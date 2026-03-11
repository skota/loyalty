defmodule Loyalty.Rewards.Purchase do
  use Ecto.Schema
  import Ecto.Changeset


  schema "purchases" do
    field :amount_cents, :integer
    field :points_earned, :integer
    field :purchased_at, :utc_datetime
    field :product_name, :string
    belongs_to :customer, Loyalty.Rewards.Customer, foreign_key: :customer_id


    timestamps()
  end

  def changeset(loyalty_program, attrs) do
    loyalty_program
    |> cast(attrs, [:amount_cents, :points_earned,  :purchased_at,  :customer_id, :product_name])
    |> validate_required([:amount_cents, :points_earned,  :purchased_at,  :customer_id, :product_name])
  end

end
