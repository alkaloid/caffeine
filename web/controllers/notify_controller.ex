defmodule Caffeine.NotifyController do
  use Caffeine.Web, :controller
  require Logger

  @door_camera_map %{
    1 => %{name: "Central - Front Door", camera_id: 5},
    2 => %{name: "Central - Side Door", camera_id: 5},
    3 => %{name: "West Wing - Front Door", camera_id: 6},
    4 => %{name: "Central - Back Door", camera_id: 3},
  }

  @camera_url "http://krog.local/cgi-bin/nph-zms?mode=single&monitor="
  @slack_file_url "https://slack.com/api/files.upload" 
  @slack_channels "@katharine" # comma separated

  def create(conn, %{"target" => target, "message" => message}) do
    send :slack, {:message, message, target}
    conn
    |> put_status(:accepted)
    |> json(%{result: :ok})
  end
  def create(conn, params) do
    Logger.error "Bad request: #{inspect params}"
    conn
    |> put_status(:bad_request)
    |> json(%{error: "You must supply at least a target and a message as parameters"})
  end

  def door_bell(conn, %{"door_id" => door_id}) do
    Caffeine.DoorBell.ring(door_id)

    conn
    |> put_status(:accepted)
    |> json(%{result: :ok})
  end
end
