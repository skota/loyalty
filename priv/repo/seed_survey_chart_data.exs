# Script for creating a rerunnable survey dataset with enough responses for charts.
#
# Run it with:
#
#     mix run priv/repo/seed_survey_chart_data.exs

import Ecto.Query

alias Loyalty.Repo
alias Loyalty.Rewards.{Customer, CustomerLoyaltyProgram, LoyaltyProgram}
alias Loyalty.Surveys.{Survey, SurveyRecipient, SurveyResponse}

now = DateTime.utc_now() |> DateTime.truncate(:second)

survey_rows = [
  %{rating: 5, days_ago: 21, feedback: "Loved the staff energy and the food came out fast."},
  %{rating: 4, days_ago: 20, feedback: "Really good overall, just a little crowded at lunch."},
  %{rating: 5, days_ago: 19, feedback: "Best burrito bowl I have had in weeks."},
  %{rating: 3, days_ago: 18, feedback: "Flavor was solid, but checkout felt a bit slow."},
  %{rating: 4, days_ago: 17, feedback: "Friendly team and easy ordering experience."},
  %{rating: 5, days_ago: 16, feedback: "Everything tasted fresh and the line moved quickly."},
  %{rating: 2, days_ago: 15, feedback: "Order was correct, but the wait felt too long."},
  %{rating: 4, days_ago: 14, feedback: "Good value and the mobile pickup was smooth."},
  %{rating: 5, days_ago: 13, feedback: "Great portion size and excellent service."},
  %{rating: 3, days_ago: 12, feedback: "Decent visit, though the dining room needed cleanup."},
  %{rating: 4, days_ago: 11, feedback: "Staff was warm and the salsa bar was stocked."},
  %{rating: 5, days_ago: 10, feedback: "Fast, fresh, and exactly what I wanted."},
  %{rating: 1, days_ago: 9, feedback: "This visit missed the mark and the order was late."},
  %{rating: 4, days_ago: 8, feedback: "Good meal and a noticeably friendlier greeting this time."},
  %{rating: 5, days_ago: 7, feedback: "Really impressed with how consistent the quality has been."},
  %{rating: 3, days_ago: 6, feedback: "Food was fine, but I expected a warmer handoff."},
  %{rating: 4, days_ago: 5, feedback: "The app pickup flow worked well for me."},
  %{rating: 5, days_ago: 5, feedback: "Excellent visit and the team handled the rush well."},
  %{rating: 2, days_ago: 4, feedback: "Ingredients tasted okay, but the order felt rushed."},
  %{rating: 4, days_ago: 4, feedback: "Good visit overall and I would come back soon."},
  %{rating: 5, days_ago: 3, feedback: "One of my best recent visits, very polished."},
  %{rating: 3, days_ago: 3, feedback: "Average experience, mostly because the drink station was empty."},
  %{rating: 4, days_ago: 2, feedback: "Fast service and the team was easy to work with."},
  %{rating: 5, days_ago: 1, feedback: "Fantastic experience from ordering through pickup."},
  %{rating: 4, days_ago: 0, feedback: "Strong finish to the week, quick and reliable."}
]

loyalty_program_attrs = %{
  name: "Survey Demo Loyalty Program",
  description: "Seeded loyalty program used for survey analytics demos.",
  points_per_dollar: 1,
  signup_bonus_points: 25,
  active: true
}

case Repo.get_by(LoyaltyProgram, name: loyalty_program_attrs.name) do
  nil ->
    Repo.insert_all("loyalty_programs", [
      Map.merge(loyalty_program_attrs, %{
        qr_code_token: Ecto.UUID.generate(),
        inserted_at: now,
        updated_at: now
      })
    ])

  %LoyaltyProgram{id: loyalty_program_id} ->
    from(lp in "loyalty_programs", where: lp.id == ^loyalty_program_id)
    |> Repo.update_all(
      set: [
        description: loyalty_program_attrs.description,
        points_per_dollar: loyalty_program_attrs.points_per_dollar,
        signup_bonus_points: loyalty_program_attrs.signup_bonus_points,
        active: loyalty_program_attrs.active,
        updated_at: now
      ]
    )
