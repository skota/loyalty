defmodule Loyalty.Surveys.SurveyRecipient do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses [:pending, :sent, :failed, :responded]

  schema "survey_recipients" do
    field :status, Ecto.Enum, values: @statuses, default: :pending
    field :notification_sent_at, :utc_datetime
    field :responded_at, :utc_datetime
    field :last_error, :string

    belongs_to :survey, Loyalty.Surveys.Survey
    belongs_to :customer, Loyalty.Rewards.Customer
    has_one :response, Loyalty.Surveys.SurveyResponse

    timestamps()
  end

  def changeset(recipient, attrs) do
    recipient
    |> cast(attrs, [
      :survey_id,
      :customer_id,
      :status,
      :notification_sent_at,
      :responded_at,
      :last_error
    ])
    |> validate_required([:survey_id, :customer_id, :status])
    |> foreign_key_constraint(:survey_id)
    |> foreign_key_constraint(:customer_id)
    |> unique_constraint([:survey_id, :customer_id])
  end
end
