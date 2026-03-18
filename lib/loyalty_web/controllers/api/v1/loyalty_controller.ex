defmodule LoyaltyWeb.Api.V1.LoyaltyController do
  use LoyaltyWeb, :controller
  alias Loyalty.Marketing

  def join_loyalty(conn, %{"join" => join_params}) do
    IO.inspect(join_params, label: "Join params")
    case Marketing.join_loyalty_program( join_params["loyalty_program_id"],join_params["device_id"],join_params["name"] ) do
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})

      {:ok, _team_contact} ->
        conn
        |> put_status(201)
        |> json(%{ok: "Joined loyalty program"})

    end
  end

  @spec leave_loyalty(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def leave_loyalty(conn, %{"join" => join_params}) do
    case Marketing.leave_loyalty_program( join_params["loyalty_program_id"], join_params["device_id"]) do
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})

      {:ok, _team_contact} ->
        # returns 200 ok
        json(conn, %{ok: "Left loyalty program"})
    end
  end
end
