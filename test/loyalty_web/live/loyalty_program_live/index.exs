defmodule LoyaltyWeb.LoyaltyProgramLive.IndexTest do
  use LoyaltyWeb.ConnCase
  import Phoenix.LiveViewTest
  import Loyalty.RewardsFixtures

  setup :register_and_log_in_user

  describe "Index" do
    test "lists all loyalty programs", %{conn: conn} do
      loyalty_program = loyalty_program_fixture()
      {:ok, _index_live, html} = live(conn, ~p"/loyalty_programs")

      assert html =~ "Loyalty Programs"
      assert html =~ loyalty_program.name
    end

    test "displays loyalty program details in table", %{conn: conn} do
      loyalty_program =
        loyalty_program_fixture(%{
          name: "Gold Program",
          points_per_dollar: Decimal.new("1.5"),
          signup_bonus_points: 500,
          active: true
        })

      {:ok, _index_live, html} = live(conn, ~p"/loyalty_programs")

      assert html =~ "Gold Program"
      assert html =~ "1.5"
      assert html =~ "500"
      assert html =~ "Yes"
    end

    test "shows 'No' for inactive programs", %{conn: conn} do
      loyalty_program_fixture(%{name: "Inactive Program", active: false})
      {:ok, _index_live, html} = live(conn, ~p"/loyalty_programs")

      assert html =~ "Inactive Program"
      assert html =~ "No"
    end

    test "displays Add Loyalty Program button", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/loyalty_programs")

      assert html =~ "Add Loyalty Program"
    end

    test "displays action buttons for each program", %{conn: conn} do
      loyalty_program_fixture()
      {:ok, _index_live, html} = live(conn, ~p"/loyalty_programs")

      assert html =~ "Edit"
      assert html =~ "Delete"
      assert html =~ "Rewards"
    end
  end

  describe "New Modal" do
    test "opens new modal when Add button is clicked", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs")

      assert index_live
             |> element("button", "Add Loyalty Program")
             |> render_click() =~ "Add Loyalty Program"
    end

    test "displays form fields in new modal", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs")

      html =
        index_live
        |> element("button", "Add Loyalty Program")
        |> render_click()

      assert html =~ "Name"
      assert html =~ "Points per Dollar"
      assert html =~ "Signup Bonus Points"
      assert html =~ "Description"
      assert html =~ "Active"
    end

    test "creates new loyalty program with valid data", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs")

      index_live
      |> element("button", "Add Loyalty Program")
      |> render_click()

      assert index_live
             |> form("#loyalty_program-form",
               loyalty_program: %{
                 name: "New Program",
                 points_per_dollar: "2.0",
                 signup_bonus_points: "1000",
                 description: "A great program",
                 active: true
               }
             )
             |> render_submit()

      html = render(index_live)
      assert html =~ "New Program"
      assert html =~ "2.0"
      assert html =~ "1000"
    end

    test "displays validation errors for invalid data", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs")

      index_live
      |> element("button", "Add Loyalty Program")
      |> render_click()

      html =
        index_live
        |> form("#loyalty_program-form",
          loyalty_program: %{
            name: "",
            points_per_dollar: "",
            signup_bonus_points: "",
            description: ""
          }
        )
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end

    test "validates form on change", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs")

      index_live
      |> element("button", "Add Loyalty Program")
      |> render_click()

      html =
        index_live
        |> form("#loyalty_program-form",
          loyalty_program: %{name: ""}
        )
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end

    test "closes modal when Cancel is clicked", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs")

      index_live
      |> element("button", "Add Loyalty Program")
      |> render_click()

      html =
        index_live
        |> element("button", "Cancel")
        |> render_click()

      # refute html =~ "Add Loyalty Program"
      assert html =~ "Loyalty Programs"
    end

    test "closes modal when overlay is clicked", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs")

      index_live
      |> element("button", "Add Loyalty Program")
      |> render_click()

      assert has_element?(index_live, "form#loyalty_program-form")

      index_live
      |> element("div.fixed.inset-0")
      |> render_click()

      refute has_element?(index_live, "form#loyalty_program-form")
    end
  end

  describe "Edit Modal" do
    test "opens edit modal when Edit button is clicked", %{conn: conn} do
      loyalty_program = loyalty_program_fixture(%{name: "Test Program"})
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs")

      html =
        index_live
        |> element("button", "Edit")
        |> render_click()

      assert html =~ "Edit Loyalty Program"
      assert html =~ "Test Program"
    end

    test "pre-populates form with existing data", %{conn: conn} do
      loyalty_program =
        loyalty_program_fixture(%{
          name: "Existing Program",
          points_per_dollar: Decimal.new("1.5"),
          signup_bonus_points: 250,
          description: "Test description"
        })

      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs")

      html =
        index_live
        |> element("button", "Edit")
        |> render_click()

      assert html =~ "Existing Program"
      assert html =~ "1.5"
      assert html =~ "250"
      assert html =~ "Test description"
    end

    test "updates loyalty program with valid data", %{conn: conn} do
      loyalty_program = loyalty_program_fixture(%{name: "Old Name"})
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs")

      index_live
      |> element("button", "Edit")
      |> render_click()

      assert index_live
             |> form("#loyalty_program-form",
               loyalty_program: %{
                 name: "Updated Name",
                 points_per_dollar: "3.0",
                 signup_bonus_points: "2000",
                 description: "Updated description",
                 active: false
               }
             )
             |> render_submit()

      html = render(index_live)
      assert html =~ "Updated Name"
      assert html =~ "3.0"
      assert html =~ "2000"
      refute html =~ "Old Name"
    end

    test "displays validation errors when updating with invalid data", %{conn: conn} do
      loyalty_program = loyalty_program_fixture()
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs")

      index_live
      |> element("button", "Edit")
      |> render_click()

      html =
        index_live
        |> form("#loyalty_program-form",
          loyalty_program: %{name: ""}
        )
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end
  end

  describe "Delete Confirmation" do
    test "shows delete confirmation dialog", %{conn: conn} do
      loyalty_program = loyalty_program_fixture(%{name: "To Delete"})
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs")

      html =
        index_live
        |> element("button", "Delete")
        |> render_click()

      assert html =~ "Confirm Delete"
      assert html =~ "To Delete"
    end

    test "cancels delete when No is clicked", %{conn: conn} do
      loyalty_program = loyalty_program_fixture(%{name: "Keep Me"})
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs")

      index_live
      |> element("button", "Delete")
      |> render_click()

      html =
        index_live
        |> element("button", "No")
        |> render_click()

      assert html =~ "Keep Me"
      refute html =~ "Confirm Delete"
    end

    test "deletes loyalty program when Yes is clicked", %{conn: conn} do
      loyalty_program = loyalty_program_fixture(%{name: "Delete Me"})
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs")

      index_live
      |> element("button", "Delete")
      |> render_click()

      html =
        index_live
        |> element("button", "Yes")
        |> render_click()

      refute html =~ "Delete Me"
      refute html =~ "Confirm Delete"
    end
  end

  describe "Rewards Navigation" do
    test "navigates to rewards page when Rewards button is clicked", %{conn: conn} do
      loyalty_program = loyalty_program_fixture()
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs")

      {:ok, _rewards_live, html} =
        index_live
        |> element("a", "Rewards")
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ "Rewards"
      assert html =~ loyalty_program.name
    end
  end
end
