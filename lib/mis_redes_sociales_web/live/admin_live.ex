defmodule MisRedesSocialesWeb.AdminLive do
  use MisRedesSocialesWeb, :live_view

  alias MisRedesSociales.Backups
  alias MisRedesSociales.Links
  alias MisRedesSociales.Links.Category
  alias MisRedesSociales.Links.LinkType

  @impl true
  def mount(_params, _session, socket) do
    categories = Links.list_categories!()
    link_types = Links.list_link_types!()
    backups = Backups.list_backups()

    {:ok,
     socket
     |> assign(
       page_title: "Administración",
       editing_link_type_id: nil,
       edit_link_type_form: nil,
       deleting_link_type: nil,
       deleting_backup_filename: nil,
       restoring_backup_filename: nil
     )
     |> assign_new_form()
     |> assign_new_link_type_form()
     |> stream(:categories, categories)
     |> stream(:link_types, link_types)
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

  def handle_event("validate_link_type", %{"link_type_form" => params}, socket) do
    form =
      AshPhoenix.Form.validate(socket.assigns.link_type_form.source, params)
      |> to_form(as: "link_type_form")

    {:noreply, assign(socket, :link_type_form, form)}
  end

  def handle_event("save_link_type", %{"link_type_form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.link_type_form.source, params: params) do
      {:ok, _link_type} ->
        link_types = Links.list_link_types!()

        {:noreply,
         socket
         |> stream(:link_types, link_types, reset: true)
         |> assign_new_link_type_form()}

      {:error, form} ->
        {:noreply, assign(socket, :link_type_form, to_form(form, as: "link_type_form"))}
    end
  end

  def handle_event("edit_link_type", %{"id" => id}, socket) do
    link_type = Links.get_link_type!(id)

    edit_form =
      link_type
      |> AshPhoenix.Form.for_update(:update, as: "edit_link_type_form")
      |> to_form()

    {:noreply,
     socket
     |> assign(editing_link_type_id: link_type.id, edit_link_type_form: edit_form)
     |> stream_insert(:link_types, link_type)}
  end

  def handle_event("cancel_link_type_edit", %{"id" => id}, socket) do
    link_type = Links.get_link_type!(id)

    {:noreply,
     socket
     |> assign(editing_link_type_id: nil, edit_link_type_form: nil)
     |> stream_insert(:link_types, link_type)}
  end

  def handle_event("save_link_type_edit", %{"edit_link_type_form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.edit_link_type_form.source, params: params) do
      {:ok, _updated_link_type} ->
        link_types = Links.list_link_types!()

        {:noreply,
         socket
         |> assign(editing_link_type_id: nil, edit_link_type_form: nil)
         |> stream(:link_types, link_types, reset: true)}

      {:error, form} ->
        link_type = Links.get_link_type!(socket.assigns.editing_link_type_id)

        {:noreply,
         socket
         |> assign(:edit_link_type_form, to_form(form, as: "edit_link_type_form"))
         |> stream_insert(:link_types, link_type)}
    end
  end

  def handle_event("delete_link_type", %{"id" => id}, socket) do
    link_type = Links.get_link_type!(id)
    {:noreply, assign(socket, :deleting_link_type, link_type)}
  end

  def handle_event("cancel_delete_link_type", _params, socket) do
    {:noreply, assign(socket, :deleting_link_type, nil)}
  end

  def handle_event("confirm_delete_link_type", _params, socket) do
    link_type = socket.assigns.deleting_link_type

    case Links.destroy_link_type(link_type) do
      :ok ->
        {:noreply,
         socket
         |> assign(:deleting_link_type, nil)
         |> stream_delete(:link_types, link_type)}

      {:error, _error} ->
        {:noreply,
         socket
         |> assign(:deleting_link_type, nil)
         |> put_flash(
           :error,
           "No se puede eliminar el tipo de enlace «#{link_type.name}» porque está siendo usado por enlaces guardados"
         )}
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

  def handle_event("delete_backup", %{"filename" => filename}, socket) do
    {:noreply, assign(socket, :deleting_backup_filename, filename)}
  end

  def handle_event("cancel_delete_backup", _params, socket) do
    {:noreply, assign(socket, :deleting_backup_filename, nil)}
  end

  def handle_event("confirm_delete_backup", _params, socket) do
    filename = socket.assigns.deleting_backup_filename

    case Backups.delete_backup(filename) do
      :ok ->
        backups = Backups.list_backups()

        {:noreply,
         socket
         |> assign(:deleting_backup_filename, nil)
         |> stream(:backups, backups, reset: true)
         |> put_flash(:info, "Respaldo eliminado correctamente (#{filename})")}

      {:error, _reason} ->
        {:noreply,
         socket
         |> assign(:deleting_backup_filename, nil)
         |> put_flash(:error, "No se pudo eliminar el respaldo")}
    end
  end

  def handle_event("restore_backup", %{"filename" => filename}, socket) do
    {:noreply, assign(socket, :restoring_backup_filename, filename)}
  end

  def handle_event("cancel_restore_backup", _params, socket) do
    {:noreply, assign(socket, :restoring_backup_filename, nil)}
  end

  def handle_event("confirm_restore_backup", _params, socket) do
    filename = socket.assigns.restoring_backup_filename

    case Backups.restore_backup(filename) do
      :ok ->
        categories = Links.list_categories!()
        link_types = Links.list_link_types!()

        {:noreply,
         socket
         |> assign(:restoring_backup_filename, nil)
         |> stream(:categories, categories, reset: true)
         |> stream(:link_types, link_types, reset: true)
         |> put_flash(:info, "Respaldo restaurado correctamente (#{filename})")}

      {:error, _reason} ->
        {:noreply,
         socket
         |> assign(:restoring_backup_filename, nil)
         |> put_flash(:error, "No se pudo restaurar el respaldo")}
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

  defp assign_new_link_type_form(socket) do
    form =
      LinkType
      |> AshPhoenix.Form.for_create(:create, as: "link_type_form")
      |> to_form()

    assign(socket, :link_type_form, form)
  end
end
