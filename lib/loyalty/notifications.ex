defmodule Loyalty.Notifications do
  require Logger
  alias Req.Response

  def send_message(device_token, message, survey_id \\ nil) do
    cond do
      is_nil(device_token) or device_token == "" ->
        {:error, :missing_device_token}

      true ->
        token = Goth.fetch!(Loyalty.Goth)

        headers = [
          {"Content-Type", "application/json"},
          {"Authorization", "Bearer #{String.trim(token.token)}"}
        ]

        body = if survey_id do
          message_body(device_token, message, survey_id)
        else
          message_body(device_token, message)
        end

        {:ok, notifications_url} = Application.fetch_env(:loyalty, :fb_notification_url)

        case Req.post(notifications_url, json: body, headers: headers) do
          {:ok, %Response{status: status} = response} when status in 200..299 ->
            {:ok, response}

          {:ok, %Response{status: status} = response} ->
            Logger.error("Push notification failed with status #{status}")
            {:error, {:unexpected_status, status, response.body}}

          {:error, reason} ->
            Logger.error("Push notification request failed: #{inspect(reason)}")
            {:error, reason}
        end
    end
  end

  defp message_body(device_token, message) do
    %{
          message: %{
            token: device_token,
            notification: %{
              body: message,
              title: "Loyalty"
            }
          }
        }
  end

  defp message_body(device_token, message, survey_id) do
    %{
      message: %{
        token: device_token,
        notification: %{
          body: message,
          title: "Loyalty"
        },
        data: %{
          survey_id: "#{survey_id}"
        }
      }
    }
  end

end
