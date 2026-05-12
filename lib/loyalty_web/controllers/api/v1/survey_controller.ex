defmodule LoyaltyWeb.Api.V1.SurveyController do
  use LoyaltyWeb, :controller

  alias Loyalty.Surveys

  def index(conn, %{"device_id" => device_id}) do
    case Surveys.list_pending_surveys_for_device(device_id) do
      {:error, reason} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: reason})

      surveys ->
        conn
        |> put_status(:ok)
        |> json(surveys)
        # |> json(%{data: surveys})
    end
  end

  @spec create_response(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create_response(conn, %{"survey_response" => params}) do
    case Surveys.submit_response_for_device(params) do
      {:ok, response} ->
        conn
        |> put_status(:created)
        |> json(%{
          data: %{
            id: response.id,
            survey_id: response.survey_id,
            rating: response.rating,
            additional_feedback: response.additional_feedback,
            submitted_at: response.submitted_at
          }
        })

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: translate_errors(changeset)})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      opts_map = Map.new(opts, fn {key, value} -> {to_string(key), value} end)

      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts_map |> Map.get(key, key) |> to_string()
      end)
    end)
  end
end
