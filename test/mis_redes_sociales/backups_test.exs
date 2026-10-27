defmodule MisRedesSociales.BackupsTest do
  use MisRedesSociales.DataCase, async: false

  alias MisRedesSociales.Backups
  alias MisRedesSociales.Links
  alias MisRedesSociales.Repo

  test "creates a valid SQLite backup file in the backups directory with the America/Santiago timestamp in its filename and preserves saved records" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "mrs_backups_test_#{System.unique_integer([:positive])}")

    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
      Repo.delete_all("links")
      Repo.delete_all("categories")

      {:ok, _category} = Links.create_category(%{name: "Respaldo Chile"})

      # 2026-10-27 04:00:00 UTC is 2026-10-27 01:00:00 in America/Santiago (UTC-3)
      now_utc = ~U[2026-10-27 04:00:00Z]

      assert {:ok, backup_path} =
               Backups.create_backup(backups_dir: tmp_dir, now: now_utc)

      assert Path.basename(backup_path) == "backup_2026-10-27_01-00-00.db"
      assert File.exists?(backup_path)

      {:ok, conn} = Exqlite.Sqlite3.open(backup_path)
      {:ok, stmt} = Exqlite.Sqlite3.prepare(conn, "SELECT name FROM categories")
      assert {:row, ["Respaldo Chile"]} = Exqlite.Sqlite3.step(conn, stmt)
      :ok = Exqlite.Sqlite3.release(conn, stmt)
      :ok = Exqlite.Sqlite3.close(conn)

      Repo.delete_all("categories")
    end)
  end

  test "lists backup files sorted from newest to oldest with filename and size, and returns empty list when directory has no backups" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "mrs_backups_list_#{System.unique_integer([:positive])}")

    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    assert Backups.list_backups(backups_dir: tmp_dir) == []

    {:ok, _older} =
      Backups.create_backup(backups_dir: tmp_dir, now: ~U[2026-10-26 04:00:00Z])

    {:ok, _newer} =
      Backups.create_backup(backups_dir: tmp_dir, now: ~U[2026-10-27 04:00:00Z])

    # Ignore unrelated files in the directory
    File.write!(Path.join(tmp_dir, "ignore.txt"), "not a db")

    assert [first, second] = Backups.list_backups(backups_dir: tmp_dir)
    assert first.filename == "backup_2026-10-27_01-00-00.db"
    assert first.id == "backup_2026-10-27_01-00-00.db"
    assert first.size_bytes > 0
    assert second.filename == "backup_2026-10-26_01-00-00.db"
    assert second.size_bytes > 0
  end
end
