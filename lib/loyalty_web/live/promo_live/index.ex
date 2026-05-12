defmodule LoyaltyWeb.PromoLive.Index do
  use LoyaltyWeb, :live_view
  alias Loyalty.Accounts

  @impl true
  def mount(_params, session, socket) do
    {user, _token} = Accounts.get_user_by_session_token(session["user_token"])
    current_user = %{name: user.first_name, email: user.email}

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:current_path, "/promos")
      |> assign(:sidebar_open, false)

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
  def render(assigns) do
    ~H"""
    <LoyaltyWeb.DashboardLayout.dashboard
      current_path={@current_path}
      current_user={@current_user}
      sidebar_open={@sidebar_open}
    >
      <:inner_content>
        <h1 class="text-2xl font-semibold">Promos</h1>
        <!-- page-specific content -->
        <h1>You are on the promos page</h1>
      </:inner_content>
    </LoyaltyWeb.DashboardLayout.dashboard>
    """
  end
end
