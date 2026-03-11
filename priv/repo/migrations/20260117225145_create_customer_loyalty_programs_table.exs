defmodule Loyalty.Repo.Migrations.CreateCustomerLoyaltyProgramsTable do
  use Ecto.Migration

  def change do
    create table(:customer_loyalty_programs) do
      add :customer_id, references(:customers, on_delete: :delete_all)
      add :loyalty_program_id, references(:loyalty_programs, on_delete: :delete_all)
      timestamps()
    end
  end
end
