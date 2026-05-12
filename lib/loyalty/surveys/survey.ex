defmodule Loyalty.Surveys.Survey do
  use Ecto.Schema
  import Ecto.Changeset

  schema "surveys" do
    field :name, :string
    field :message, :string
    field :purchase_count_threshold, :integer
    field :purchase_window_days, :integer
    field :active, :boolean, default: true
    field :recipient_count, :integer, virtual: true, default: 0
    field :response_count, :integer, virtual: true, default: 0

    belongs_to :loyalty_program, Loyalty.Rewards.LoyaltyProgram
    has_many :recipients, Loyalty.Surveys.SurveyRecipient
    has_many :responses, Loyalty.Surveys.SurveyResponse

    timestamps()
  end

  def changeset(survey, attrs) do
    survey
    |> cast(attrs, [
      :name,
      :message,
      :purchase_count_threshold,
      :purchase_window_days,
      :active,
      :loyalty_program_id
    ])
    |> validate_required([
      :name,
      :message,
      :purchase_count_threshold,
      :purchase_window_days,
      :active,
      :loyalty_program_id
    ])
    |> validate_length(:name, max: 120)
    |> validate_length(:message, max: 500)
    |> validate_number(:purchase_count_threshold, greater_than: 0)
    |> validate_number(:purchase_window_days, greater_than: 0)
    |> foreign_key_constraint(:loyalty_program_id)
  end
end
