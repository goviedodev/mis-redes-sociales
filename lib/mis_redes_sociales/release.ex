defmodule MisRedesSociales.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :mis_redes_sociales

  def migrate do
    load_app()

    for repo <- repos() do
      ensure_sqlite_dir(repo)
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end

    :ok
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp ensure_sqlite_dir(repo) do
    case Keyword.get(repo.config(), :database) do
      db_path when is_binary(db_path) ->
        db_path
        |> Path.dirname()
        |> File.mkdir_p!()

      _ ->
        :ok
    end
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.ensure_all_started(:ssl)
    Application.load(@app)
  end
end
