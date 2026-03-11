defmodule Loyalty.Rewards.LoyaltyPointTransaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "loyalty_points_transactions" do
    field :points, :integer
    field :source, :string
    field :notes, :string
    belongs_to :customer, Loyalty.Rewards.Customer
    belongs_to :loyalty_program, Loyalty.Rewards.LoyaltyProgram
    field :inserted_at, :utc_datetime
  end

  def changeset(loyalty_point, attrs) do
    loyalty_point
    |> cast(attrs, [:points, :source, :notes, :customer_id, :loyalty_program_id, :inserted_at])
    |> validate_required([:points, :source,  :customer_id, :loyalty_program_id, :inserted_at])
  end


end
