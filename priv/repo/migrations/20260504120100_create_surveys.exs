defmodule Loyalty.Repo.Migrations.CreateSurveys do
  use Ecto.Migration

  def change do
    create table(:surveys) do
      add :loyalty_program_id, references(:loyalty_programs, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :message, :text, null: false
      add :purchase_count_threshold, :integer, null: false
      add :purchase_window_days, :integer, null: false
      add :active, :boolean, null: false, default: true

      timestamps()
    end

    create index(:surveys, [:loyalty_program_id])
    create index(:surveys, [:active])

    create table(:survey_recipients) do
      add :survey_id, references(:surveys, on_delete: :delete_all), null: false
      add :customer_id, references(:customers, on_delete: :delete_all), null: false
      add :status, :string, null: false, default: "pending"
      add :notification_sent_at, :utc_datetime
      add :responded_at, :utc_datetime
      add :last_error, :text

      timestamps()
    end

    create unique_index(:survey_recipients, [:survey_id, :customer_id])
    create index(:survey_recipients, [:customer_id])
    create index(:survey_recipients, [:status])

    create table(:survey_responses) do
      add :survey_id, references(:surveys, on_delete: :delete_all), null: false
      add :customer_id, references(:customers, on_delete: :delete_all), null: false
      add :survey_recipient_id, references(:survey_recipients, on_delete: :delete_all), null: false
      add :rating, :integer, null: false
      add :additional_feedback, :text
      add :submitted_at, :utc_datetime, null: false

      timestamps()
    end

    create unique_index(:survey_responses, [:survey_recipient_id])
    create index(:survey_responses, [:survey_id])
    create index(:survey_responses, [:customer_id])
  end
end
