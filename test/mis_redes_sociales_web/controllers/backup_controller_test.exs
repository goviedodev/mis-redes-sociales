defmodule MisRedesSocialesWeb.BackupControllerTest do
  use MisRedesSocialesWeb.ConnCase, async: false

  alias MisRedesSociales.Backups

  defp unlocked_conn(conn) do
    Plug.Test.init_test_session(conn, %{pin_unlocked: true})
  end

  test "GET /backups/:filename downloads the SQLite backup file when authenticated and blocks unauthenticated or invalid requests",
       %{conn: conn} do
    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "mrs_backup_download_#{System.unique_integer([:positive])}"
      )

    previous_dir = Application.get_env(:mis_redes_sociales, :backups_dir)
    Application.put_env(:mis_redes_sociales, :backups_dir, tmp_dir)

    on_exit(fn ->
      if previous_dir do
        Application.put_env(:mis_redes_sociales, :backups_dir, previous_dir)
      else
        Application.delete_env(:mis_redes_sociales, :backups_dir)
      end

      File.rm_rf!(tmp_dir)
    end)

    {:ok, backup_path} =
      Backups.create_backup(backups_dir: tmp_dir, now: ~U[2026-10-27 04:00:00Z])

    filename = Path.basename(backup_path)

    # Unauthenticated request redirects to /pin
    unauth_conn = get(conn, "/backups/#{filename}")
    assert redirected_to(unauth_conn) == "/pin"

    # Authenticated request downloads the backup
    auth_conn = get(unlocked_conn(conn), "/backups/#{filename}")
    assert auth_conn.status == 200
    assert get_resp_header(auth_conn, "content-type") == ["application/vnd.sqlite3"]
    assert auth_conn.resp_body == File.read!(backup_path)

    # Non-backup or non-existent file returns 404
    File.write!(Path.join(tmp_dir, "secret.txt"), "nope")
    bad_conn = get(unlocked_conn(conn), "/backups/secret.txt")
    assert bad_conn.status == 404
  end
end
