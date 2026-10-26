defmodule MisRedesSocialesWeb.PinLive do
  use MisRedesSocialesWeb, :live_view

  @valid_pin ["8", "7", "5", "1"]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Ingresa tu PIN", digits: [], error: nil)}
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

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="mx-auto max-w-xs py-8 flex flex-col items-center gap-6">
        <div class="text-center space-y-1">
          <h1 class="text-2xl font-bold">Ingresa tu PIN</h1>
          <p class="text-sm opacity-70">Marca los 4 dígitos para desbloquear</p>
        </div>

        <div id="pin-display" class="flex gap-4 my-2">
          <%= for idx <- 0..3 do %>
            <div
              id={"pin-dot-#{idx}"}
              data-filled={to_string(idx < length(@digits))}
              class={[
                "w-4 h-4 rounded-full border-2 border-primary transition-all",
                if(idx < length(@digits), do: "bg-primary scale-110", else: "bg-transparent")
              ]}
            />
          <% end %>
        </div>

        <%= if @error do %>
          <p id="pin-error" class="text-error text-sm font-medium">{@error}</p>
        <% end %>

        <div class="grid grid-cols-3 gap-4 w-full">
          <%= for digit <- [1, 2, 3, 4, 5, 6, 7, 8, 9] do %>
            <button
              id={"pin-key-#{digit}"}
              type="button"
              phx-click="digit"
              phx-value-digit={digit}
              class="btn btn-lg btn-circle btn-outline text-xl font-semibold mx-auto"
            >
              {digit}
            </button>
          <% end %>
          <div />
          <button
            id="pin-key-0"
            type="button"
            phx-click="digit"
            phx-value-digit="0"
            class="btn btn-lg btn-circle btn-outline text-xl font-semibold mx-auto"
          >
            0
          </button>
          <button
            id="pin-clear"
            type="button"
            phx-click="clear"
            class="btn btn-lg btn-ghost text-sm font-medium mx-auto"
          >
            Borrar
          </button>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
