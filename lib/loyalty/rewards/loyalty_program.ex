defmodule Loyalty.Rewards.LoyaltyProgram do
  use Ecto.Schema
  import Ecto.Changeset


  schema "loyalty_programs" do
    field :name, :string
    field :points_per_dollar, :decimal
    field :signup_bonus_points, :integer
    field :description, :string
    field :active, :boolean, default: true
    has_many :rewards, Loyalty.Rewards.Reward
    timestamps()
  end

  def changeset(loyalty_program, attrs) do
    loyalty_program
    |> cast(attrs, [:name, :points_per_dollar, :signup_bonus_points, :description, :active])
    |> validate_required([:name, :points_per_dollar, :signup_bonus_points, :description,:active])
  end

end
