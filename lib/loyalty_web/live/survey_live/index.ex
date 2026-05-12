defmodule LoyaltyWeb.SurveyLive.Index do
  use LoyaltyWeb, :live_view

  alias Loyalty.Surveys
  alias Loyalty.Surveys.Survey

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:current_user, current_user(socket))
      |> assign(:current_path, "/surveys")
      |> assign(:sidebar_open, false)
      |> assign(:show_modal, false)
      |> assign(:show_delete_confirm, false)
      |> assign(:modal_action, nil)
      |> assign(:selected_survey, nil)
      |> assign(:loyalty_program_options, Surveys.list_loyalty_program_options())
      |> assign(:form, to_form(Surveys.change_survey(%Survey{})))
      |> stream(:surveys, Surveys.list_surveys(), reset: true)

    {:ok, socket}
  end

  @impl true
  @spec handle_event(<<_::32, _::_*8>>, any(), any()) :: {:noreply, any()}
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  @impl true
  def handle_event("close_sidebar", _params, socket) do
    {:noreply, assign(socket, :sidebar_open, false)}
  end

  @impl true
  def handle_event("show_new_modal", _params, socket) do
    {:noreply,
     assign(socket,
       show_modal: true,
       modal_action: :new,
       selected_survey: nil,
       form: to_form(Surveys.change_survey(%Survey{}))
     )}
  end

  @impl true
  def handle_event("show_edit_modal", %{"id" => id}, socket) do
    survey = Surveys.get_survey!(id)

    {:noreply,
     assign(socket,
       show_modal: true,
       modal_action: :edit,
       selected_survey: survey,
       form: to_form(Surveys.change_survey(survey))
     )}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, show_modal: false, selected_survey: nil)}
  end

  @impl true
  def handle_event("validate", %{"survey" => params}, socket) do
    changeset =
      case socket.assigns.modal_action do
        :edit -> Surveys.change_survey(socket.assigns.selected_survey, params)
        _ -> Surveys.change_survey(%Survey{}, params)
      end
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"survey" => params}, socket) do
    case socket.assigns.modal_action do
      :edit -> update_survey(socket, params)
      _ -> create_survey(socket, params)
    end
  end

  @impl true
  def handle_event("show_delete_confirm", %{"id" => id}, socket) do
    {:noreply,
     assign(socket,
       show_delete_confirm: true,
       selected_survey: Surveys.get_survey!(id)
     )}
  end

  @impl true
  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, show_delete_confirm: false, selected_survey: nil)}
  end

  @impl true
  def handle_event("confirm_delete", _params, socket) do
    case Surveys.delete_survey(socket.assigns.selected_survey) do
      {:ok, _survey} ->
        {:noreply,
         socket
         |> assign(:show_delete_confirm, false)
         |> assign(:selected_survey, nil)
         |> refresh_surveys()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Unable to delete survey.")}
    end
  end

  @impl true
  def handle_event("ignore", _params, socket) do
    {:noreply, socket}
  end

  defp create_survey(socket, params) do
    case Surveys.create_survey(params) do
      {:ok, _survey} ->
        {:noreply,
         socket
         |> assign(:show_modal, false)
         |> assign(:form, to_form(Surveys.change_survey(%Survey{})))
         |> refresh_surveys()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp update_survey(socket, params) do
    case Surveys.update_survey(socket.assigns.selected_survey, params) do
      {:ok, _survey} ->
        {:noreply,
         socket
         |> assign(:show_modal, false)
         |> assign(:selected_survey, nil)
         |> assign(:form, to_form(Surveys.change_survey(%Survey{})))
         |> refresh_surveys()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp refresh_surveys(socket) do
    stream(socket, :surveys, Surveys.list_surveys(), reset: true)
  end

  defp current_user(socket) do
    case socket.assigns.current_scope do
      %{user: user} when not is_nil(user) -> %{name: user.first_name, email: user.email}
      _ -> nil
    end
  end
end
