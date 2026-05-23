defmodule LoyaltyWeb.PageController do
  use LoyaltyWeb, :controller

  def home(conn, _params) do
    current_user = conn.assigns.current_scope && conn.assigns.current_scope.user

    if current_user do
      conn
      |> redirect(to: ~p"/dashboard")
    else
      render(conn, :home)
    end
  end
end
