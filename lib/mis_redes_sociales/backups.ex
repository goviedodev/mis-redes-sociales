defmodule MisRedesSociales.Backups do
  @moduledoc """
  Creates consistent SQLite database backups in the configured backups directory
  using `America/Santiago` timestamps.
  """

  alias MisRedesSociales.Repo

  @timezone "America/Santiago"

  def backups_dir do
    Application.get_env(:mis_redes_sociales, :backups_dir) ||
      Path.expand("../../backups", __DIR__)
  end

  def create_backup(opts \\ []) do
    dir = Keyword.get(opts, :backups_dir, backups_dir())
    now_utc = Keyword.get(opts, :now, DateTime.utc_now())

    {:ok, santiago_dt} = DateTime.shift_zone(now_utc, @timezone)
    timestamp = Calendar.strftime(santiago_dt, "%Y-%m-%d_%H-%M-%S")
    filename = "backup_#{timestamp}.db"
    dest_path = Path.join(dir, filename)

    File.mkdir_p!(dir)
    _ = File.rm(dest_path)

    db_path = Keyword.fetch!(Repo.config(), :database)
    escaped_dest = String.replace(dest_path, "'", "''")

    with {:ok, conn} <- Exqlite.Sqlite3.open(db_path),
         :ok <- Exqlite.Sqlite3.execute(conn, "VACUUM INTO '#{escaped_dest}'"),
         :ok <- Exqlite.Sqlite3.close(conn) do
      {:ok, dest_path}
    end
  end
end
