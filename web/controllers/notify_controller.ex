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


    door_info = @door_camera_map[String.to_integer(door_id)]

    {:ok, response} = HTTPoison.get "#{@camera_url}#{door_info.camera_id}"
    {:ok, image_path} = Briefly.create
    File.write!(image_path, response.body)

    text = "Knock knock! Someone is at the #{door_info.name}"

    # Elixir Slack doesn't appear to support file uploads: https://github.com/BlakeWilliams/Elixir-Slack/issues/96
    # Do this directly with HTTPoison instead
    HTTPoison.post!(@slack_file_url, {:multipart,
      [
        {"token", Application.get_env(:slack, :api_token)},
        {:file, image_path},
        {"channels", @slack_channels},
        {"title", "#{door_info.name} Snapshot"},
        {"initial_comment", text},
      ]
    })

    conn
    |> put_status(:accepted)
    |> json(%{result: :ok})
  end
end
