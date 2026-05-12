defmodule LoyaltyWeb.LoyaltyProgramLive.QR do
  use LoyaltyWeb, :live_view

  alias Loyalty.QRCode
  alias Loyalty.{Accounts, Rewards}

  @impl true
  def mount(%{"id" => id}, session, socket) do
    {user, _token} = Accounts.get_user_by_session_token(session["user_token"])
    loyalty_program = Rewards.get_loyalty_program(id)

    socket =
      socket
      |> assign(:current_user, %{name: user.first_name, email: user.email})
      |> assign(:current_path, "/loyalty_programs")
      |> assign(:sidebar_open, false)
      |> assign(:loyalty_program, loyalty_program)
      |> assign(:qr_code_data_uri, QRCode.data_uri(loyalty_program))
      |> assign(:qr_code_download_name, QRCode.filename(loyalty_program))

    {:ok, socket}
  end
end
