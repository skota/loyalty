defmodule Loyalty.Surveys.SurveyResponse do
  use Ecto.Schema
  import Ecto.Changeset

  schema "survey_responses" do
    field :rating, :integer
    field :additional_feedback, :string
    field :submitted_at, :utc_datetime

    belongs_to :survey, Loyalty.Surveys.Survey
    belongs_to :customer, Loyalty.Rewards.Customer
    belongs_to :survey_recipient, Loyalty.Surveys.SurveyRecipient

    timestamps()
  end

  def changeset(response, attrs) do
    response
    |> cast(attrs, [
      :survey_id,
      :customer_id,
      :survey_recipient_id,
      :rating,
      :additional_feedback,
      :submitted_at
    ])
    |> validate_required([:survey_id, :customer_id, :survey_recipient_id, :rating, :submitted_at])
    |> validate_number(:rating, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_length(:additional_feedback, max: 2_000)
    |> foreign_key_constraint(:survey_id)
    |> foreign_key_constraint(:customer_id)
    |> foreign_key_constraint(:survey_recipient_id)
    |> unique_constraint(:survey_recipient_id)
  end
end
