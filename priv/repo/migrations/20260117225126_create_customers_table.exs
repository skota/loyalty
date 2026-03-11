defmodule Loyalty.Repo.Migrations.CreateCustomersTable do
  use Ecto.Migration

  def change do
    create table(:customers) do
      add :phone, :string, null: true
      add :source, :string # "qr", "manual", "text-in"
      add :meta, :map, default: %{}
      add :name, :string
      add :device_id, :uuid, null: false
      add :email, :string
      add :points_balance, :integer, default: 0
      add :device_token, :string
      timestamps()
    end

  end
end
