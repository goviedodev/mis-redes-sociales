defmodule MisRedesSocialesWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use MisRedesSocialesWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="navbar px-4 sm:px-6 lg:px-8 border-b border-base-300 bg-base-100">
      <div class="flex-1">
        <a
          href="/"
          class="flex w-fit items-center gap-2 text-base-content hover:opacity-80 transition-opacity"
        >
          <span class="text-base font-bold tracking-tight">Mis Redes Sociales</span>
        </a>
      </div>
      <div class="flex-none">
        <.theme_toggle />
      </div>
    </header>

    <main class="px-4 py-12 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides light, dark, and sepia theme selector based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div
      id="theme-selector"
      role="group"
      aria-label="Selector de tema"
      class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full"
    >
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-0 [[data-theme=dark]_&]:left-1/3 [[data-theme=sepia]_&]:left-2/3 transition-[left]" />

      <button
        id="theme-btn-light"
        type="button"
        aria-label="Claro"
        class="relative z-10 flex items-center justify-center gap-1 px-2.5 py-1.5 cursor-pointer w-1/3 text-xs font-medium opacity-75 hover:opacity-100 [[data-theme=light]_&]:opacity-100"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4" />
        <span class="sr-only sm:not-sr-only">Claro</span>
      </button>

      <button
        id="theme-btn-dark"
        type="button"
        aria-label="Oscuro"
        class="relative z-10 flex items-center justify-center gap-1 px-2.5 py-1.5 cursor-pointer w-1/3 text-xs font-medium opacity-75 hover:opacity-100 [[data-theme=dark]_&]:opacity-100"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4" />
        <span class="sr-only sm:not-sr-only">Oscuro</span>
      </button>

      <button
        id="theme-btn-sepia"
        type="button"
        aria-label="Sepia"
        class="relative z-10 flex items-center justify-center gap-1 px-2.5 py-1.5 cursor-pointer w-1/3 text-xs font-medium opacity-75 hover:opacity-100 [[data-theme=sepia]_&]:opacity-100"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="sepia"
      >
        <.icon name="hero-book-open-micro" class="size-4" />
        <span class="sr-only sm:not-sr-only">Sepia</span>
      </button>
    </div>
    """
  end
end
