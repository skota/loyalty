defmodule Loyalty.Rewards do
  @moduledoc """
  The Rewards context.
  """

  import Ecto.Query, warn: false
  alias Loyalty.Repo
  alias Loyalty.Rewards

  alias Loyalty.Rewards.{LoyaltyPointsTransaction,
              Reward, Purchase, Customer,
              LoyaltyProgram, CustomerLoyaltyProgram}


  # customer ---------
  def list_customers, do: Repo.all(Customer)
  def get_customer!(id), do: Repo.get!(Customer, id)


  def get_customer_by_device_id(id), do: Repo.get_by(Customer, device_id: id)

  def create_customer(attrs \\ %{}) do
    %Customer{}
    |> Customer.changeset(attrs)
    |> Repo.insert(on_conflict: :nothing)
  end

  def create_customer_loyalty_program(attrs \\ %{}) do
    %CustomerLoyaltyProgram{}
    |> CustomerLoyaltyProgram.changeset(attrs)
    |> Repo.insert(on_conflict: :nothing)
  end

  def update_device_token(attrs \\ %{}) do

    {:ok, device_id} = Ecto.UUID.dump(attrs["device_id"])

    # attrs contains contact_id or device_id
    customer = Repo.get_by(Customer, device_id: device_id)

    customer
      |> Customer.update_device_token_changeset(%{device_token: attrs["device_token"]})
      |> Repo.update()

  end

  def update_customer_changeset(customer, attrs) do
    customer
    |> Customer.update_changeset(attrs)
  end


  # Loyalty program ---------------------------------
  def create_loyalty_program(attrs) do
    %LoyaltyProgram{}
    |> LoyaltyProgram.changeset(attrs)
    |> Repo.insert()
  end

  def update_loyalty_program(%LoyaltyProgram{} = loyalty_program, attrs) do
    loyalty_program
    |> LoyaltyProgram.changeset(attrs)
    |> Repo.update()
  end

  def delete_loyalty_program(%LoyaltyProgram{} = loyalty_program) do
    Repo.delete(loyalty_program)
  end

  def change_loyalty_program(%LoyaltyProgram{} = loyalty_program, attrs \\ %{}) do
    LoyaltyProgram.changeset(loyalty_program, attrs)
  end

  def get_loyalty_program(id), do: Repo.get!(LoyaltyProgram, id)

  def list_loyalty_programs do
    Repo.all(LoyaltyProgram)
  end


  # Reward functions
  def list_rewards(loyalty_program_id) do
    Repo.all(from r in Reward,
      where: r.loyalty_program_id == ^loyalty_program_id,
      order_by: [desc: r.inserted_at])
  end

  def get_reward!(id), do: Repo.get!(Reward, id)

  def create_reward(attrs \\ %{}) do
    %Reward{}
    |> Reward.changeset(attrs)
    |> Repo.insert()
  end

  def update_reward(%Reward{} = reward, attrs) do
    reward
    |> Reward.changeset(attrs)
    |> Repo.update()
  end

  def delete_reward(%Reward{} = reward) do
    Repo.delete(reward)
  end

  def change_reward(%Reward{} = reward, attrs \\ %{}) do
    Reward.changeset(reward, attrs)
  end

  # loyalty point transactions
  def award_loyalty_points(purchase_params, loyalty_program_id) do
    # awarded when a purchase is made
    # 1 - find contact based on device_id and get current points
    customer = get_customer_by_device_id(purchase_params["device_id"])

    loyalty_program = Rewards.get_loyalty_program(loyalty_program_id)

    #from loyalty_program get "points_per_dollar" to compute points
    points = Decimal.mult(loyalty_program.points_per_dollar, purchase_params["amount"])
            |> Decimal.to_integer()

    purchase_params = %{
      "contact_id" => customer.id,
      "product_name" => purchase_params["items"],
      "amount_cents" => purchase_params["amount"] ,
      "points_earned" => points,
      "purchased_at" => DateTime.utc_now(),

    }

    loyalty_point_transaction = %{
      "loyalty_program_id" => loyalty_program.id,
      "customer_id" => customer.id,
      "points" => trunc(points/100),
      "source" => "purchase",
      "notes" => "points for purchase of #{purchase_params["items"]}",
      "inserted_at" => DateTime.utc_now
    }

    # 1 - update contact balance - update_contact_changeset  -> new func that returns changeset
    # 2 - insert purchase
    # 3 - add loyalty_points_transaction
    points_balance = (customer.points_balance + (points)/100) |> round()

    result = Ecto.Multi.new()
      |> Ecto.Multi.update(:customer, update_customer_changeset(customer, %{points_balance: points_balance}))
      |> Ecto.Multi.insert(:insert, insert_purchase_changeset(purchase_params))
      |> Ecto.Multi.insert(:loyalty_points_transaction, insert_loyalty_points_changeset(loyalty_point_transaction))
      |> Repo.transaction()

    case result do
      {:ok, %{customer: _customer, insert: _purchase, loyalty_points_transaction: _loyalty_points_transaction}} ->
        {:ok, "success"}
      {:error, :customer, changeset, _} ->
        {:error, changeset}
      {:error, :insert, changeset, _} ->
        {:error, changeset}
      {:error, :loyalty_points_transaction, changeset, _} ->
        {:error, changeset}
    end
  end


  def insert_purchase_changeset(attrs) do
    %Purchase{}
    |> Purchase.changeset(attrs)
  end

  def insert_loyalty_points_changeset(attrs) do
    %LoyaltyPointsTransaction{}
    |> LoyaltyPointsTransaction.changeset(attrs)
  end

  def redeem_loyalty_points(reward_params) do
    customer = get_customer!(reward_params["customer_id"])
    reward = get_reward!(reward_params["reward_id"])

    # team_contact = Teams.get_team_contact_by_contact_id(reward_params["contact_id"])

    # TODO: it is possible there may be multiple loyalty programs need to ffigure out how to handle it
    # for now we just deal with one
    # team = Teams.get_team(team_contact.team_id)
    loyalty_program = Rewards.get_loyalty_program(reward_params["loyalty_program_id"])


    loyalty_point_transaction = %{
      "loyalty_program_id" => loyalty_program.id,
      "customer_id" => customer.id,
      "points" => reward_params["points"],
      "source" => "redeem",
      "notes" => "Redeem points for #{reward.name}",
      "inserted_at" => DateTime.utc_now
    }

    points_balance = customer.points_balance - reward_params["points"]

    # IO.inspect "points balance: #{points_balance}"
    result = Ecto.Multi.new()
      |> Ecto.Multi.update(:customer, update_customer_changeset(customer, %{points_balance: points_balance}))
      |> Ecto.Multi.insert(:loyalty_points_transaction, insert_loyalty_points_changeset(loyalty_point_transaction))
      |> Repo.transaction()

    case result do
      {:ok, %{customer: _customer, loyalty_points_transaction: _loyalty_points_transaction}} ->
        # You redeemed #{reward.name} for #{reward.points_required} points. Your new balance is #{customer.points_balance}

        # device_token = customer.device_token

        # Task.async(fn ->
        #   Notifications.send_message(device_token, "You redeemed #{reward.name} for #{reward.points_required} points. Your new balance is #{customer.points_balance}")
        # end)

        {:ok, "success"}
      {:error, :customer, changeset, _} ->
        {:error, changeset}
      {:error, :loyalty_points_transaction, changeset, _} ->
        {:error, changeset}
    end
  end

  # purchases
  def get_purchase_by_device_id(device_id) do
    {:ok, id} = Ecto.UUID.dump(device_id)
    q = from p in "purchases",
        join: c in "customers", on: p.customer_id == c.id,
        where: c.device_id == ^id,
        select: %{
          amount: p.amount_cents,
          points: p.points_earned,
          purchased_at: p.purchased_at
        }


    Repo.all(q)

  end
end
