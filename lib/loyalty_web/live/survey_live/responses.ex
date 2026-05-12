defmodule LoyaltyWeb.SurveyLive.Responses do
  use LoyaltyWeb, :live_view

  alias Loyalty.Surveys

  @chart_height 220
  @chart_width 620

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    %{survey: survey, responses: responses, summary: summary} = Surveys.get_survey_dashboard!(id)

    socket =
      socket
      |> assign(:current_user, current_user(socket))
      |> assign(:current_path, "/surveys")
      |> assign(:sidebar_open, false)
      |> assign(:survey, survey)
      |> assign(:responses, responses)
      |> assign(:summary, summary)
      |> assign(:rating_chart, rating_chart(summary.rating_counts))
      |> assign(:timeline_chart, timeline_chart(summary.response_timeline))

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  @impl true
  def handle_event("close_sidebar", _params, socket) do
    {:noreply, assign(socket, :sidebar_open, false)}
  end

  defp current_user(socket) do
    case socket.assigns.current_scope do
      %{user: user} when not is_nil(user) -> %{name: user.first_name, email: user.email}
      _ -> nil
    end
  end

  defp rating_chart(rating_counts) do
    max_count =
      rating_counts
      |> Enum.map(& &1.count)
      |> case do
        [] -> 1
        counts -> Enum.max(counts)
      end
      |> Kernel.max(1)

    bar_width = 72
    gap = 36
    left_padding = 42
    base_y = 180

    bars =
      rating_counts
      |> Enum.with_index()
      |> Enum.map(fn {%{rating: rating, count: count}, index} ->
        height =
          if count == 0 do
            8
          else
            round(count / max_count * 132)
          end

        x = left_padding + index * (bar_width + gap)
        y = base_y - height

        %{
          rating: rating,
          count: count,
          x: x,
          y: y,
          width: bar_width,
          height: height,
          label_x: x + div(bar_width, 2)
        }
      end)

    %{bars: bars, base_y: base_y, width: @chart_width, height: @chart_height}
  end

  defp timeline_chart([]) do
    %{points: "", labels: [], width: @chart_width, height: @chart_height, base_y: 176}
  end

  defp timeline_chart(timeline) do
    max_count =
      timeline
      |> Enum.map(& &1.count)
      |> case do
        [] -> 1
        counts -> Enum.max(counts)
      end
      |> Kernel.max(1)

    count = length(timeline)
    usable_width = 520
    x_start = 54
    y_base = 176
    usable_height = 118
    step = if count == 1, do: 0, else: usable_width / (count - 1)

    points =
      timeline
      |> Enum.with_index()
      |> Enum.map(fn {%{count: response_count}, index} ->
        x = x_start + step * index
        y = y_base - response_count / max_count * usable_height
        "#{round_coord(x)},#{round_coord(y)}"
      end)
      |> Enum.join(" ")

    labels =
      timeline
      |> Enum.with_index()
      |> Enum.map(fn {%{date: date, count: response_count}, index} ->
        x = x_start + step * index
        y = y_base - response_count / max_count * usable_height

        %{
          x: round_coord(x),
          y: round_coord(y),
          date: Calendar.strftime(date, "%b %-d"),
          count: response_count
        }
      end)

    %{points: points, labels: labels, width: @chart_width, height: @chart_height, base_y: y_base}
  end

  defp round_coord(value) when is_integer(value), do: value
  defp round_coord(value) when is_float(value), do: Float.round(value, 1)
end
