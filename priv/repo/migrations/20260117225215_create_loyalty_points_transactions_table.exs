defmodule Loyalty.Repo.Migrations.CreateLoyaltyPointsTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:loyalty_points_transactions) do
      add :customer_id, references(:customers, on_delete: :delete_all), null: false
      add :loyalty_program_id, references(:loyalty_programs, on_delete: :delete_all), null: false
      add :points, :integer, null: false
      add :source, :string, null: false
      add :inserted_at, :utc_datetime, null: false
      add :notes, :string
    end
  end
end
