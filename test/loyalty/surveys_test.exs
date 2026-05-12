defmodule Loyalty.SurveysTest do
  use Loyalty.DataCase

  alias Loyalty.Repo
  alias Loyalty.Rewards.{Customer, Purchase}
  alias Loyalty.Surveys
  alias Loyalty.Surveys.{SurveyRecipient, SurveyResponse}
  alias Loyalty.Surveys.Workers.ScheduleSurveyRecipientsWorker

  import Loyalty.RewardsFixtures

  setup do
    Application.put_env(:loyalty, :notifications_module, Loyalty.NotificationsStub)
    Application.put_env(:loyalty, :notifications_test_pid, self())

    on_exit(fn ->
      Application.delete_env(:loyalty, :notifications_module)
      Application.delete_env(:loyalty, :notifications_test_pid)
    end)

    loyalty_program = loyalty_program_fixture()

    customer =
      Repo.insert!(%Customer{
        device_id: Ecto.UUID.generate(),
        name: "Repeat Customer",
        email: "repeat@example.com",
        points_balance: 0,
        device_token: "push-token-1"
      })

    Repo.insert!(%Loyalty.Rewards.CustomerLoyaltyProgram{
      customer_id: customer.id,
      loyalty_program_id: loyalty_program.id
    })

    %{loyalty_program: loyalty_program, customer: customer}
  end

  test "daily worker queues and delivers a survey for newly eligible customers", %{
    loyalty_program: loyalty_program,
    customer: customer
  } do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Repo.insert!(%Purchase{
      customer_id: customer.id,
      amount_cents: 1_000,
      points_earned: 10,
      product_name: "Burrito",
      purchased_at: DateTime.add(now, -2 * 86_400, :second)
    })

    Repo.insert!(%Purchase{
      customer_id: customer.id,
      amount_cents: 1_500,
      points_earned: 15,
      product_name: "Taco",
      purchased_at: DateTime.add(now, -1 * 86_400, :second)
    })

    {:ok, survey} =
      Surveys.create_survey(%{
        loyalty_program_id: loyalty_program.id,
        name: "Recent buyers",
        message: "Tell us how we did.",
        purchase_count_threshold: 2,
        purchase_window_days: 7,
        active: true
      })

    assert :ok = ScheduleSurveyRecipientsWorker.perform(%Oban.Job{})

    recipient =
      Repo.one!(
        from recipient in SurveyRecipient,
          where: recipient.survey_id == ^survey.id and recipient.customer_id == ^customer.id
      )

    assert recipient.status == :sent
    assert recipient.notification_sent_at
    assert_received {:notification_sent, "push-token-1", "Tell us how we did."}
  end

  test "submit_response_for_device stores the rating and free-form feedback", %{
    loyalty_program: loyalty_program,
    customer: customer
  } do
    {:ok, survey} =
      Surveys.create_survey(%{
        loyalty_program_id: loyalty_program.id,
        name: "Experience check-in",
        message: "Rate your visit.",
        purchase_count_threshold: 1,
        purchase_window_days: 30,
        active: true
      })

    recipient =
      Repo.insert!(%SurveyRecipient{
        survey_id: survey.id,
        customer_id: customer.id,
        status: :sent,
        notification_sent_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })

    assert {:ok, %SurveyResponse{} = response} =
             Surveys.submit_response_for_device(%{
               "device_id" => customer.device_id,
               "survey_id" => survey.id,
               "rating" => 5,
               "additional_feedback" => "Service was excellent."
             })

    assert response.rating == 5
    assert response.additional_feedback == "Service was excellent."

    updated_recipient = Repo.get!(SurveyRecipient, recipient.id)
    assert updated_recipient.status == :responded
    assert updated_recipient.responded_at
  end
end
