defmodule MisRedesSociales.Links do
  use Ash.Domain,
    otp_app: :mis_redes_sociales

  alias MisRedesSociales.Links.LinkType

  resources do
    resource MisRedesSociales.Links.Link do
      define(:create_link, action: :create)
      define(:list_links, action: :list_recent)
      define(:get_link, action: :read, get_by: [:id])
      define(:update_link, action: :update)
      define(:destroy_link, action: :destroy)
    end

    resource MisRedesSociales.Links.Category do
      define(:create_category, action: :create)
      define(:list_categories, action: :list_alphabetical)
    end

    resource MisRedesSociales.Links.LinkType do
      define(:create_link_type, action: :create)
      define(:list_link_types_raw, action: :list_alphabetical)
      define(:get_link_type, action: :read, get_by: [:id])
      define(:update_link_type, action: :update)
      define(:destroy_link_type, action: :destroy)
    end
  end

  def list_link_types! do
    case list_link_types_raw!() do
      [] ->
        for name <- LinkType.default_names() do
          create_link_type!(%{name: name})
        end

        list_link_types_raw!()

      link_types ->
        link_types
    end
  end
end
