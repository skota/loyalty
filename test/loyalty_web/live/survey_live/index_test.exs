defmodule LoyaltyWeb.SurveyLive.IndexTest do
  use LoyaltyWeb.ConnCase

  import Phoenix.LiveViewTest
  import Loyalty.AccountsFixtures
  import Loyalty.RewardsFixtures

  test "authenticated users can create a survey", %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)
    loyalty_program = loyalty_program_fixture()

    {:ok, view, _html} = live(conn, ~p"/surveys")

    assert has_element?(view, "#new-survey-button")

    view
    |> element("#new-survey-button")
    |> render_click()

    assert has_element?(view, "#survey-form")

    view
    |> form("#survey-form", %{
      "survey" => %{
        "name" => "Weekly regulars",
        "message" => "How was your latest visit?",
        "loyalty_program_id" => loyalty_program.id,
        "purchase_count_threshold" => 3,
        "purchase_window_days" => 14,
        "active" => "true"
      }
    })
    |> render_submit()

    assert has_element?(view, "#surveys")
    assert render(view) =~ "Weekly regulars"
    assert render(view) =~ "3 purchases in 14 days"
  end
end
