defmodule Caffeine.Slack do
  require Logger
  use Slack

  def handle_connect(slack, state) do
    Logger.info "Connected to Slack as #{slack.me.name}"
    {:ok, state}
  end

  def handle_event(message = %{type: "message"}, slack, state) do
    send_message("I got a message!", message.channel, slack)
    {:ok, state}
  end
  def handle_event(event, _slack, state) do
    Logger.debug "Unhandled event: #{inspect event}"
    {:ok, state}
  end

  def handle_info({:message, text, channel}, slack, state) do
    Logger.debug "Sending message to channel #{channel}: #{text}"

    send_message(text, channel, slack)

    {:ok, state}
  end
  def handle_info(info, _slack, state) do
    Logger.debug "Unhandled info: #{inspect info}"
    {:ok, state}
  end
end
