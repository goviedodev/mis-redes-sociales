defmodule MisRedesSociales.Links.Category do
  use Ash.Resource,
    otp_app: :mis_redes_sociales,
    domain: MisRedesSociales.Links,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table("categories")
    repo(MisRedesSociales.Repo)
  end

  actions do
    defaults([:read])

    create :create do
      primary?(true)
      accept([:name])
    end

    read :list_alphabetical do
      prepare(build(sort: [name: :asc]))
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute :name, :string do
      allow_nil?(false)
      public?(true)
    end

    timestamps(type: :utc_datetime_usec)
  end

  identities do
    identity :unique_name, [:name] do
      message("ya existe")
    end
  end
end
