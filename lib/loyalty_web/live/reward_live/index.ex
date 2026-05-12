defmodule LoyaltyWeb.RewardLive.Index do
  use LoyaltyWeb, :live_view
  alias Loyalty.{Rewards, Accounts}
  alias Loyalty.Rewards.Reward

  @impl true
  def mount(%{"id" => loyalty_program_id}, session, socket) do
    {user, _token} = Accounts.get_user_by_session_token(session["user_token"])
    current_user = %{name: user.first_name, email: user.email}
    loyalty_program = Rewards.get_loyalty_program(loyalty_program_id)
    rewards = Rewards.list_rewards(loyalty_program_id)

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:current_path, "/loyalty_programs")
      |> assign(:sidebar_open, false)
      |> assign(:loyalty_program, loyalty_program)
      |> assign(:loyalty_program_id, loyalty_program_id)
      |> assign(:rewards, rewards)
      |> assign(:show_modal, false)
      |> assign(:show_delete_confirm, false)
      |> assign(:modal_action, nil)
      |> assign(:selected_reward, nil)
      |> assign(:form, to_form(Rewards.change_reward(%Reward{})))

    {:ok, socket}
  end

  @impl true
  @spec handle_event(<<_::32, _::_*8>>, any(), any()) :: {:noreply, any()}
  def handle_event("show_new_modal", _params, socket) do
    changeset =
      Rewards.change_reward(%Reward{loyalty_program_id: socket.assigns.loyalty_program_id})

    {:noreply,
     assign(socket,
       show_modal: true,
       modal_action: :new,
       selected_reward: nil,
       form: to_form(changeset)
     )}
  end

  @impl true
  def handle_event("show_edit_modal", %{"id" => id}, socket) do
    reward = Rewards.get_reward!(id)
    changeset = Rewards.change_reward(reward)

    {:noreply,
     assign(socket,
       show_modal: true,
       modal_action: :edit,
       selected_reward: reward,
       form: to_form(changeset)
     )}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, show_modal: false, selected_reward: nil)}
  end

  @impl true
  def handle_event("save", %{"reward" => params}, socket) do
    params = Map.put(params, "loyalty_program_id", socket.assigns.loyalty_program_id)

    case socket.assigns.modal_action do
      :new -> create_reward(socket, params)
      :edit -> update_reward(socket, params)
    end
  end

  @impl true
  def handle_event("show_delete_confirm", %{"id" => id}, socket) do
    reward = Rewards.get_reward!(id)

    {:noreply,
     assign(socket,
       show_delete_confirm: true,
       selected_reward: reward
     )}
  end

  @impl true
  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, show_delete_confirm: false, selected_reward: nil)}
  end

  @impl true
  def handle_event("confirm_delete", _params, socket) do
    case Rewards.delete_reward(socket.assigns.selected_reward) do
      {:ok, _} ->
        {:noreply,
         assign(socket,
           rewards: list_rewards(socket.assigns.loyalty_program_id),
           show_delete_confirm: false,
           selected_reward: nil
         )}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("validate", %{"reward" => params}, socket) do
    params = Map.put(params, "loyalty_program_id", socket.assigns.loyalty_program_id)

    changeset =
      case socket.assigns.modal_action do
        :new -> Rewards.change_reward(%Reward{}, params)
        :edit -> Rewards.change_reward(socket.assigns.selected_reward, params)
      end
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  # phx-click ignore is needed to prevent event bubbling to outer div. Otherwise clicking
  # anywhere inside the modal will close it
  def handle_event("ignore", %{}, socket) do
    {:noreply, socket}
  end

  defp create_reward(socket, params) do
    case Rewards.create_reward(params) do
      {:ok, _reward} ->
        {:noreply,
         assign(socket,
           rewards: list_rewards(socket.assigns.loyalty_program_id),
           show_modal: false,
           form:
             to_form(
               Rewards.change_reward(%Reward{
                 loyalty_program_id: socket.assigns.loyalty_program_id
               })
             )
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp update_reward(socket, params) do
    case Rewards.update_reward(socket.assigns.selected_reward, params) do
      {:ok, _reward} ->
        {:noreply,
         assign(socket,
           rewards: list_rewards(socket.assigns.loyalty_program_id),
           show_modal: false,
           selected_reward: nil,
           form:
             to_form(
               Rewards.change_reward(%Reward{
                 loyalty_program_id: socket.assigns.loyalty_program_id
               })
             )
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp list_rewards(loyalty_program_id) do
    Rewards.list_rewards(loyalty_program_id)
  end
end
