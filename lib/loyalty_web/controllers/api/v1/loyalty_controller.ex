defmodule LoyaltyWeb.Api.V1.LoyaltyController do
  use LoyaltyWeb, :controller
  alias Loyalty.{Marketing, Notifications}


  def index(conn, %{"device_id" => device_id}) do
    case Marketing.get_loyalty_membership(device_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json([])

      loyalty_programs ->
        conn
        |> put_status(:ok)
        |> json(loyalty_programs)
    end
  end

  def join_loyalty(conn, %{"join" => join_params}) do
    case Marketing.join_loyalty_program(
           join_params["loyalty_program_id"],
           join_params["device_id"]
         ) do
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})

      {:ok, _customer_loyalty_program} ->
        customer = Marketing.get_customer_by_device_id(join_params["device_id"])
        Notifications.send_message(customer.device_token, "Successfully joined loyalty program!")
        conn
        |> put_status(201)
        |> json(%{ok: "Joined loyalty program"})
    end
  end

  @spec leave_loyalty(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def leave_loyalty(conn, %{"join" => join_params}) do
    case Marketing.leave_loyalty_program(
           join_params["loyalty_program_id"],
           join_params["device_id"]
         ) do
      {:ok, _team_contact} ->
        # returns 200 ok
        json(conn, %{ok: "Left loyalty program"})
    end
  end
end
