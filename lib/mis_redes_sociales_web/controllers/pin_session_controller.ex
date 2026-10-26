defmodule MisRedesSocialesWeb.PinSessionController do
  use MisRedesSocialesWeb, :controller

  def create(conn, %{"token" => token}) do
    case Phoenix.Token.verify(MisRedesSocialesWeb.Endpoint, "pin_unlock", token, max_age: 60) do
      {:ok, :unlocked} ->
        conn
        |> put_session(:pin_unlocked, true)
        |> configure_session(renew: true)
        |> redirect(to: ~p"/")

      {:error, _reason} ->
        conn
        |> redirect(to: ~p"/pin")
    end
  end
end
