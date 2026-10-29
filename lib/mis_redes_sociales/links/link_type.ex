defmodule MisRedesSociales.Links.LinkType do
  use Ash.Resource,
    otp_app: :mis_redes_sociales,
    domain: MisRedesSociales.Links,
    data_layer: AshSqlite.DataLayer

  import Ecto.Query

  alias MisRedesSociales.Repo

  @default_names ["Youtube", "Facebook", "Instagram", "TikTok"]

  def default_names, do: @default_names

  sqlite do
    table("link_types")
    repo(MisRedesSociales.Repo)
  end

  actions do
    defaults([:read])

    create :create do
      primary?(true)
      accept([:name])
    end

    update :update do
      primary?(true)
      require_atomic?(false)
      accept([:name])

      change(
        after_action(fn changeset, record, _context ->
          old_name = changeset.data.name
          new_name = record.name

          if old_name && new_name && old_name != new_name do
            now = DateTime.utc_now()

            from(l in "links", where: l.link_type == ^old_name)
            |> Repo.update_all(set: [link_type: new_name, updated_at: now])
          end

          {:ok, record}
        end)
      )
    end

    destroy :destroy do
      primary?(true)
      require_atomic?(false)

      validate(fn changeset, _context ->
        name = changeset.data.name

        if Repo.exists?(from(l in "links", where: l.link_type == ^name)) do
          {:error,
           field: :name,
           message: "No se puede eliminar porque está siendo usado por enlaces guardados"}
        else
          :ok
        end
      end)
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
