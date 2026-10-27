defmodule MisRedesSocialesWeb.BackupController do
  use MisRedesSocialesWeb, :controller

  alias MisRedesSociales.Backups

  def show(conn, %{"filename" => filename}) do
    safe_filename = Path.basename(filename)

    if valid_backup_filename?(safe_filename) do
      path = Path.join(Backups.backups_dir(), safe_filename)

      if File.regular?(path) do
        conn
        |> put_resp_content_type("application/vnd.sqlite3", nil)
        |> put_resp_header(
          "content-disposition",
          ~s(attachment; filename="#{safe_filename}")
        )
        |> send_file(200, path)
      else
        send_resp(conn, 404, "Respaldo no encontrado")
      end
    else
      send_resp(conn, 404, "Respaldo no encontrado")
    end
  end

  defp valid_backup_filename?(name) do
    String.starts_with?(name, "backup_") and String.ends_with?(name, ".db")
  end
end
