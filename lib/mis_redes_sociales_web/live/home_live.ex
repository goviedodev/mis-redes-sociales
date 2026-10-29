defmodule MisRedesSocialesWeb.HomeLive do
  use MisRedesSocialesWeb, :live_view

  alias MisRedesSociales.Links
  alias MisRedesSociales.Links.Link

  @default_filters %{"category" => "", "subcategory" => "", "link_type" => ""}

  @impl true
  def mount(_params, _session, socket) do
    links = Links.list_links!()
    categories = Links.list_categories!() |> Enum.map(& &1.name)
    link_types = Links.list_link_types!() |> Enum.map(& &1.name)

    {:ok,
     socket
     |> assign(
       page_title: "Mis Redes Sociales",
       link_types: link_types,
       categories: categories,
       active_tab: "saved",
       filters: @default_filters,
       filter_form: to_form(@default_filters, as: :filter),
       editing_link_id: nil,
       edit_form: nil,
       deleting_link: nil,
       show_install_prompt: false
     )
     |> allow_upload(:artifact, accept: :any, max_entries: 1, max_file_size: 20_000_000)
     |> assign_new_form()
     |> stream(:links, links)}
  end

  @impl true
  def handle_event("pwa_install_ready", %{"ready" => ready}, socket) do
    {:noreply, assign(socket, show_install_prompt: ready)}
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) when tab in ["new", "saved"] do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  def handle_event("filter", %{"filter" => filter_params}, socket) do
    filters = Map.merge(@default_filters, filter_params)
    links = Links.list_links!(filters)

    {:noreply,
     socket
     |> assign(filters: filters, filter_form: to_form(filters, as: :filter))
     |> stream(:links, links, reset: true)}
  end

  def handle_event("clear_filters", _params, socket) do
    links = Links.list_links!(@default_filters)

    {:noreply,
     socket
     |> assign(filters: @default_filters, filter_form: to_form(@default_filters, as: :filter))
     |> stream(:links, links, reset: true)}
  end

  def handle_event("edit_link", %{"id" => id}, socket) do
    link = Links.get_link!(id)

    edit_form =
      link
      |> AshPhoenix.Form.for_update(:update, as: "edit_form")
      |> to_form()

    {:noreply,
     socket
     |> assign(editing_link_id: link.id, edit_form: edit_form)
     |> stream_insert(:links, link)}
  end

  def handle_event("cancel_edit", %{"id" => id}, socket) do
    link = Links.get_link!(id)

    {:noreply,
     socket
     |> assign(editing_link_id: nil, edit_form: nil)
     |> stream_insert(:links, link)}
  end

  def handle_event("save_edit", %{"edit_form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.edit_form.source, params: params) do
      {:ok, updated_link} ->
        links = Links.list_links!(socket.assigns.filters)

        {:noreply,
         socket
         |> assign(editing_link_id: nil, edit_form: nil)
         |> stream(:links, links, reset: true)
         |> stream_insert(:links, updated_link)}

      {:error, form} ->
        link = Links.get_link!(socket.assigns.editing_link_id)

        {:noreply,
         socket
         |> assign(:edit_form, to_form(form, as: "edit_form"))
         |> stream_insert(:links, link)}
    end
  end

  def handle_event("delete_link", %{"id" => id}, socket) do
    link = Links.get_link!(id)

    {:noreply, assign(socket, :deleting_link, link)}
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, :deleting_link, nil)}
  end

  def handle_event("confirm_delete", _params, socket) do
    link = socket.assigns.deleting_link
    :ok = Links.destroy_link!(link)

    {:noreply,
     socket
     |> assign(:deleting_link, nil)
     |> stream_delete(:links, link)}
  end

  def handle_event("validate", %{"form" => params}, socket) do
    form =
      AshPhoenix.Form.validate(socket.assigns.form.source, params)
      |> to_form(as: "form")

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form.source,
           params: params,
           before_submit: fn changeset ->
             if changeset.valid? do
               case consume_artifact(socket) do
                 {name, filename} ->
                   changeset
                   |> Ash.Changeset.force_change_attribute(:artifact_name, name)
                   |> Ash.Changeset.force_change_attribute(:artifact_path, filename)

                 nil ->
                   changeset
               end
             else
               changeset
             end
           end
         ) do
      {:ok, _link} ->
        links = Links.list_links!(socket.assigns.filters)

        {:noreply,
         socket
         |> stream(:links, links, reset: true)
         |> assign(:active_tab, "saved")
         |> assign_new_form()}

      {:error, form} ->
        {:noreply, assign(socket, :form, to_form(form, as: "form"))}
    end
  end

  defp consume_artifact(socket) do
    consume_uploaded_entries(socket, :artifact, fn %{path: path}, entry ->
      artifacts_dir = Application.get_env(:mis_redes_sociales, :artifacts_dir, "artifacts")
      File.mkdir_p!(artifacts_dir)
      safe_name = Path.basename(entry.client_name)
      filename = "#{System.unique_integer([:positive])}-#{safe_name}"
      dest = Path.join(artifacts_dir, filename)
      File.cp!(path, dest)
      {:ok, {safe_name, filename}}
    end)
    |> List.first()
  end

  defp assign_new_form(socket) do
    form =
      Link
      |> AshPhoenix.Form.for_create(:create, as: "form")
      |> to_form()

    assign(socket, :form, form)
  end
end
