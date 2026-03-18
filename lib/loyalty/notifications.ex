defmodule Loyalty.Notifications do
  require Logger

  def send_message(device_token, message) do
    # get oauth token
    token =  Goth.fetch!(Loyalty.Goth)
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{String.trim(token.token)}"}
    ]

    body = "{
        \"message\":{
            \"token\":\"#{device_token}\",
            \"notification\":{
                \"body\":\"#{message}\",
                \"title\":\"Loyalty\"
            }
          }
    }"

    {:ok, notifications_url} = Application.fetch_env(:reward_pilot, :fb_notification_url)
    # IO.inspect "Notificatin url: #{notifications_url}"
    {:ok, response} = Req.post(notifications_url, body: body, headers: headers)

    IO.inspect(response)
  end

end
