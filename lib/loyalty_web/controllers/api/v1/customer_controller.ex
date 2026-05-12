defmodule LoyaltyWeb.Api.V1.CustomerController do
  use LoyaltyWeb, :controller
  alias Loyalty.Marketing

  def fetch(conn, %{"device_id" => device_id}) do
    case Marketing.get_customer_by_device_id(device_id) do
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})

      customer ->
        conn
        |> put_status(200)
        |> json(%{
          id: customer.id,
          name: customer.name,
          device_id: customer.device_id,
          points: customer.points_balance
        })
    end
  end
end
