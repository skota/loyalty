defmodule Loyalty.Repo.Migrations.CreateLoyaltyProgramsTable do
  use Ecto.Migration

  def change do
    create table(:loyalty_programs) do
      add :name, :string
      add :points_per_dollar, :decimal, default: 1.0
      add :signup_bonus_points, :integer, default: 0
      add :description, :text
      add :active, :boolean, default: true
      timestamps()
    end
  end
end
