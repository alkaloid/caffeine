defmodule Caffeine.DoorBell do
  require Logger

  use GenServer
  
  @name :door_bell
  @slack_file_url "https://slack.com/api/files.upload" 
  @slack_channels Application.get_env(:caffeine, :doorbell_notifies) # comma separated
  @camera_url "http://localhost:7080/api/2.0/snapshot/camera/"
  @unifi_nvr_api_key Application.get_env(:caffeine, :unifi_nvr_api_key)
  @door_camera_map %{
    1 => %{name: "Central - Front Door", camera_id: 5},
    2 => %{name: "Central - Side Door", camera_id: "58e79fa2e01219fe05bd1ea0"},
    3 => %{name: "West Wing - Front Door", camera_id: "58e79fa2e01219fe05bd1ea0"},
    4 => %{name: "Central - Back Door", camera_id: 3},
  }
  @missing_camera_image "attachments/missing_camera.png"

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

    case HTTPoison.get "#{@camera_url}#{door_info.camera_id}?apiKey=#{@unifi_nvr_api_key}" do
      {:ok, response} ->
        # FIXME: Briefly only cleans up on Briefly application exit. We are likely leaking
        # both files and memory (FDs, list of temp files in ets)
        {:ok, image_path} = Briefly.create
        File.write!(image_path, response.body)
      {:error, error} ->
        Logger.error "Unable to fetch camera image for door #{door_info.name}: #{inspect error.reason}"
        image_path = "#{Application.app_dir(:caffeine, "priv")}/#{@missing_camera_image}"
    end

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
