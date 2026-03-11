defmodule Loyalty.RewardsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Loyalty.Rewards` context.
  """

  alias Loyalty.Rewards

  @doc """
  Generate a loyalty_program.
  """
  def loyalty_program_fixture(attrs \\ %{}) do
    {:ok, loyalty_program} =
      attrs
      |> Enum.into(%{
        name: "Test Program #{System.unique_integer([:positive])}",
        points_per_dollar: Decimal.new("1.0"),
        signup_bonus_points: 100,
        description: "Test program description",
        active: true
      })
      |> Rewards.create_loyalty_program()

    loyalty_program
  end

  @doc """
  Generate a reward.
  """
  def reward_fixture(attrs \\ %{}) do
    loyalty_program =
      case Map.get(attrs, :loyalty_program_id) do
        nil -> loyalty_program_fixture()
        id -> Rewards.get_loyalty_program(id)
      end

    {:ok, reward} =
      attrs
      |> Enum.into(%{
        name: "Test Reward #{System.unique_integer([:positive])}",
        points_required: 50,
        description: "Test reward description",
        loyalty_program_id: loyalty_program.id
      })
      |> Rewards.create_reward()

    reward
  end
end
