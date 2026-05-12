defmodule Loyalty.QRCode do
  @moduledoc false

  alias Loyalty.Rewards.LoyaltyProgram

  def payload(%LoyaltyProgram{qr_code_token: qr_code_token}) do
    "loyalty-program:" <> qr_code_token
  end

  def svg(%LoyaltyProgram{} = loyalty_program) do
    loyalty_program
    |> payload()
    |> EQRCode.encode()
    |> EQRCode.svg()
    |> IO.iodata_to_binary()
  end

  def data_uri(%LoyaltyProgram{} = loyalty_program) do
    "data:image/svg+xml;base64," <> (loyalty_program |> svg() |> Base.encode64())
  end

  def filename(%LoyaltyProgram{name: name}) do
    slug =
      name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/u, "-")
      |> String.trim("-")
      |> case do
        "" -> "loyalty-program"
        value -> value
      end

    "#{slug}-qr.svg"
  end
end
