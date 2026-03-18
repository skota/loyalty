defmodule Loyalty.Rewards.Customer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "customers" do
    field :phone, :string
    field :source, :string
    field :meta, :map, default: %{}
    field :name, :string
    field :email, :string
    field :device_id, Ecto.UUID
    field :points_balance, :integer
    field :device_token, :string
    timestamps()
  end

  def changeset(customer, attrs) do
    customer
    |> cast(attrs, [:phone, :name, :source, :meta, :email, :device_id, :points_balance])
    |> validate_required([:device_id])
    |> unique_constraint(:device_id)
  end

  def update_changeset(customer, attrs) do
    customer
    |> cast(attrs, [:phone, :name, :source, :meta, :email, :device_id, :points_balance])
    |> validate_required([:device_id])
  end

  def update_device_token_changeset(customer, attrs) do
    customer
    |> cast(attrs, [:device_token])
    |> validate_required([:device_token])
  end


end
