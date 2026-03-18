defmodule LoyaltyWeb.Api.V1.PurchaseController do
  use LoyaltyWeb, :controller
  alias Loyalty.Marketing

  def create(conn, %{"purchase" => purchase_params}) do
    case Marketing.award_loyalty_points(purchase_params) do
      {:ok, _loyalty_points_transaction} ->
        conn
        |> put_status(200)
        |> json(%{ok: "success"})

      {:error, reason} ->
        # we will get a changeset back..show appropriate error
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end


  def fetch(conn, %{"device_id" => device_id}) do
    case Marketing.get_purchase_by_device_id(device_id) do
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
      results ->
        conn
        |> put_status(200)
        |> json(results)
    end
  end
end
