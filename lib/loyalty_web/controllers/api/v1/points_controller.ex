defmodule LoyaltyWeb.Api.V1.PointsController do
  use LoyaltyWeb, :controller
  alias Loyalty.Marketing

  def fetch(conn, %{"device_id" => device_id}) do
    # list users rewards
    case Marketing.eligible_rewards(device_id) do
      rewards ->
        conn
        |> put_status(200)
        |> json(rewards)

      {:error, reason} ->
        # we will get a changeset back..show appropriate error
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end


  def redeem(conn, %{"reward" => reward_params}) do
    case Marketing.redeem_loyalty_points(reward_params) do
      {:ok, "success"} ->
        conn
        |> put_status(200)
        |> json(%{ok: "success"})

      {:error, reason} ->
        # we will get a changeset back..show appropriate error
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end

    conn
        |> put_status(200)
  end


  def reward_details(conn, %{"device_id" => device_id, "reward_id" => reward_id}) do
    case Marketing.get_reward_details(device_id, reward_id) do
      reward ->
        conn
        |> put_status(200)
        |> json(reward)

      {:error, reason} ->
        # we will get a changeset back..show appropriate error
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end
end
