defmodule LoyaltyWeb.CustomerLive.Index do
  use LoyaltyWeb, :live_view
  alias Loyalty.{Accounts, Rewards}

  @impl true
  def mount(_params, session, socket) do
    {user, _token} = Accounts.get_user_by_session_token(session["user_token"])
    current_user = %{name: user.first_name, email: user.email}
    customers = Rewards.list_customers()

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:current_path, "/customers")
      |> assign(:sidebar_open, false)
      |> assign(:search_query, "")
      |> assign(:customers, customers)
      |> assign(:customer_count, length(customers))
      |> assign(:search_form, to_form(%{"query" => ""}, as: :search))

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  def handle_event("close_sidebar", _params, socket) do
    {:noreply, assign(socket, :sidebar_open, false)}
  end

  @impl true
  def handle_event("search", %{"search" => %{"query" => query}}, socket) do
    customers = Rewards.list_customers(query)

    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:customers, customers)
     |> assign(:customer_count, length(customers))
     |> assign(:search_form, to_form(%{"query" => query}, as: :search))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <LoyaltyWeb.DashboardLayout.dashboard
      current_path={@current_path}
      current_user={@current_user}
      sidebar_open={@sidebar_open}
    >
      <:inner_content>
        <div class="mx-auto max-w-7xl space-y-8 px-4 py-6 sm:px-6 lg:px-8">
          <section class="relative overflow-hidden rounded-[2rem] border border-slate-200 bg-[linear-gradient(135deg,#fefce8_0%,#ffffff_45%,#ecfeff_100%)] p-8 shadow-sm">
            <div class="absolute inset-y-0 right-0 hidden w-1/3 bg-[radial-gradient(circle_at_top,_rgba(234,179,8,0.16),_transparent_60%)] lg:block" />
            <div class="relative flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
              <div class="max-w-2xl space-y-3">
                <p class="text-sm font-semibold uppercase tracking-[0.25em] text-amber-600">
                  Customer Directory
                </p>
                <h1 class="font-serif text-4xl text-slate-900">
                  Keep your customer base searchable, readable, and ready for follow-up.
                </h1>
                <p class="max-w-xl text-sm leading-6 text-slate-600">
                  Browse the full customer list, spot high-balance members quickly, and filter in real time by name, email, phone, or device id.
                </p>
              </div>

              <div class="rounded-3xl border border-white/70 bg-white/80 px-5 py-4 shadow-sm backdrop-blur">
                <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500">
                  Visible Customers
                </p>
                <p class="mt-2 text-3xl font-semibold text-slate-900">{@customer_count}</p>
                <p class="mt-1 text-sm text-slate-500">Filtered from the current search.</p>
              </div>
            </div>
          </section>

          <section class="grid gap-4 md:grid-cols-3">
            <div class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
              <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500">
                Search Scope
              </p>
              <p class="mt-3 text-2xl font-semibold text-slate-900">Name to device</p>
              <p class="mt-2 text-sm leading-6 text-slate-600">
                Search checks customer name, email, phone, and device id to make support lookups fast.
              </p>
            </div>
            <div class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
              <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500">Signal</p>
              <p class="mt-3 text-2xl font-semibold text-slate-900">Points balance</p>
              <p class="mt-2 text-sm leading-6 text-slate-600">
                See loyalty balance inline so you can quickly identify engaged customers.
              </p>
            </div>
            <div class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
              <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500">Workflow</p>
              <p class="mt-3 text-2xl font-semibold text-slate-900">Realtime filtering</p>
              <p class="mt-2 text-sm leading-6 text-slate-600">
                Search updates live as you type, so the page stays responsive without extra clicks.
              </p>
            </div>
          </section>

          <section class="overflow-hidden rounded-[2rem] border border-slate-200 bg-white shadow-sm">
            <div class="border-b border-slate-200 px-6 py-5">
              <div class="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
                <div>
                  <h2 class="text-xl font-semibold text-slate-900">Customers</h2>
                  <p class="text-sm text-slate-500">
                    Search and review your customer records in one place.
                  </p>
                </div>

                <.form
                  for={@search_form}
                  id="customer-search-form"
                  phx-change="search"
                  class="w-full max-w-xl"
                >
                  <.input
                    field={@search_form[:query]}
                    type="text"
                    label="Search customers"
                    placeholder="Search by name, email, phone, or device id"
                  />
                </.form>
              </div>
            </div>

            <div class="overflow-x-auto">
              <table class="min-w-full text-left">
                <thead class="bg-slate-50 text-xs font-semibold uppercase tracking-[0.2em] text-slate-500">
                  <tr>
                    <th class="px-6 py-4">Customer</th>
                    <th class="px-6 py-4">Contact</th>
                    <th class="px-6 py-4">Device</th>
                    <th class="px-6 py-4">Points</th>
                    <th class="px-6 py-4">Source</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-slate-100 bg-white">
                  <tr :if={@customers == []}>
                    <td colspan="5" class="px-6 py-12 text-center text-sm text-slate-500">
                      {if @search_query == "",
                        do: "No customers found yet.",
                        else: "No customers match your search."}
                    </td>
                  </tr>
                  <tr :for={customer <- @customers} class="group">
                    <td class="px-6 py-5 align-top">
                      <div class="space-y-1">
                        <p class="font-semibold text-slate-900">
                          {customer.name || "Unnamed Customer"}
                        </p>
                        <p class="text-sm text-slate-500">
                          Added {Calendar.strftime(customer.inserted_at, "%b %-d, %Y")}
                        </p>
                      </div>
                    </td>
                    <td class="px-6 py-5 align-top text-sm leading-6 text-slate-600">
                      <p>{customer.email || "No email on file"}</p>
                      <p>{customer.phone || "No phone on file"}</p>
                    </td>
                    <td class="px-6 py-5 align-top text-sm text-slate-600">
                      <span class="rounded-2xl bg-slate-100 px-3 py-2 font-mono text-xs text-slate-700">
                        {customer.device_id}
                      </span>
                    </td>
                    <td class="px-6 py-5 align-top">
                      <span class="inline-flex rounded-full bg-amber-100 px-3 py-1 text-sm font-semibold text-amber-700">
                        {customer.points_balance || 0} pts
                      </span>
                    </td>
                    <td class="px-6 py-5 align-top text-sm text-slate-600">
                      {customer.source || "Unknown"}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>
        </div>
      </:inner_content>
    </LoyaltyWeb.DashboardLayout.dashboard>
    """
  end
end
