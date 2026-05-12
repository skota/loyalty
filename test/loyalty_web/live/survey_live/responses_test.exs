defmodule LoyaltyWeb.SurveyLive.ResponsesTest do
  use LoyaltyWeb.ConnCase

  import Phoenix.LiveViewTest
  import Loyalty.AccountsFixtures
  import Loyalty.RewardsFixtures

  alias Loyalty.Repo
  alias Loyalty.Rewards.Customer
  alias Loyalty.Surveys.{Survey, SurveyRecipient, SurveyResponse}

  test "shows native svg charts and response details", %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)
    loyalty_program = loyalty_program_fixture()

    survey =
      Repo.insert!(%Survey{
        loyalty_program_id: loyalty_program.id,
        name: "Chart Ready Survey",
        message: "Tell us about your visit.",
        purchase_count_threshold: 2,
        purchase_window_days: 14,
        active: true
      })

    customer =
      Repo.insert!(%Customer{
        device_id: Ecto.UUID.generate(),
        name: "Chart Customer",
        email: "chart_customer@example.com",
        points_balance: 0
      })

    recipient =
      Repo.insert!(%SurveyRecipient{
        survey_id: survey.id,
        customer_id: customer.id,
        status: :responded,
        notification_sent_at: DateTime.utc_now() |> DateTime.truncate(:second),
        responded_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })

    Repo.insert!(%SurveyResponse{
      survey_id: survey.id,
      customer_id: customer.id,
      survey_recipient_id: recipient.id,
      rating: 5,
      additional_feedback: "Amazing experience.",
      submitted_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })

    {:ok, view, _html} = live(conn, ~p"/surveys/#{survey.id}/responses")

    assert has_element?(view, "svg[aria-label='Rating distribution chart']")
    assert has_element?(view, "svg[aria-label='Survey response timeline chart']")
    assert render(view) =~ "Chart Ready Survey"
    assert render(view) =~ "Amazing experience."
  end
end
