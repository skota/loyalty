defmodule Loyalty.Repo.Migrations.AddQrCodeTokenToLoyaltyPrograms do
  use Ecto.Migration

  def up do
    execute("CREATE EXTENSION IF NOT EXISTS pgcrypto")

    alter table(:loyalty_programs) do
      add :qr_code_token, :string
    end

    execute("""
    UPDATE loyalty_programs
    SET qr_code_token = gen_random_uuid()::text
    WHERE qr_code_token IS NULL
    """)

    execute("""
    ALTER TABLE loyalty_programs
    ALTER COLUMN qr_code_token SET NOT NULL
    """)

    create unique_index(:loyalty_programs, [:qr_code_token])
  end

  def down do
    drop unique_index(:loyalty_programs, [:qr_code_token])

    alter table(:loyalty_programs) do
      remove :qr_code_token
    end
  end
end
