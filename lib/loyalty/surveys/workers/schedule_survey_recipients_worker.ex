defmodule Loyalty.Surveys.Workers.ScheduleSurveyRecipientsWorker do
  use Oban.Worker, queue: :survey_scheduler, max_attempts: 1

  alias Loyalty.Surveys

  @impl Oban.Worker
  def perform(_job) do
    Surveys.schedule_active_surveys()
    :ok
  end
end
