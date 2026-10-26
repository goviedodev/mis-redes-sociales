defmodule MisRedesSocialesWeb.PinAuth do
  @moduledoc """
  Plug and LiveView `on_mount` hook to require PIN authentication.
  """
  import Plug.Conn
  import Phoenix.Controller

  def require_authenticated_pin(conn, _opts) do
    if get_session(conn, :pin_unlocked) == true do
      conn
    else
      conn
      |> redirect(to: "/pin")
      |> halt()
    end
  end

  def on_mount(:ensure_unlocked, _params, session, socket) do
    if session["pin_unlocked"] == true do
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: "/pin")}
    end
  end
end
