defmodule Loyalty.Rewards.CustomerLoyaltyProgram do
  use Ecto.Schema
  import Ecto.Changeset

  schema "customer_loyalty_programs" do
    field :customer_id, :integer
    field :loyalty_program_id, :integer
    timestamps()
  end

  def changeset(customer_loyalty_program, attrs) do
    customer_loyalty_program
    |> cast(attrs, [:customer_id, :loyalty_program_id])
    |> validate_required([:customer_id, :loyalty_program_id])
  end
end
