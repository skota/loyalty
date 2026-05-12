defmodule LoyaltyWeb.LoyaltyProgramLive.Index do
  use LoyaltyWeb, :live_view
  alias Loyalty.QRCode
  alias Loyalty.{Rewards, Accounts}
  alias Loyalty.Rewards.LoyaltyProgram

  @impl true
  def mount(_params, session, socket) do
    {user, _token} = Accounts.get_user_by_session_token(session["user_token"])
    current_user = %{name: user.first_name, email: user.email}

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:current_path, "/loyalty_programs")
      |> assign(:sidebar_open, false)
      |> assign(:loyalty_programs, Rewards.list_loyalty_programs())
      |> assign(:show_modal, false)
      |> assign(:show_delete_confirm, false)
      |> assign(:modal_action, nil)
      |> assign(:selected_program, nil)
      |> assign(:form, to_form(Rewards.change_loyalty_program(%LoyaltyProgram{})))

    {:ok, socket}
  end

  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  def handle_event("close_sidebar", _params, socket) do
    {:noreply, assign(socket, :sidebar_open, false)}
  end

  @impl true
  def handle_event("show_new_modal", _params, socket) do
    changeset = Rewards.change_loyalty_program(%LoyaltyProgram{})

    {:noreply,
     assign(socket,
       show_modal: true,
       modal_action: :new,
       selected_program: nil,
       form: to_form(changeset)
     )}
  end

  @impl true
  def handle_event("show_edit_modal", %{"id" => id}, socket) do
    program = Rewards.get_loyalty_program(id)
    changeset = Rewards.change_loyalty_program(program)

    {:noreply,
     assign(socket,
       show_modal: true,
       modal_action: :edit,
       selected_program: program,
       form: to_form(changeset)
     )}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, show_modal: false, selected_program: nil)}
  end

  @impl true
  def handle_event("save", %{"loyalty_program" => params}, socket) do
    case socket.assigns.modal_action do
      :new -> create_program(socket, params)
      :edit -> update_program(socket, params)
    end
  end

  @impl true
  def handle_event("show_delete_confirm", %{"id" => id}, socket) do
    program = Rewards.get_loyalty_program(id)

    {:noreply,
     assign(socket,
       show_delete_confirm: true,
       selected_program: program
     )}
  end

  @impl true
  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, show_delete_confirm: false, selected_program: nil)}
  end

  @impl true
  def handle_event("confirm_delete", _params, socket) do
    case Rewards.delete_loyalty_program(socket.assigns.selected_program) do
      {:ok, _} ->
        {:noreply,
         assign(socket,
           loyalty_programs: Rewards.list_loyalty_programs(),
           show_delete_confirm: false,
           selected_program: nil
         )}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("validate", %{"loyalty_program" => params}, socket) do
    changeset =
      case socket.assigns.modal_action do
        :new -> Rewards.change_loyalty_program(%LoyaltyProgram{}, params)
        :edit -> Rewards.change_loyalty_program(socket.assigns.selected_program, params)
      end
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  # phx-click ignore is needed to prevent event bubbling to outer div. Otherwise clicking
  # anywhere inside the modal will close it
  def handle_event("ignore", %{}, socket) do
    {:noreply, socket}
  end

  defp create_program(socket, params) do
    case Rewards.create_loyalty_program(params) do
      {:ok, _program} ->
        {:noreply,
         assign(socket,
           loyalty_programs: Rewards.list_loyalty_programs(),
           show_modal: false,
           form: to_form(Rewards.change_loyalty_program(%LoyaltyProgram{}))
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp update_program(socket, params) do
    case Rewards.update_loyalty_program(socket.assigns.selected_program, params) do
      {:ok, _program} ->
        {:noreply,
         assign(socket,
           loyalty_programs: Rewards.list_loyalty_programs(),
           show_modal: false,
           selected_program: nil,
           form: to_form(Rewards.change_loyalty_program(%LoyaltyProgram{}))
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def qr_thumbnail_data_uri(%LoyaltyProgram{} = loyalty_program) do
    QRCode.data_uri(loyalty_program)
  end
end
