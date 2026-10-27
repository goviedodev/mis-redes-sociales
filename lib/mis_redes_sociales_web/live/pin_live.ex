defmodule MisRedesSocialesWeb.PinLive do
  use MisRedesSocialesWeb, :live_view

  @valid_pin ["8", "7", "5", "1"]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Ingresa tu PIN",
       digits: [],
       error: nil,
       show_install_prompt: false
     )}
  end

  @impl true
  def handle_event("pwa_install_ready", %{"ready" => ready}, socket) do
    {:noreply, assign(socket, show_install_prompt: ready)}
  end

  @impl true
  def handle_event("digit", %{"digit" => digit}, socket) do
    digits = socket.assigns.digits ++ [digit]

    cond do
      digits == @valid_pin ->
        token = Phoenix.Token.sign(MisRedesSocialesWeb.Endpoint, "pin_unlock", :unlocked)
        {:noreply, redirect(socket, to: ~p"/pin/session?token=#{token}")}

      length(digits) == 4 ->
        {:noreply, assign(socket, digits: [], error: "PIN incorrecto")}

      true ->
        {:noreply, assign(socket, digits: digits, error: nil)}
    end
  end

  @impl true
  def handle_event("clear", _params, socket) do
    {:noreply, assign(socket, digits: Enum.drop(socket.assigns.digits, -1), error: nil)}
  end
end
