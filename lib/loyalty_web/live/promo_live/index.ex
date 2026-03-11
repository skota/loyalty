defmodule LoyaltyWeb.PromoLive.Index do
  use LoyaltyWeb, :live_view


  def mount(_params, _session, socket) do
    # {:ok, assign(socket, :current_scope, session["current_scope"])}
    # TODO: fetch actual user from session
    current_user = %{name: "user", email: "user@mail.com"}

    socket = socket
          |> assign(:current_user, current_user)
          |> assign(:current_path, "/promos")
          |> assign(:sidebar_open, false)

    {:ok, socket}
  end

  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  def handle_event("close_sidebar", _params, socket) do
    {:noreply, assign(socket, :sidebar_open, false)}
  end

  # def handle_params(_params, uri, socket) do
  #   {:noreply, assign(socket, :current_path, uri.path)}
  # end


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
          <h1> You are on the promos page </h1>
        </:inner_content>
      </LoyaltyWeb.DashboardLayout.dashboard>
    """
  end


end
