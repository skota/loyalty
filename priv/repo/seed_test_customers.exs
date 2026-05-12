# Script for creating a small set of predictable test customers.
#
# Run it with:
#
#     mix run priv/repo/seed_test_customers.exs

alias Loyalty.Repo
alias Loyalty.Rewards.Customer

test_customers = [
  %{
    name: "Test Customer 1",
    email: "test_customer_1@example.com",
    phone: "555-0001",
    device_id: "11111111-1111-1111-1111-111111111111",
    points_balance: 0,
    source: "seed",
    meta: %{"segment" => "test"}
  },
  %{
    name: "Test Customer 2",
    email: "test_customer_2@example.com",
    phone: "555-0002",
    device_id: "22222222-2222-2222-2222-222222222222",
    points_balance: 0,
    source: "seed",
    meta: %{"segment" => "test"}
  },
  %{
    name: "Test Customer 3",
    email: "test_customer_3@example.com",
    phone: "555-0003",
    device_id: "33333333-3333-3333-3333-333333333333",
    points_balance: 0,
    source: "seed",
    meta: %{"segment" => "test"}
  },
  %{
    name: "Test Customer 4",
    email: "test_customer_4@example.com",
    phone: "555-0004",
    device_id: "44444444-4444-4444-4444-444444444444",
    points_balance: 0,
    source: "seed",
    meta: %{"segment" => "test"}
  },
  %{
    name: "Test Customer 5",
    email: "test_customer_5@example.com",
    phone: "555-0005",
    device_id: "55555555-5555-5555-5555-555555555555",
    points_balance: 0,
    source: "seed",
    meta: %{"segment" => "test"}
  }
]

Enum.each(test_customers, fn attrs ->
  case Repo.get_by(Customer, email: attrs.email) do
    nil ->
      %Customer{}
      |> Customer.changeset(attrs)
      |> Repo.insert!()

      IO.puts("Inserted #{attrs.name}")

    _customer ->
      IO.puts("Skipped #{attrs.name} (already exists)")
  end
end)
