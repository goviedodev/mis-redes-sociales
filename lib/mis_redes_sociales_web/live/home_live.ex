defmodule MisRedesSocialesWeb.HomeLive do
  use MisRedesSocialesWeb, :live_view

  alias MisRedesSociales.Links
  alias MisRedesSociales.Links.Link

  @link_types ["Youtube", "Facebook", "Instagram", "TikTok"]

  @default_filters %{"category" => "", "subcategory" => "", "link_type" => ""}

  @impl true
  def mount(_params, _session, socket) do
    links = Links.list_links!()
    categories = Links.list_categories!() |> Enum.map(& &1.name)

    {:ok,
     socket
     |> assign(
       page_title: "Mis Redes Sociales",
       link_types: @link_types,
       categories: categories,
       active_tab: "new",
       filters: @default_filters,
       filter_form: to_form(@default_filters, as: :filter)
     )
     |> allow_upload(:artifact, accept: :any, max_entries: 1, max_file_size: 20_000_000)
     |> assign_new_form()
     |> stream(:links, links)}
  end

  @impl true
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
