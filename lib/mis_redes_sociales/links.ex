defmodule MisRedesSociales.Links do
  use Ash.Domain,
    otp_app: :mis_redes_sociales

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
  end
end
