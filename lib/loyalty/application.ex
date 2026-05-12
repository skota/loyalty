defmodule Loyalty.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      LoyaltyWeb.Telemetry,
      Loyalty.Repo,
      {Oban, Application.fetch_env!(:loyalty, Oban)},
      {DNSCluster, query: Application.get_env(:loyalty, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Loyalty.PubSub},
      # Start a worker by calling: Loyalty.Worker.start_link(arg)
      # {Loyalty.Worker, arg},
      # Start to serve requests, typically the last entry
      LoyaltyWeb.Endpoint
    ]
    |> maybe_add_goth()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Loyalty.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LoyaltyWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp maybe_add_goth(children) do
    case load_google_credentials() do
      {:ok, credentials} ->
        children ++
          [
            {Goth,
             name: Loyalty.Goth,
             source:
               {:service_account, credentials,
                scopes: ["https://www.googleapis.com/auth/firebase.messaging"]}}
          ]

      {:error, reason} ->
        Logger.warning("Skipping Goth startup: #{reason}")
        children
    end
  end

  defp load_google_credentials do
    with credentials when is_binary(credentials) and credentials != "" <-
           System.get_env("GOOGLE_APPLICATION_CREDENTIALS_JSON"),
         {:ok, decoded} <- Jason.decode(credentials) do
      {:ok, decoded}
    else
      nil -> {:error, "GOOGLE_APPLICATION_CREDENTIALS_JSON is not set"}
      "" -> {:error, "GOOGLE_APPLICATION_CREDENTIALS_JSON is empty"}
      {:error, _reason} -> {:error, "GOOGLE_APPLICATION_CREDENTIALS_JSON is not valid JSON"}
    end
  end
end
