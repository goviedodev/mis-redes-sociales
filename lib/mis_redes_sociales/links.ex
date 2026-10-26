defmodule MisRedesSociales.Links do
  use Ash.Domain,
    otp_app: :mis_redes_sociales

  resources do
    resource MisRedesSociales.Links.Link do
      define(:create_link, action: :create)
      define(:list_links, action: :list_recent)
    end

    resource MisRedesSociales.Links.Category do
      define(:create_category, action: :create)
      define(:list_categories, action: :list_alphabetical)
    end
  end
end
