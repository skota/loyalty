defmodule Loyalty.Rewards.Reward do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rewards" do
    field :name, :string
    field :points_required, :integer
    field :description, :string
    belongs_to :loyalty_program, Loyalty.Rewards.LoyaltyProgram
    timestamps()
  end

  def changeset(loyalty_program, attrs) do
    loyalty_program
    |> cast(attrs, [:name, :points_required, :description, :loyalty_program_id])
    |> validate_required([:name, :points_required, :description, :loyalty_program_id])
  end
end
