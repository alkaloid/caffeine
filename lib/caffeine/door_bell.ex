defmodule Caffeine.DoorBell do
  require Logger

  use GenServer
  
  @name :door_bell
  @slack_file_url "https://slack.com/api/files.upload" 
  @slack_channels "@bklang" # comma separated
  @camera_url "http://krog.local/cgi-bin/nph-zms?mode=single&monitor="
  @door_camera_map %{
    1 => %{name: "Central - Front Door", camera_id: 5},
    2 => %{name: "Central - Side Door", camera_id: 5},
    3 => %{name: "West Wing - Front Door", camera_id: 6},
    4 => %{name: "Central - Back Door", camera_id: 3},
  }

  @doc """
    Handles long-running Slack API requests in a separate actor so that
    the request controller does not get blocked
  """
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  def ring(door_id) do
    GenServer.cast(@name, {:ring, door_id})
  end

  def handle_cast({:ring, door_id}, _) do
    door_info = @door_camera_map[String.to_integer(door_id)]

    {:ok, response} = HTTPoison.get "#{@camera_url}#{door_info.camera_id}"
    {:ok, image_path} = Briefly.create
    # FIXME: Briefly only cleans up on Briefly application exit. We are likely leaking
    # both files and memory (FDs, list of temp files in ets)
    File.write!(image_path, response.body)

    text = "Knock knock! Someone is at the #{door_info.name}"

    Logger.info "Alerting members to a doorbell at #{door_info.name}"

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
    {:noreply, nil}
  end
end
