defmodule MisRedesSocialesWeb.ArtifactController do
  use MisRedesSocialesWeb, :controller

  def show(conn, %{"filename" => filename}) do
    safe_filename = Path.basename(filename)
    artifacts_dir = Application.get_env(:mis_redes_sociales, :artifacts_dir, "artifacts")
    path = Path.join(artifacts_dir, safe_filename)

    if File.regular?(path) do
      conn
      |> put_resp_content_type(MIME.from_path(safe_filename))
      |> send_file(200, path)
    else
      send_resp(conn, 404, "Archivo no encontrado")
    end
  end
end
