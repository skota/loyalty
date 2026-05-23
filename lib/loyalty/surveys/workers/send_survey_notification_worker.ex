defmodule Loyalty.Surveys.Workers.SendSurveyNotificationWorker do
  use Oban.Worker,
    queue: :survey_delivery,
    max_attempts: 5,
    unique: [period: 60, keys: [:survey_recipient_id]]

  alias Oban.Job
  alias Loyalty.{Surveys, Notifications}

  @impl Oban.Worker
  def perform(%Job{args: %{"survey_recipient_id" => survey_recipient_id}}) do
    recipient = Surveys.get_survey_recipient!(survey_recipient_id)
    notifications_module = Application.get_env(:loyalty, :notifications_module, Notifications)

    cond do
      recipient.status in [:sent, :responded] ->
        :ok

      is_nil(recipient.customer.device_token) or recipient.customer.device_token == "" ->
        {:ok, _recipient} = Surveys.mark_recipient_failed(recipient, "missing device token")
        :ok

      true ->
        case notifications_module.send_message(
               recipient.customer.device_token,
               recipient.survey.message,
               recipient.survey_id
             ) do
          {:ok, _response} ->
            {:ok, _recipient} = Surveys.mark_recipient_sent(recipient)
            :ok

          {:error, reason} ->
            {:ok, _recipient} = Surveys.mark_recipient_failed(recipient, inspect(reason))
            {:error, inspect(reason)}
        end
    end
  end
end
