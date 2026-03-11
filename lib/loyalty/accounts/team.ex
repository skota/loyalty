defmodule Loyalty.Accounts.Team do
  use Ecto.Schema
  import Ecto.Changeset

  schema "teams" do
    field :team_name, :string
    field :onboarded, :boolean
    timestamps()
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:team_name, :onboarded])
    |> unique_constraint([:team_name])
  end

end
