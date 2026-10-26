defmodule MisRedesSociales.Links.Link do
  use Ash.Resource,
    otp_app: :mis_redes_sociales,
    domain: MisRedesSociales.Links,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table("links")
    repo(MisRedesSociales.Repo)
  end

  actions do
    defaults([:read])

    create :create do
      primary?(true)
      accept([:category, :subcategory, :link_type, :url, :short_description, :long_description])
    end

    read :list_recent do
      prepare(build(sort: [inserted_at: :desc]))
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute :category, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :subcategory, :string do
      allow_nil?(true)
      public?(true)
    end

    attribute :link_type, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :url, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :short_description, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :long_description, :string do
      allow_nil?(true)
      public?(true)
    end

    timestamps(type: :utc_datetime_usec)
  end

  validations do
    validate(one_of(:link_type, ["Youtube", "Facebook", "Instagram", "TikTok"]))
  end
end
