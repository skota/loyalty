defmodule LoyaltyWeb.LoyaltyProgramLive.QRTest do
  use LoyaltyWeb.ConnCase

  import Loyalty.RewardsFixtures
  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  test "shows a qr thumbnail link for each loyalty program", %{conn: conn} do
    loyalty_program = loyalty_program_fixture(%{name: "Program With QR"})

    {:ok, view, _html} = live(conn, ~p"/loyalty_programs")

    assert has_element?(view, "#loyalty-program-qr-link-#{loyalty_program.id}")
    assert has_element?(view, "#loyalty-program-qr-thumb-#{loyalty_program.id}")
  end

  test "opens the qr page from the loyalty program index", %{conn: conn} do
    loyalty_program = loyalty_program_fixture(%{name: "Scan Me"})

    {:ok, view, _html} = live(conn, ~p"/loyalty_programs")

    {:ok, _qr_view, html} =
      view
      |> element("#loyalty-program-qr-link-#{loyalty_program.id}")
      |> render_click()
      |> follow_redirect(conn)

    assert html =~ "Download SVG"
    assert html =~ "Scan Me"
  end

  test "renders the qr image and download link on the qr page", %{conn: conn} do
    loyalty_program = loyalty_program_fixture(%{name: "Window Sticker"})

    {:ok, view, _html} = live(conn, ~p"/loyalty_programs/#{loyalty_program.id}/qr")

    assert has_element?(view, "#loyalty-program-qr-image")
    assert has_element?(view, "#loyalty-program-qr-download[download]")
    assert has_element?(view, "#loyalty-program-qr-token")
  end
end
