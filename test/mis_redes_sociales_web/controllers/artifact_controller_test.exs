defmodule MisRedesSocialesWeb.ArtifactControllerTest do
  use MisRedesSocialesWeb.ConnCase, async: false

  test "GET /artifacts/:filename serves the uploaded artifact when PIN is unlocked and redirects to /pin when locked",
       %{conn: conn} do
    File.mkdir_p!("artifacts")
    filename = "test-doc.pdf"
    stored_path = Path.join("artifacts", filename)
    File.write!(stored_path, "%PDF-1.4 test document")
    on_exit(fn -> File.rm(stored_path) end)

    locked_conn = get(conn, "/artifacts/#{filename}")
    assert redirected_to(locked_conn) == "/pin"

    unlocked_conn =
      conn
      |> Plug.Test.init_test_session(%{pin_unlocked: true})
      |> get("/artifacts/#{filename}")

    assert response(unlocked_conn, 200) == "%PDF-1.4 test document"
  end
end
