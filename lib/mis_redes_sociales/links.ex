defmodule MisRedesSociales.Links do
  use Ash.Domain,
    otp_app: :mis_redes_sociales

  resources do
    resource MisRedesSociales.Links.Link do
      define(:create_link, action: :create)
      define(:list_links, action: :list_recent)
    end
  end
end
