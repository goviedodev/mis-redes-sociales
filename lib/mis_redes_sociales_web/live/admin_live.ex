defmodule MisRedesSocialesWeb.AdminLive do
  use MisRedesSocialesWeb, :live_view

  alias MisRedesSociales.Backups
  alias MisRedesSociales.Links
  alias MisRedesSociales.Links.Category

  @impl true
  def mount(_params, _session, socket) do
    categories = Links.list_categories!()
    backups = Backups.list_backups()

    {:ok,
     socket
     |> assign(page_title: "Administración")
     |> assign_new_form()
     |> stream(:categories, categories)
     |> stream(:backups, backups)}
  end

  @impl true
  def handle_event("validate", %{"form" => params}, socket) do
    form =
      AshPhoenix.Form.validate(socket.assigns.form.source, params)
      |> to_form(as: "form")

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form.source, params: params) do
      {:ok, _category} ->
        categories = Links.list_categories!()

        {:noreply,
         socket
         |> stream(:categories, categories, reset: true)
         |> assign_new_form()}

      {:error, form} ->
        {:noreply, assign(socket, :form, to_form(form, as: "form"))}
    end
  end

  def handle_event("create_backup", _params, socket) do
    case Backups.create_backup() do
      {:ok, backup_path} ->
        backups = Backups.list_backups()

        {:noreply,
         socket
         |> stream(:backups, backups, reset: true)
         |> put_flash(
           :info,
           "Respaldo creado correctamente (#{Path.basename(backup_path)})"
         )}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "No se pudo crear el respaldo")}
    end
  end

  def format_size(bytes) when is_integer(bytes) do
    "#{Float.round(bytes / 1024, 1)} KB"
  end

  defp assign_new_form(socket) do
    form =
      Category
      |> AshPhoenix.Form.for_create(:create, as: "form")
      |> to_form()

    assign(socket, :form, form)
  end
end
