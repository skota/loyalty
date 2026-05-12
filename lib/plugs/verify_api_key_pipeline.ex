defmodule Loyalty.VerifyApiKeyPipeline do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        # we are just faking it for now
        if token == "secret123" do
          assign(conn, :current_api_key, %{key: token})
        else
          conn |> send_resp(401, "Unauthorized") |> halt()
        end

      _ ->
        conn |> send_resp(401, "Unauthorized") |> halt()
    end
  end
end
