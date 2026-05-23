defmodule LoyaltyWeb.UserLive.Login do
  use LoyaltyWeb, :live_view

  alias Loyalty.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.login flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm space-y-4">
        <div class="text-center">
          <.header>
            <p>Log in</p>
            <:subtitle>
              <%= if @current_scope do %>
                You need to reauthenticate to perform sensitive actions on your account.
              <% else %>
                Don't have an account? <.link
                  navigate={~p"/users/register"}
                  class="font-semibold text-brand hover:underline"
                  phx-no-format
                >Sign up</.link> for an account now.
                <span class="sr-only">Register</span>
              <% end %>
            </:subtitle>
          </.header>
        </div>

        <div :if={local_mail_adapter?()} class="alert alert-info">
          <.icon name="hero-information-circle" class="size-6 shrink-0" />
          <div>
            <p>You are running the local mail adapter.</p>
            <p>
              To see sent emails, visit <.link href="/dev/mailbox" class="underline">the mailbox page</.link>.
            </p>
          </div>
        </div>

        <.form
          for={@magic_form}
          id="login_form_magic"
          phx-submit="submit_magic"
          class="space-y-4"
        >
          <.input
            readonly={!!@current_scope}
            id="login_form_magic_email"
            field={@magic_form[:email]}
            type="email"
            label="Email"
            autocomplete="email"
            required
          />
          <.button class="btn btn-primary btn-soft w-full">
            Log in with email
          </.button>
        </.form>

        <div class="relative py-2">
          <div class="absolute inset-0 flex items-center">
            <div class="w-full border-t border-slate-200" />
          </div>
          <div class="relative flex justify-center text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">
            <span class="bg-white px-3">or use your password</span>
          </div>
        </div>

        <.form
          for={@password_form}
          id="login_form_password"
          action={~p"/users/log-in"}
          phx-submit="submit_password"
          phx-trigger-action={@trigger_submit}
        >
          <.input
            readonly={!!@current_scope}
            id="login_form_password_email"
            field={@password_form[:email]}
            type="email"
            label="Email"
            autocomplete="email"
            required
          />
          <.input
            field={@password_form[:password]}
            type="password"
            label="Password"
            autocomplete="current-password"
          />
          <.button
            class="btn btn-primary w-full"
            name={@password_form[:remember_me].name}
            value="true"
          >
            Log in and stay logged in <span aria-hidden="true">→</span>
          </.button>
          <.button class="btn btn-primary btn-soft w-full mt-2">
            Log in only this time
          </.button>
        </.form>
      </div>
    </Layouts.login>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    password_form =
      to_form(
        %{"email" => email, "password" => nil, "remember_me" => false},
        as: "user"
      )

    magic_form = to_form(%{"email" => email}, as: "user")

    {:ok,
     assign(socket,
       magic_form: magic_form,
       password_form: password_form,
       trigger_submit: false
     )}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:loyalty, Loyalty.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
