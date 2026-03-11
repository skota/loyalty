defmodule Loyalty.Repo.Migrations.CreateTeamsTable do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :team_name, :text, null: false
      timestamps(type: :utc_datetime)
    end
  end
end
