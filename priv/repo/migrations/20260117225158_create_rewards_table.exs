defmodule Loyalty.Repo.Migrations.CreateRewardsTable do
  use Ecto.Migration

  def change do
    create table(:rewards) do
      add :loyalty_program_id, references(:loyalty_programs, on_delete: :delete_all)
      add :name, :string
      add :points_required, :integer
      add :description, :string
      timestamps()
    end
  end
end
