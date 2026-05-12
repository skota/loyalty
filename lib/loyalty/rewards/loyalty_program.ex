defmodule Loyalty.Rewards.LoyaltyProgram do
  use Ecto.Schema
  import Ecto.Changeset

  schema "loyalty_programs" do
    field :name, :string
    field :points_per_dollar, :decimal
    field :signup_bonus_points, :integer
    field :description, :string
    field :active, :boolean, default: true
    field :qr_code_token, :string
    has_many :rewards, Loyalty.Rewards.Reward
    timestamps()
  end

  def changeset(loyalty_program, attrs) do
    loyalty_program
    |> cast(attrs, [
      :name,
      :points_per_dollar,
      :signup_bonus_points,
      :description,
      :active,
      :qr_code_token
    ])
    |> maybe_put_qr_code_token()
    |> validate_required([
      :name,
      :points_per_dollar,
      :signup_bonus_points,
      :description,
      :active,
      :qr_code_token
    ])
    |> unique_constraint(:qr_code_token)
  end

  defp maybe_put_qr_code_token(changeset) do
    case get_field(changeset, :qr_code_token) do
      nil -> put_change(changeset, :qr_code_token, Ecto.UUID.generate())
      _token -> changeset
    end
  end
end
