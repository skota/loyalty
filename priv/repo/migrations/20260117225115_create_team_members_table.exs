defmodule Loyalty.Repo.Migrations.CreateUsersTeamsTable do
  use Ecto.Migration

  def change do
    create table(:team_members) do
      add :team_id, :integer, null: false
      add :user_id, :integer, null: false
      timestamps(type: :utc_datetime)
    end
  end
end
