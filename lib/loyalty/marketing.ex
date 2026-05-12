defmodule Loyalty.Marketing do
  import Ecto.Query, warn: false
  alias Loyalty.Notifications
  # Rep
  alias Loyalty.Repo,
        alias(Loyalty.Rewards.{
          Customer,
          LoyaltyProgram,
          CustomerLoyaltyProgram,
          LoyaltyPointsTransaction,
          Purchase,
          Reward
        })

  # Customers
  def list_Customers, do: Repo.all(Customer)
  def get_customer!(id), do: Repo.get!(Customer, id)

  def get_customer_by_device_id(id), do: Repo.get_by(Customer, device_id: id)

  def create_Customer(attrs \\ %{}) do
    %Customer{}
    |> Customer.changeset(attrs)
    |> Repo.insert(on_conflict: :nothing)
  end

  def update_device_token(attrs \\ %{}) do
    {:ok, device_id} = Ecto.UUID.dump(attrs["device_id"])

    # attrs contains Customer_id or device_id
    customer = Repo.get_by(Customer, device_id: device_id)

    customer
    |> Customer.update_device_token_changeset(%{device_token: attrs["device_token"]})
    |> Repo.update()
  end

  @spec update_customer_changeset(
          {map(), map()}
          | %{
              :__struct__ => atom() | %{:__changeset__ => map(), optional(any()) => any()},
              optional(atom()) => any()
            },
          :invalid | %{optional(:__struct__) => none(), optional(atom() | binary()) => any()}
        ) :: Ecto.Changeset.t()
  def update_customer_changeset(customer, attrs) do
    customer
    |> Customer.update_changeset(attrs)
  end

  # users loyalty memberships
  def get_loyalty_membership(device_id) do
    {:ok, id} = Ecto.UUID.dump(device_id)

    q =
      from c in "customers",
        join: clp in "customer_loyalty_programs",
        on: c.id == clp.customer_id,
        join: lp in "loyalty_programs",
        on: lp.id == clp.loyalty_program_id,
        where: c.device_id == ^id,
        order_by: [asc: clp.inserted_at],
        select: %{
          "id" => clp.id,
          "name" => lp.name,
          "description" => lp.description,
          "points_per_dollar" => lp.points_per_dollar,
          "joined_at" => clp.inserted_at
        }

    Repo.all(q)
  end

  def get_loyalty_membership_by_id(id) do
    Repo.get(CustomerLoyaltyProgram, id)
  end

  # loyalty point transactions
  @spec award_loyalty_points(nil | maybe_improper_list() | map()) ::
          {:error, any()} | {:ok, <<_::56>>}
  def award_loyalty_points(purchase_params) do
    # awarded when a purchase is made
    # 1 - find Customer based on device_id and get current points
    customer = get_customer_by_device_id(purchase_params["device_id"])

    cust_loyalty_program = get_loyalty_membership_by_id(purchase_params["cust_loyalty_program_id"])
    loyalty_program = get_loyalty_program(cust_loyalty_program.loyalty_program_id)

    # from loyalty_program get "points_per_dollar" to compute points
    points =
      Decimal.mult(loyalty_program.points_per_dollar, purchase_params["amount"])
      |> Decimal.to_integer()

    purchase_params = %{
      "customer_id" => customer.id,
      "total_amount" => purchase_params["amount"],
      "product_name" => purchase_params["items"],
      "amount_cents" => purchase_params["amount"],
      "points_earned" => points,
      "purchased_at" => DateTime.utc_now()
    }

    #redemption will be negative points, so we store as negative in the db and when showing to user we show absolute value of points
    loyalty_point_transaction = %{
      "loyalty_program_id" => loyalty_program.id,
      "customer_id" => customer.id,
      "points" => (trunc(points / 100) * -1),
      "source" => "purchase",
      "notes" => "points for purchase of #{purchase_params["items"]}",
      "inserted_at" => DateTime.utc_now()
    }

    IO.inspect("Existing balance: #{customer.points_balance}, new points: #{points / 100}")
    # 1 - update Customer balance - update_Customer_changeset  -> new func that returns changeset
    # 2 - insert purchase
    # 3 - add loyalty_points_transaction
    points_balance = (customer.points_balance + points / 100) |> round()
    IO.inspect("points balance: #{points_balance}")

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.update(
        :customer,
        update_customer_changeset(customer, %{points_balance: points_balance})
      )
      |> Ecto.Multi.insert(:insert, insert_purchase_changeset(purchase_params))
      |> Ecto.Multi.insert(
        :loyalty_points_transaction,
        insert_loyalty_points_changeset(loyalty_point_transaction)
      )

    result = Repo.transaction(multi)

    case result do
      {:ok,
       %{
         customer: _customer,
         insert: _purchase,
         loyalty_points_transaction: loyalty_points_transaction
       }} ->
        IO.inspect loyalty_points_transaction\
        # send push notification to user about points earned
        device_token = customer.device_token
        Task.async(fn ->
          Notifications.send_message(
            device_token,
            "You earned #{points / 100} points for your purchase of #{purchase_params["product_name"]}. Your new balance is #{points_balance} points."
          )
        end)
        {:ok, "success"}

      {:error, :customer, changeset, _} ->
        {:error, changeset}

      {:error, :insert, changeset, _} ->
        {:error, changeset}

      {:error, :loyalty_points_transaction, changeset, _} ->
        {:error, changeset}
    end
  end

  defp insert_purchase_changeset(attrs) do
    %Purchase{}
    |> Purchase.changeset(attrs)
  end

  defp insert_loyalty_points_changeset(attrs) do
    %LoyaltyPointsTransaction{}
    |> LoyaltyPointsTransaction.changeset(attrs)
  end

  def redeem_loyalty_points(reward_params) do
    customer = get_customer!(reward_params["customer_id"])
    reward = get_reward!(reward_params["reward_id"])

    loyalty_program =
      get_customer_loyalty_program_by(reward_params["loyalty_program_id"], reward_params["customer_id"])

    loyalty_point_transaction = %{
      "loyalty_program_id" => loyalty_program.id,
      "customer_id" => customer.id,
      "points" => (reward_params["points"] * -1),
      "source" => "redeem",
      "notes" => "Redeem points for #{reward.name}",
      "inserted_at" => DateTime.utc_now()
    }

    points_balance = customer.points_balance - reward_params["points"]

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.update(
        :customer_details,
        update_customer_changeset(customer, %{points_balance: points_balance})
      )
      |> Ecto.Multi.insert(
        :loyalty_points_transaction,
        insert_loyalty_points_changeset(loyalty_point_transaction)
      )

    result = Repo.transaction(multi)

    case result do
      {:ok, %{customer_details: customer_details, loyalty_points_transaction: _loyalty_points_transaction}} ->
        # You redeemed #{reward.name} for #{reward.points_required} points. Your new balance is #{Customer.points_balance}
        IO.inspect "Customer details: #{inspect(customer_details)}, reward: #{reward.name}, points required: #{reward.points_required}, new balance: #{points_balance}"
        device_token = customer_details.device_token

        Task.async(fn ->
          Notifications.send_message(
            device_token,
            "You redeemed #{reward.name} for #{reward.points_required} points. Your new balance is #{points_balance}"
          )
        end)

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

    q =
      from p in "purchases",
        join: c in "customers",
        on: p.customer_id == c.id,
        where: c.device_id == ^id,
        select: %{
          amount: p.amount_cents,
          points: p.points_earned,
          purchased_at: p.purchased_at
        }

    Repo.all(q)
  end

  # rewards
  def eligible_rewards(device_id) do
    {:ok, device_id} = Ecto.UUID.dump(device_id)

    customer =
      Customer
      |> Repo.get_by!(device_id: device_id)

    q =
      from c in "customers",
        join: tm in "customer_loyalty_programs",
        on: c.id == tm.customer_id,
        join: lp in "loyalty_programs",
        on: lp.id == tm.loyalty_program_id,
        join: r in "rewards",
        on: r.loyalty_program_id == lp.id,
        where: c.device_id == ^device_id and r.points_required <= ^customer.points_balance,
        select: %{
          id: r.id,
          loyalty_program_id: lp.id,
          name: r.name,
          description: r.description,
          points_required: r.points_required
        }

    Repo.all(q)
  end

  def get_reward!(id) do
    Repo.get!(Reward, id)
  end

  @spec get_reward_details(any(), any()) :: any()
  def get_reward_details(device_id, reward_id) do
    {:ok, device_id} = Ecto.UUID.dump(device_id)
    {reward_id, ""} = Integer.parse(reward_id)

    q =
      from c in "customers",
        join: tm in "customer_loyalty_programs",
        on: c.id == tm.customer_id,
        join: lp in "loyalty_programs",
        on: lp.id == tm.loyalty_program_id,
        join: r in "rewards",
        on: r.loyalty_program_id == lp.id,
        where: c.device_id == ^device_id and r.id <= ^reward_id,
        select: %{
          customer_name: c.name,
          customer_id: c.id,
          points_balance: c.points_balance,
          reward_id: r.id,
          reward_name: r.name,
          reward_description: r.description,
          points_required: r.points_required
        }

    Repo.one(q)
  end

  # loyalty programs
  def get_loyalty_program_by(loyalty_program_id, customer_id) do
    Repo.get_by(LoyaltyProgram, id: loyalty_program_id, customer_id: customer_id)
  end

  def get_loyalty_program(loyalty_program_id) do
    Repo.get_by(LoyaltyProgram, id: loyalty_program_id)
  end



  def get_loyalty_program_by_qrcode(id) do

    Repo.get_by(LoyaltyProgram, [qr_code_token: id])
  end

  def join_loyalty_program(loyalty_program_id, device_id) do
    {:ok, id} = Ecto.UUID.dump(device_id)

    customer = get_customer_by_device_id(id)
    loyalty_program = get_loyalty_program_by_qrcode(loyalty_program_id)

    # insert into customer_loyalty_programs (customer_id, loyalty_program_id, inserted_at) values ((select id from Customers where device_id = device_id), loyalty_program_id, now())
    params = %{
      "customer_id" => customer.id,
      "loyalty_program_id" => loyalty_program.id,
      "inserted_at" => DateTime.utc_now()
    }

    case create_customer_loyalty_program(params) do
      {:ok, _customer_loyalty_program} ->
        # returns 201 created
        {:ok, "Joined loyalty program"}

      {:error, changeset} ->

        {:error, "There was an error joining the loyalty program: #{inspect(changeset)} "}
      end

    # {:ok, "Joined loyalty program"}
  end

  def leave_loyalty_program(loyalty_program_id, device_id) do
    {:ok, id} = Ecto.UUID.dump(device_id)
    customer = get_customer_by_device_id(id)
    program = get_loyalty_program_by(loyalty_program_id, customer.id)

    Repo.delete(program)

    {:ok, "Left loyalty program"}
  end


  # customer loyalty program
  def create_customer_loyalty_program(attrs \\ %{}) do
    %CustomerLoyaltyProgram{}
    |> CustomerLoyaltyProgram.changeset(attrs)
    |> Repo.insert()
  end

  def get_customer_loyalty_program_by(loyalty_program_id, customer_id) do
    q = from clp in "customer_loyalty_programs",
        join: lp in "loyalty_programs",
        on: lp.id == clp.loyalty_program_id,
        join: c in "customers",
        on: c.id == clp.customer_id,
      where: clp.loyalty_program_id == ^loyalty_program_id and clp.customer_id == ^customer_id,
      select: %{
        id: lp.id,
        name: lp.name,
        description: lp.description,
        points_per_dollar: lp.points_per_dollar,
        active: true
      }


    Repo.one(q)
  end
end
