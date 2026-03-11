defmodule Loyalty.Repo.Migrations.CreatePurchasesTable do
  use Ecto.Migration


  def change do
    create table(:purchases) do
      add :customer_id, references(:customers, on_delete: :delete_all)
      add :amount_cents, :integer
      add :points_earned, :integer
      add :purchased_at, :utc_datetime
      add :product_name, :string
      timestamps()
    end

    create index(:purchases, [:customer_id])
  end

end
