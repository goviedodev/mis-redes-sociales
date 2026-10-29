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

    destroy :destroy do
      primary?(true)
      require_atomic?(false)

      change(
        after_action(fn _changeset, record, _context ->
          if record.artifact_path do
            artifacts_dir = Application.get_env(:mis_redes_sociales, :artifacts_dir, "artifacts")
            File.rm(Path.join(artifacts_dir, Path.basename(record.artifact_path)))
          end

          {:ok, record}
        end)
      )
    end

    create :create do
      primary?(true)

      accept([
        :category,
        :subcategory,
        :link_type,
        :url,
        :short_description,
        :long_description,
        :artifact_name,
        :artifact_path
      ])
    end

    update :update do
      primary?(true)
      require_atomic?(false)

      accept([
        :category,
        :subcategory,
        :link_type,
        :url,
        :short_description,
        :long_description
      ])
    end

    read :list_recent do
      argument(:category, :string, allow_nil?: true)
      argument(:subcategory, :string, allow_nil?: true)
      argument(:link_type, :string, allow_nil?: true)

      prepare(build(sort: [inserted_at: :desc]))

      prepare(fn query, _context ->
        require Ash.Query

        query
        |> filter_by_category(Ash.Query.get_argument(query, :category))
        |> filter_by_subcategory(Ash.Query.get_argument(query, :subcategory))
        |> filter_by_link_type(Ash.Query.get_argument(query, :link_type))
      end)
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

    attribute :artifact_name, :string do
      allow_nil?(true)
      public?(true)
    end

    attribute :artifact_path, :string do
      allow_nil?(true)
      public?(true)
    end

    timestamps(type: :utc_datetime_usec)
  end

  defp filter_by_category(query, val) when val in [nil, ""], do: query

  defp filter_by_category(query, val) do
    require Ash.Query
    Ash.Query.filter(query, category == ^val)
  end

  defp filter_by_subcategory(query, val) when val in [nil, ""], do: query

  defp filter_by_subcategory(query, val) do
    require Ash.Query
    pattern = "%#{String.downcase(String.trim(val))}%"
    Ash.Query.filter(query, fragment("lower(?) LIKE ?", subcategory, ^pattern))
  end

  defp filter_by_link_type(query, val) when val in [nil, ""], do: query

  defp filter_by_link_type(query, val) do
    require Ash.Query
    Ash.Query.filter(query, link_type == ^val)
  end
end
