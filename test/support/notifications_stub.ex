defmodule Loyalty.NotificationsStub do
  def send_message(device_token, message) do
    if test_pid = Application.get_env(:loyalty, :notifications_test_pid) do
      send(test_pid, {:notification_sent, device_token, message})
    end

    {:ok, %{device_token: device_token, message: message}}
  end
end
