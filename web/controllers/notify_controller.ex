defmodule Caffeine.NotifyController do
  use Caffeine.Web, :controller
  require Logger

  def create(conn, params = %{"target" => target, "message" => message}) do
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
end
