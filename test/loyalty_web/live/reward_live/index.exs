defmodule LoyaltyWeb.RewardLive.IndexTest do
  use LoyaltyWeb.ConnCase
  import Phoenix.LiveViewTest
  import Loyalty.RewardsFixtures

  setup :register_and_log_in_user

  describe "Index" do
    setup do
      loyalty_program = loyalty_program_fixture()
      %{loyalty_program: loyalty_program}
    end

    test "lists all rewards for a loyalty program", %{
      conn: conn,
      loyalty_program: loyalty_program
    } do
      reward = reward_fixture(%{loyalty_program_id: loyalty_program.id})
      {:ok, _index_live, html} = live(conn, ~p"/loyalty_programs/#{loyalty_program.id}/rewards")

      assert html =~ "Rewards"
      assert html =~ reward.name
    end

    test "displays reward details in table", %{conn: conn, loyalty_program: loyalty_program} do
      reward =
        reward_fixture(%{
          name: "Free Coffee",
          points_required: 100,
          description: "Get a free coffee",
          loyalty_program_id: loyalty_program.id
        })

      {:ok, _index_live, html} = live(conn, ~p"/loyalty_programs/#{loyalty_program.id}/rewards")

      assert html =~ "Free Coffee"
      assert html =~ "100"
      assert html =~ "Get a free coffee"
    end

    test "displays loyalty program name", %{conn: conn, loyalty_program: loyalty_program} do
      {:ok, _index_live, html} = live(conn, ~p"/loyalty_programs/#{loyalty_program.id}/rewards")

      assert html =~ loyalty_program.name
    end

    test "displays Add Reward button", %{conn: conn, loyalty_program: loyalty_program} do
      {:ok, _index_live, html} = live(conn, ~p"/loyalty_programs/#{loyalty_program.id}/rewards")

      assert html =~ "Add Reward"
    end

    test "displays action buttons for each reward", %{
      conn: conn,
      loyalty_program: loyalty_program
    } do
      reward_fixture(%{loyalty_program_id: loyalty_program.id})
      {:ok, _index_live, html} = live(conn, ~p"/loyalty_programs/#{loyalty_program.id}/rewards")

      assert html =~ "Edit"
      assert html =~ "Delete"
    end

    test "displays back link to loyalty programs", %{conn: conn, loyalty_program: loyalty_program} do
      {:ok, _index_live, html} = live(conn, ~p"/loyalty_programs/#{loyalty_program.id}/rewards")

      assert html =~ "Back to Loyalty Programs"
    end

    test "navigates back to loyalty programs when back link is clicked", %{
      conn: conn,
      loyalty_program: loyalty_program
    } do
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs/#{loyalty_program.id}/rewards")

      {:ok, _programs_live, html} =
        index_live
        |> element("a", "Back to Loyalty Programs")
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ "Loyalty Programs"
    end
  end

  describe "New Modal" do
    setup do
      loyalty_program = loyalty_program_fixture()
      %{loyalty_program: loyalty_program}
    end

    test "opens new modal when Add button is clicked", %{
      conn: conn,
      loyalty_program: loyalty_program
    } do
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs/#{loyalty_program.id}/rewards")

      html =
        index_live
        |> element("button", "Add Reward")
        |> render_click()

      assert html =~ "Add Reward"
    end

    test "displays form fields in new modal", %{conn: conn, loyalty_program: loyalty_program} do
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs/#{loyalty_program.id}/rewards")

      html =
        index_live
        |> element("button", "Add Reward")
        |> render_click()

      assert html =~ "Name"
      assert html =~ "Points Required"
      assert html =~ "Description"
    end

    test "creates new reward with valid data", %{conn: conn, loyalty_program: loyalty_program} do
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs/#{loyalty_program.id}/rewards")

      index_live
      |> element("button", "Add Reward")
      |> render_click()

      assert index_live
             |> form("#reward-form",
               reward: %{
                 name: "New Reward",
                 points_required: "500",
                 description: "A great reward"
               }
             )
             |> render_submit()

      html = render(index_live)
      assert html =~ "New Reward"
      assert html =~ "500"
      assert html =~ "A great reward"
    end

    test "automatically sets loyalty_program_id", %{conn: conn, loyalty_program: loyalty_program} do
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs/#{loyalty_program.id}/rewards")

      index_live
      |> element("button", "Add Reward")
      |> render_click()

      index_live
      |> form("#reward-form",
        reward: %{
          name: "Test Reward",
          points_required: "100",
          description: "Test"
        }
      )
      |> render_submit()

      # Verify reward was created with correct loyalty_program_id
      reward = Loyalty.Rewards.list_rewards(loyalty_program.id) |> List.first()
      assert reward.loyalty_program_id == loyalty_program.id
    end

    test "displays validation errors for invalid data", %{
      conn: conn,
      loyalty_program: loyalty_program
    } do
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs/#{loyalty_program.id}/rewards")

      index_live
      |> element("button", "Add Reward")
      |> render_click()

      html =
        index_live
        |> form("#reward-form",
          reward: %{
            name: "",
            points_required: "",
            description: ""
          }
        )
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end

    test "validates form on change", %{conn: conn, loyalty_program: loyalty_program} do
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs/#{loyalty_program.id}/rewards")

      index_live
      |> element("button", "Add Reward")
      |> render_click()

      html =
        index_live
        |> form("#reward-form", reward: %{name: ""})
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end

    test "closes modal when Cancel is clicked", %{conn: conn, loyalty_program: loyalty_program} do
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs/#{loyalty_program.id}/rewards")

      index_live
      |> element("button", "Add Reward")
      |> render_click()

      html =
        index_live
        |> element("button", "Cancel")
        |> render_click()

      assert html =~ "Rewards"
    end

    test "closes modal when overlay is clicked", %{conn: conn, loyalty_program: loyalty_program} do
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs/#{loyalty_program.id}/rewards")

      index_live
      |> element("button", "Add Reward")
      |> render_click()

      assert has_element?(index_live, "form#reward-form")

      index_live
      |> element("div.fixed.inset-0")
      |> render_click()

      refute has_element?(index_live, "form#reward-form")
    end
  end

  describe "Edit Modal" do
    setup do
      loyalty_program = loyalty_program_fixture()
      reward = reward_fixture(%{loyalty_program_id: loyalty_program.id})
      %{loyalty_program: loyalty_program, reward: reward}
    end

    test "opens edit modal when Edit button is clicked", %{
      conn: conn,
      loyalty_program: loyalty_program,
      reward: reward
    } do
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs/#{loyalty_program.id}/rewards")

      html =
        index_live
        |> element("button", "Edit")
        |> render_click()

      assert html =~ "Edit Reward"
      assert html =~ reward.name
    end

    test "pre-populates form with existing data", %{conn: conn, loyalty_program: loyalty_program} do
      reward =
        reward_fixture(%{
          name: "Existing Reward",
          points_required: 250,
          description: "Test description",
          loyalty_program_id: loyalty_program.id
        })

      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs/#{loyalty_program.id}/rewards")

      html =
        index_live
        |> element("button[phx-value-id='#{reward.id}']", "Edit")
        |> render_click()

      assert html =~ "Existing Reward"
      assert html =~ "250"
      assert html =~ "Test description"
    end

    test "updates reward with valid data", %{
      conn: conn,
      loyalty_program: loyalty_program,
      reward: reward
    } do
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs/#{loyalty_program.id}/rewards")

      index_live
      |> element("button", "Edit")
      |> render_click()

      assert index_live
             |> form("#reward-form",
               reward: %{
                 name: "Updated Reward",
                 points_required: "1000",
                 description: "Updated description"
               }
             )
             |> render_submit()

      html = render(index_live)
      assert html =~ "Updated Reward"
      assert html =~ "1000"
      assert html =~ "Updated description"
    end

    test "displays validation errors when updating with invalid data", %{
      conn: conn,
      loyalty_program: loyalty_program,
      reward: reward
    } do
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs/#{loyalty_program.id}/rewards")

      index_live
      |> element("button", "Edit")
      |> render_click()

      html =
        index_live
        |> form("#reward-form", reward: %{name: ""})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end
  end

  describe "Delete Confirmation" do
    setup do
      loyalty_program = loyalty_program_fixture()

      reward =
        reward_fixture(%{
          name: "To Delete",
          loyalty_program_id: loyalty_program.id
        })

      %{loyalty_program: loyalty_program, reward: reward}
    end

    test "shows delete confirmation dialog", %{
      conn: conn,
      loyalty_program: loyalty_program,
      reward: reward
    } do
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs/#{loyalty_program.id}/rewards")

      html =
        index_live
        |> element("button", "Delete")
        |> render_click()

      assert html =~ "Confirm Delete"
      assert html =~ "To Delete"
    end

    test "cancels delete when No is clicked", %{
      conn: conn,
      loyalty_program: loyalty_program,
      reward: reward
    } do
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs/#{loyalty_program.id}/rewards")

      index_live
      |> element("button", "Delete")
      |> render_click()

      html =
        index_live
        |> element("button", "No")
        |> render_click()

      assert html =~ "To Delete"
      refute html =~ "Confirm Delete"
    end

    test "deletes reward when Yes is clicked", %{
      conn: conn,
      loyalty_program: loyalty_program,
      reward: reward
    } do
      {:ok, index_live, _html} = live(conn, ~p"/loyalty_programs/#{loyalty_program.id}/rewards")

      index_live
      |> element("button", "Delete")
      |> render_click()

      html =
        index_live
        |> element("button", "Yes")
        |> render_click()

      refute html =~ "To Delete"
      refute html =~ "Confirm Delete"
    end
  end

  describe "Multiple Rewards" do
    setup do
      loyalty_program = loyalty_program_fixture()
      %{loyalty_program: loyalty_program}
    end

    test "displays multiple rewards for the same program", %{
      conn: conn,
      loyalty_program: loyalty_program
    } do
      reward1 = reward_fixture(%{name: "Reward 1", loyalty_program_id: loyalty_program.id})
      reward2 = reward_fixture(%{name: "Reward 2", loyalty_program_id: loyalty_program.id})
      reward3 = reward_fixture(%{name: "Reward 3", loyalty_program_id: loyalty_program.id})

      {:ok, _index_live, html} = live(conn, ~p"/loyalty_programs/#{loyalty_program.id}/rewards")

      assert html =~ "Reward 1"
      assert html =~ "Reward 2"
      assert html =~ "Reward 3"
    end

    test "only displays rewards for the current loyalty program", %{
      conn: conn,
      loyalty_program: loyalty_program
    } do
      other_program = loyalty_program_fixture(%{name: "Other Program"})

      reward1 = reward_fixture(%{name: "My Reward", loyalty_program_id: loyalty_program.id})
      reward2 = reward_fixture(%{name: "Other Reward", loyalty_program_id: other_program.id})

      {:ok, _index_live, html} = live(conn, ~p"/loyalty_programs/#{loyalty_program.id}/rewards")

      assert html =~ "My Reward"
      refute html =~ "Other Reward"
    end
  end
end
