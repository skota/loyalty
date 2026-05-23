defmodule Loyalty.Repo.Migrations.UpdateLoyaltyProgramPointsType do
  use Ecto.Migration

  def change do
    alter table(:loyalty_programs) do
      modify :points_per_dollar, :integer
    end
  end
end
