defmodule Loyalty.Surveys do
  @moduledoc """
  Survey management, delivery scheduling, and response collection.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Loyalty.{Repo, Marketing}
  alias Loyalty.Rewards.{Customer, CustomerLoyaltyProgram, LoyaltyProgram, Purchase}
  alias Loyalty.Surveys.{Survey, SurveyRecipient, SurveyResponse}
  alias Loyalty.Surveys.Workers.SendSurveyNotificationWorker

  @rating_scale 1..5

  @spec list_surveys() :: any()
  def list_surveys do
    from(survey in Survey,
      join: loyalty_program in assoc(survey, :loyalty_program),
      left_join: recipient in assoc(survey, :recipients),
      left_join: response in assoc(survey, :responses),
      preload: [loyalty_program: loyalty_program],
      group_by: [survey.id, loyalty_program.id],
      order_by: [desc: survey.inserted_at],
      select_merge: %{
        recipient_count: count(recipient.id, :distinct),
        response_count: count(response.id, :distinct)
      }
    )
    |> Repo.all()
  end

  def list_loyalty_program_options do
    LoyaltyProgram
    |> order_by([program], asc: program.name)
    |> select([program], {program.name, program.id})
    |> Repo.all()
  end

  def get_survey!(id) do
    Survey
    |> Repo.get!(id)
    |> Repo.preload(:loyalty_program)
  end

  def get_survey_dashboard!(id) do
    survey =
      Survey
      |> Repo.get!(id)
      |> Repo.preload(:loyalty_program)

    responses =
      SurveyResponse
      |> join(:inner, [response], customer in assoc(response, :customer))
      |> where([response], response.survey_id == ^survey.id)
      |> order_by([response], desc: response.submitted_at)
      |> select([response, customer], %{
        id: response.id,
        rating: response.rating,
        additional_feedback: response.additional_feedback,
        submitted_at: response.submitted_at,
        customer_name: customer.name,
        customer_email: customer.email
      })
      |> Repo.all()

    %{
      survey: survey,
      responses: responses,
      summary: build_response_summary(responses)
    }
  end

  def create_survey(attrs \\ %{}) do
    %Survey{}
    |> Survey.changeset(attrs)
    |> Repo.insert()
  end

  def update_survey(%Survey{} = survey, attrs) do
    survey
    |> Survey.changeset(attrs)
    |> Repo.update()
  end

  def delete_survey(%Survey{} = survey) do
    Repo.delete(survey)
  end

  def change_survey(%Survey{} = survey, attrs \\ %{}) do
    Survey.changeset(survey, attrs)
  end

  def list_pending_surveys_for_device(device_id) do
    case Repo.get_by(Customer, device_id: device_id) do
      nil ->
        {:error, "customer not found"}

      %Customer{id: customer_id} ->
        surveys =
          SurveyRecipient
          |> join(:inner, [recipient], survey in assoc(recipient, :survey))
          |> where(
            [recipient, survey],
            recipient.customer_id == ^customer_id and survey.active == true
          )
          |> where([recipient], recipient.status in [:pending, :sent])
          |> order_by([recipient], desc: recipient.inserted_at)
          |> select([recipient, survey], %{
            survey_id: survey.id,
            loyalty_program_id: survey.loyalty_program_id,
            name: survey.name,
            message: survey.message,
            status: recipient.status
          })
          |> Repo.all()

        surveys
    end
  end

  def submit_response_for_device(attrs) do
    case Marketing.get_customer_by_device_id(attrs["device_id"]) do
      nil ->
        {:error, "customer not found"}

      %Customer{} = customer ->
        with %SurveyRecipient{} = recipient <-
               get_recipient_for_customer_survey(customer.id, attrs["survey_id"]),
             true <- recipient.customer_id == customer.id do
          create_survey_response(customer, recipient, attrs)
        else
          nil -> {:error, "survey recipient not found"}
          false -> {:error, "survey recipient does not belong to customer"}
        end
    end
  end

  def get_survey_recipient!(id) do
    SurveyRecipient
    |> Repo.get!(id)
    |> Repo.preload([:customer, :survey, :response])
  end

  def mark_recipient_sent(%SurveyRecipient{} = recipient) do
    recipient
    |> SurveyRecipient.changeset(%{
      status: :sent,
      notification_sent_at: DateTime.utc_now() |> DateTime.truncate(:second),
      last_error: nil
    })
    |> Repo.update()
  end

  def mark_recipient_failed(%SurveyRecipient{} = recipient, reason) do
    recipient
    |> SurveyRecipient.changeset(%{
      status: :failed,
      last_error: reason
    })
    |> Repo.update()
  end

  def schedule_active_surveys(now \\ DateTime.utc_now()) do
    Survey
    |> where([survey], survey.active == true)
    |> Repo.all()
    |> Enum.reduce(%{surveys_processed: 0, recipients_queued: 0}, fn survey, acc ->
      {:ok, result} = queue_matching_recipients(survey, now)

      %{
        surveys_processed: acc.surveys_processed + 1,
        recipients_queued: acc.recipients_queued + result.recipients_queued
      }
    end)
  end

  def queue_matching_recipients(%Survey{} = survey, now \\ DateTime.utc_now()) do
    timestamp = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    recipients =
      survey
      |> eligible_customers_query(now)
      |> Repo.all()
      |> Enum.map(fn customer ->
        %{
          survey_id: survey.id,
          customer_id: customer.id,
          status: :pending,
          inserted_at: timestamp,
          updated_at: timestamp
        }
      end)

    if recipients == [] do
      {:ok, %{recipients_queued: 0}}
    else
      Repo.transaction(fn ->
        {_, inserted_recipients} =
          Repo.insert_all(
            SurveyRecipient,
            recipients,
            on_conflict: :nothing,
            conflict_target: [:survey_id, :customer_id],
            returning: [:id]
          )

        Enum.each(inserted_recipients, fn recipient ->
          case Oban.insert(
                 SendSurveyNotificationWorker.new(%{"survey_recipient_id" => recipient.id})
               ) do
            {:ok, _job} -> :ok
            {:error, changeset} -> Repo.rollback(changeset)
          end
        end)

        %{recipients_queued: length(inserted_recipients)}
      end)
    end
  end

  defp eligible_customers_query(%Survey{} = survey, now) do
    cutoff = DateTime.add(now, -survey.purchase_window_days * 86_400, :second)

    from(customer in Customer,
      join: membership in CustomerLoyaltyProgram,
      on:
        membership.customer_id == customer.id and
          membership.loyalty_program_id == ^survey.loyalty_program_id,
      join: purchase in Purchase,
      on: purchase.customer_id == customer.id and purchase.purchased_at >= ^cutoff,
      left_join: recipient in SurveyRecipient,
      on: recipient.customer_id == customer.id and recipient.survey_id == ^survey.id,
      where: not is_nil(customer.device_token) and customer.device_token != "",
      where: is_nil(recipient.id),
      group_by: customer.id,
      having: count(purchase.id) >= ^survey.purchase_count_threshold,
      select: customer
    )
  end

  defp get_recipient_for_customer_survey(customer_id, survey_id) do
    SurveyRecipient
    |> Repo.get_by(customer_id: customer_id, survey_id: survey_id)
    |> Repo.preload([:customer, :survey])
  end

  defp create_survey_response(customer, recipient, attrs) do
    submitted_at = DateTime.utc_now() |> DateTime.truncate(:second)

    response_attrs = %{
      survey_id: recipient.survey_id,
      customer_id: customer.id,
      survey_recipient_id: recipient.id,
      rating: attrs["rating"],
      additional_feedback: attrs["additional_feedback"],
      submitted_at: submitted_at
    }

    Multi.new()
    |> Multi.insert(:response, SurveyResponse.changeset(%SurveyResponse{}, response_attrs))
    |> Multi.update(
      :recipient,
      SurveyRecipient.changeset(recipient, %{
        status: :responded,
        responded_at: submitted_at
      })
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{response: response}} -> {:ok, response}
      {:error, :response, changeset, _changes} -> {:error, changeset}
      {:error, :recipient, changeset, _changes} -> {:error, changeset}
    end
  end

  defp build_response_summary(responses) do
    rating_counts =
      responses
      |> Enum.frequencies_by(& &1.rating)
      |> then(fn counts ->
        Enum.map(@rating_scale, fn rating ->
          %{rating: rating, count: Map.get(counts, rating, 0)}
        end)
      end)

    response_timeline =
      responses
      |> Enum.group_by(&DateTime.to_date(&1.submitted_at))
      |> Enum.map(fn {date, day_responses} ->
        average_rating =
          day_responses
          |> Enum.map(& &1.rating)
          |> average()

        %{
          date: date,
          count: length(day_responses),
          average_rating: average_rating
        }
      end)
      |> Enum.sort_by(& &1.date, Date)

    all_ratings =
      responses
      |> Enum.map(& &1.rating)

    %{
      total_responses: length(responses),
      average_rating: average(all_ratings),
      top_rating: top_rating(rating_counts),
      rating_counts: rating_counts,
      response_timeline: response_timeline
    }
  end

  defp average([]), do: 0.0

  defp average(values) do
    values
    |> Enum.sum()
    |> Kernel./(length(values))
    |> Float.round(1)
  end

  defp top_rating(rating_counts) do
    rating_counts
    |> Enum.max_by(& &1.count, fn -> %{rating: 0, count: 0} end)
    |> Map.get(:rating)
  end
end
