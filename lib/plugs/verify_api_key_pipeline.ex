defmodule Loyalty.VerifyApiKeyPipeline do
  import Plug.Conn
  import Ecto.Query, warn: false
  alias Loyalty.Repo
  alias Loyalty.Accounts.UserApikey
  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        verify_token(conn, token)

      _ ->
        conn |> send_resp(401, "Unauthorized") |> halt()
    end
  end

  defp verify_token(conn, token) do
    hash = :crypto.hash(:sha256, token) |> Base.encode16()

    case Repo.get_by(UserApikey, key_hash: hash) do
      nil ->
        conn |> send_resp(401, "Invalid token") |> halt()

      key ->
        assign(conn, :current_api_key, key)
    end
  end
end
