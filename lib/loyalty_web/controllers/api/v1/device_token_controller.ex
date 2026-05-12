defmodule LoyaltyWeb.Api.V1.DeviceTokenController do
  use LoyaltyWeb, :controller
  alias Loyalty.Marketing

  def create(conn, params) do
    Marketing.update_device_token(params)

    conn
    |> json(%{message: "ok"})
  end
end
