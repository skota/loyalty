defmodule Loyalty.RewardsQrTest do
  use Loyalty.DataCase, async: true

  import Loyalty.RewardsFixtures

  alias Loyalty.QRCode
  alias Loyalty.Rewards

  test "create_loyalty_program assigns a qr_code_token" do
    {:ok, loyalty_program} =
      Rewards.create_loyalty_program(%{
        name: "QR Ready Program",
        points_per_dollar: Decimal.new("2.5"),
        signup_bonus_points: 250,
        description: "Program with qr code",
        active: true
      })

    assert loyalty_program.qr_code_token
    assert String.match?(loyalty_program.qr_code_token, ~r/\A[0-9a-f-]{36}\z/)
  end

  test "builds an svg data uri for a loyalty program" do
    loyalty_program = loyalty_program_fixture()

    assert QRCode.data_uri(loyalty_program) =~ "data:image/svg+xml;base64,"
    assert QRCode.filename(loyalty_program) =~ "-qr.svg"
  end
end
