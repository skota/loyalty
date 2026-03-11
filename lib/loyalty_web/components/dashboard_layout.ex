defmodule LoyaltyWeb.DashboardLayout do
  use LoyaltyWeb, :html

  attr :current_path, :string, required: true
  attr :current_user, :any, default: nil
  attr :sidebar_open, :any, default: false
  slot :inner_content, required: true

  def dashboard(assigns) do
    ~H"""
      <div class="min-h-screen bg-gray-100">
      <!-- Mobile top bar -->
      <div class="md:hidden flex items-center justify-between bg-white px-4 py-3 border-b">
        <span class="font-semibold text-gray-900">Dashboard</span>

        <button
          phx-click="toggle_sidebar"
          class="p-2 rounded-md hover:bg-gray-100"
          aria-label="Open menu"
        >
          <.icon name="hero-bars-3" class="w-6 h-6" />
        </button>
      </div>

      <div class="flex relative">
        <!-- Mobile overlay -->
        <div
          :if={@sidebar_open}
          phx-click="close_sidebar"
          class="fixed inset-0 bg-black/30 z-30 md:hidden"
        />

        <!-- Sidebar -->
        <aside
          class={[
            "fixed md:fixed inset-y-0 left-0 z-40 w-64 h-screen bg-gray-100 border-r flex flex-col",
            "transform transition-transform duration-200",
            @sidebar_open && "translate-x-0",
            !@sidebar_open && "-translate-x-full",
            "md:static md:translate-x-0"
          ]}
        >
          <!-- Navigation (takes remaining space) -->
          <nav class="flex-1 overflow-y-auto p-4 space-y-1 pb-10">
            <.menu_item icon="hero-home" label="Dashboard" to="/dashboard" current_path={@current_path} />
            <.menu_item icon="hero-credit-card" label="Loyalty program" to="/loyalty_programs" current_path={@current_path} />
            <.menu_item icon="hero-user" label="Customer" to="/customers" current_path={@current_path} />
            <.menu_item icon="hero-gift" label="Promos" to="/promos" current_path={@current_path} />
            <.menu_item icon="hero-chart-bar" label="Analytics" to="/analytics" current_path={@current_path} />
          </nav>

          <!-- Footer (always bottom, visually separated) -->
          <!-- Footer -->
          <div class="mt-6 p-4 border-t text-sm text-grey-900">
            <div class="flex flex-col gap-3">
              <span class="truncate">
                <%= @current_user && @current_user.email || "" %>
              </span>

              <.link
                href="/users/log-out"
                method="delete"
                class="flex items-center gap-2 hover:text-gray-900"
              >
                <.icon name="hero-cog-6-tooth" class="w-5 h-5" />
                <span>Logout</span>
              </.link>
            </div>
          </div>
        </aside>

        <!-- Main content -->
        <main class="flex-1 bg-white p-4 md:p-6  border border-slate-200">
          <%= render_slot(@inner_content) %>
        </main>
      </div>
    </div>
    """
  end
end
