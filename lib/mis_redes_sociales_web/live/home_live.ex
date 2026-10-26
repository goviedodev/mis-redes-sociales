defmodule MisRedesSocialesWeb.HomeLive do
  use MisRedesSocialesWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Mis Redes Sociales")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-4">
        <h1 class="text-2xl font-bold">Mis Redes Sociales</h1>
      </div>
    </Layouts.app>
    """
  end
end
