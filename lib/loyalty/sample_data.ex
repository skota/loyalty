defmodule Loyalty.SampleData do
  @moduledoc """
  Module for generating sample data for testing or development.
  """

  import Ecto.Query, warn: false
  alias Loyalty.Repo
  alias Loyalty.Accounts
  alias Loyalty.Rewards


  def generate() do
    # 1. create team and users
    {_user, team} = create_user_and_team()

    # 2. Loyalty Program
    {:ok , loyalty_program} = Rewards.create_loyalty_program(%{
      name: "Sample Loyalty Program",
      description: "A sample loyalty program for testing.",
      points_per_dollar: 1,
      signup_bonus_points: 0,
      user_role: :team_member,
      active: true
    })

    # 3. Reward
    {:ok , _reward} = Rewards.create_reward(%{
      name: "Sample Reward",
      description: "A sample reward for testing.",
      points_required: 500,
      loyalty_program_id: loyalty_program.id
    })

    # 4. Customer
    {:ok , customer} = Rewards.create_customer(%{
      name: "Sample Customer",
      email: "customer@example.com",
      team_id: team.id,
      device_id: Ecto.UUID.generate(),
      points_balance: 0
    })

    # 5. Customer Loyalty Program
    {:ok , _customer_loyalty_program} = Rewards.create_customer_loyalty_program(%{
      customer_id: customer.id,
      loyalty_program_id: loyalty_program.id
    })

    purchase_params = %{
      "customer_id" => customer.id,
      "product_name" => "Taco supreme",
      "amount_cents" => 1500 ,
      "purchased_at" => DateTime.utc_now()
    }

    points_earned = Decimal.mult(loyalty_program.points_per_dollar, purchase_params["amount_cents"])
                    |> Decimal.to_integer() |> div(100)

    purchase_params = Map.put(purchase_params, "points_earned", points_earned)

    # 6. Record purchase, award loyalty points
    {:ok , _purchase} = record_purchase_and_award_loyalty_points(purchase_params, customer,loyalty_program.id)

  end


  def record_purchase_and_award_loyalty_points(purchase_params, customer, loyalty_program_id) do
    loyalty_point_transaction = %{
      "loyalty_program_id" => loyalty_program_id,
      "customer_id" => customer.id,
      "points" => purchase_params["points_earned"],
      "source" => "purchase",
      "notes" => "points for purchase of #{purchase_params["items"]}",
      "inserted_at" => DateTime.utc_now
    }

    # 1 - update contact balance - update_contact_changeset
    # 2 - insert purchase
    # 3 - add loyalty_points_transaction
    points_balance = (customer.points_balance + (purchase_params["points_earned"])) |> round()


    result = Ecto.Multi.new()
      |> Ecto.Multi.update(:customer, Rewards.update_customer_changeset(customer, %{points_balance: points_balance}))
      |> Ecto.Multi.insert(:purchase, Rewards.insert_purchase_changeset(purchase_params))
      |> Ecto.Multi.insert(:loyalty_points_transaction, Rewards.insert_loyalty_points_changeset(loyalty_point_transaction))
      |> Repo.transaction()

    case result do
      {:ok, %{customer: _customer, purchase: _purchase, loyalty_points_transaction: _loyalty_points_transaction}} ->
        {:ok, "success"}
      {:error, :customer, changeset, _} ->
        {:error, changeset}
      {:error, :purchase, changeset, _} ->
        IO.inspect changeset
        {:error, changeset}
      {:error, :loyalty_points_transaction, changeset, _} ->
        IO.inspect changeset
        {:error, changeset}
    end

  end

  def create_user_and_team() do
    {:ok, team} = Accounts.create_team(%{team_name: "Sample Team"})
    {:ok, user} = Accounts.register_with_email_password(%{
      email: "test@example.com",
      team_id: team.id,
      first_name: "Test",
      last_name: "User",

      password: "Secret123"
    })

    {:ok, _team_member} = Accounts.create_team_member(%{
      team_id: team.id,
      user_id: user.id,
      role: "admin"
    })

    {user, team}
  end

end