end

loyalty_program = Repo.get_by!(LoyaltyProgram, name: loyalty_program_attrs.name)

survey_attrs = %{
  loyalty_program_id: loyalty_program.id,
  name: "Post Visit Satisfaction Demo",
  message: "How was your latest visit? Rate us and share any feedback.",
  purchase_count_threshold: 3,
  purchase_window_days: 14,
  active: true
}

survey =
  case Repo.get_by(Survey, name: survey_attrs.name, loyalty_program_id: loyalty_program.id) do
    nil ->
      %Survey{}
      |> Survey.changeset(survey_attrs)
      |> Repo.insert!()

    %Survey{} = existing_survey ->
      existing_survey
      |> Survey.changeset(survey_attrs)
      |> Repo.update!()
  end

Enum.with_index(survey_rows, 1)
|> Enum.each(fn {row, index} ->
  padded = String.pad_leading(Integer.to_string(index), 2, "0")
  submitted_at = DateTime.add(now, -row.days_ago * 86_400, :second)

  customer_attrs = %{
    name: "Survey Demo Customer #{padded}",
    email: "survey_demo_customer_#{padded}@example.com",
    phone: "555-20#{padded}",
    device_id: "00000000-0000-0000-0000-000000000#{padded}",
    points_balance: 0,
    source: "seed",
    meta: %{"seed" => "survey_chart_data"},
    device_token: "survey-demo-device-token-#{padded}",
    device_id: Ecto.UUID.generate()
  }

  customer =
    case Repo.get_by(Customer, email: customer_attrs.email) do
      nil ->
        %Customer{}
        |> Customer.changeset(customer_attrs)
        |> Ecto.Changeset.change(device_token: customer_attrs.device_token)
        |> Repo.insert!()

      %Customer{} = existing_customer ->
        existing_customer
        |> Customer.update_changeset(customer_attrs)
        |> Ecto.Changeset.change(device_token: customer_attrs.device_token)
        |> Repo.update!()
    end

  case Repo.get_by(
         CustomerLoyaltyProgram,
         customer_id: customer.id,
         loyalty_program_id: loyalty_program.id
       ) do
    nil ->
      %CustomerLoyaltyProgram{}
      |> CustomerLoyaltyProgram.changeset(%{
        customer_id: customer.id,
        loyalty_program_id: loyalty_program.id
      })
      |> Repo.insert!()

    _membership ->
      :ok
  end

  recipient_attrs = %{
    survey_id: survey.id,
    customer_id: customer.id,
    status: :responded,
    notification_sent_at: submitted_at,
    responded_at: submitted_at,
    last_error: nil
  }

  recipient =
    case Repo.get_by(SurveyRecipient, survey_id: survey.id, customer_id: customer.id) do
      nil ->
        %SurveyRecipient{}
        |> SurveyRecipient.changeset(recipient_attrs)
        |> Repo.insert!()

      %SurveyRecipient{} = existing_recipient ->
        existing_recipient
        |> SurveyRecipient.changeset(recipient_attrs)
        |> Repo.update!()
    end

  response_attrs = %{
    survey_id: survey.id,
    customer_id: customer.id,
    survey_recipient_id: recipient.id,
    rating: row.rating,
    additional_feedback: row.feedback,
    submitted_at: submitted_at
  }

  case Repo.get_by(SurveyResponse, survey_recipient_id: recipient.id) do
    nil ->
      %SurveyResponse{}
      |> SurveyResponse.changeset(response_attrs)
      |> Repo.insert!()

    %SurveyResponse{} = existing_response ->
      existing_response
      |> SurveyResponse.changeset(response_attrs)
      |> Repo.update!()
  end
end)

IO.puts("Seeded 25 survey responses for #{survey.name}")
