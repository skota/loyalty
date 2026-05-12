defmodule Loyalty.Accounts.TeamMember do
  use Ecto.Schema
  import Ecto.Changeset

  schema "team_members" do
    field :user_id, :integer
    field :team_id, :integer
    timestamps()
  end

  @doc false
  def changeset(job, attrs) do
    job
    |> cast(attrs, [:user_id, :team_id])
    |> validate_required([:user_id, :team_id])
  end
end
