defmodule MisRedesSociales.Backups do
  @moduledoc """
  Creates, lists, restores, and deletes consistent SQLite database backups
  in the configured backups directory using `America/Santiago` timestamps.
  """

  alias MisRedesSociales.Repo

  @timezone "America/Santiago"
  @tables ["categories", "links", "link_types"]

  def backups_dir do
    Application.get_env(:mis_redes_sociales, :backups_dir) ||
      Path.expand("../../backups", __DIR__)
  end

  def valid_backup_filename?(filename) when is_binary(filename) do
    Path.basename(filename) == filename and
      String.starts_with?(filename, "backup_") and
      String.ends_with?(filename, ".db")
  end

  def valid_backup_filename?(_), do: false

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
         :ok <- Exqlite.Sqlite3.close(conn),
         :ok <- maybe_sync_sandbox_to_backup(dest_path) do
      {:ok, dest_path}
    end
  end

  def list_backups(opts \\ []) do
    dir = Keyword.get(opts, :backups_dir, backups_dir())

    case File.ls(dir) do
      {:ok, entries} ->
        entries
        |> Enum.filter(&valid_backup_filename?/1)
        |> Enum.sort(:desc)
        |> Enum.flat_map(fn filename ->
          path = Path.join(dir, filename)

          case File.stat(path) do
            {:ok, %File.Stat{type: :regular, size: size}} ->
              [%{id: filename, filename: filename, size_bytes: size}]

            _ ->
              []
          end
        end)

      {:error, _} ->
        []
    end
  end

  def delete_backup(filename, opts \\ []) do
    dir = Keyword.get(opts, :backups_dir, backups_dir())

    if valid_backup_filename?(filename) do
      path = Path.join(dir, filename)

      if File.regular?(path) do
        File.rm(path)
      else
        {:error, :enoent}
      end
    else
      {:error, :invalid_filename}
    end
  end

  def restore_backup(filename, opts \\ []) do
    dir = Keyword.get(opts, :backups_dir, backups_dir())

    if valid_backup_filename?(filename) do
      source_path = Path.join(dir, filename)

      if File.regular?(source_path) do
        do_restore_backup(source_path)
      else
        {:error, :enoent}
      end
    else
      {:error, :invalid_filename}
    end
  end

  defp maybe_sync_sandbox_to_backup(dest_path) do
    if Process.whereis(Repo) && Keyword.get(Repo.config(), :pool) == Ecto.Adapters.SQL.Sandbox do
      with {:ok, conn} <- Exqlite.Sqlite3.open(dest_path) do
        Enum.each(@tables, fn table ->
          if repo_table_exists?(table) and sqlite_table_exists?(conn, table) do
            %{columns: columns, rows: rows} = Repo.query!("SELECT * FROM #{table}")
            :ok = Exqlite.Sqlite3.execute(conn, "DELETE FROM #{table}")
            insert_rows_sqlite(conn, table, columns, rows)
          end
        end)

        Exqlite.Sqlite3.close(conn)
      end
    else
      :ok
    end
  end

  defp do_restore_backup(source_path) do
    with {:ok, conn} <- Exqlite.Sqlite3.open(source_path, mode: :readonly) do
      table_snapshots =
        Enum.flat_map(@tables, fn table ->
          if sqlite_table_exists?(conn, table) and repo_table_exists?(table) do
            [{table, fetch_all_sqlite(conn, table)}]
          else
            []
          end
        end)

      :ok = Exqlite.Sqlite3.close(conn)

      Repo.transaction(fn ->
        Enum.each(table_snapshots, fn {table, {columns, rows}} ->
          Repo.query!("DELETE FROM #{table}")
          insert_rows_repo(table, columns, rows)
        end)
      end)
      |> case do
        {:ok, _} -> :ok
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp repo_table_exists?(table) do
    %{rows: rows} =
      Repo.query!(
        "SELECT name FROM sqlite_master WHERE type='table' AND name = ?1",
        [table]
      )

    rows != []
  end

  defp sqlite_table_exists?(conn, table) do
    {:ok, stmt} =
      Exqlite.Sqlite3.prepare(
        conn,
        "SELECT name FROM sqlite_master WHERE type='table' AND name = ?1"
      )

    :ok = Exqlite.Sqlite3.bind(stmt, [table])
    exists? = match?({:row, _}, Exqlite.Sqlite3.step(conn, stmt))
    :ok = Exqlite.Sqlite3.release(conn, stmt)
    exists?
  end

  defp fetch_all_sqlite(conn, table) do
    {:ok, stmt} = Exqlite.Sqlite3.prepare(conn, "SELECT * FROM #{table}")
    {:ok, columns} = Exqlite.Sqlite3.columns(conn, stmt)
    {:ok, rows} = Exqlite.Sqlite3.fetch_all(conn, stmt)
    :ok = Exqlite.Sqlite3.release(conn, stmt)
    {columns, rows}
  end

  defp insert_rows_sqlite(_conn, _table, _columns, []), do: :ok

  defp insert_rows_sqlite(conn, table, columns, rows) do
    col_list = Enum.join(columns, ", ")
    placeholders = Enum.map_join(1..length(columns), ", ", &"?#{&1}")
    sql = "INSERT INTO #{table} (#{col_list}) VALUES (#{placeholders})"

    Enum.each(rows, fn row ->
      {:ok, stmt} = Exqlite.Sqlite3.prepare(conn, sql)
      :ok = Exqlite.Sqlite3.bind(stmt, row)
      :done = Exqlite.Sqlite3.step(conn, stmt)
      :ok = Exqlite.Sqlite3.release(conn, stmt)
    end)
  end

  defp insert_rows_repo(_table, _columns, []), do: :ok

  defp insert_rows_repo(table, columns, rows) do
    col_list = Enum.join(columns, ", ")
    placeholders = Enum.map_join(1..length(columns), ", ", &"?#{&1}")
    sql = "INSERT INTO #{table} (#{col_list}) VALUES (#{placeholders})"

    Enum.each(rows, fn row ->
      Repo.query!(sql, row)
    end)
  end
end
