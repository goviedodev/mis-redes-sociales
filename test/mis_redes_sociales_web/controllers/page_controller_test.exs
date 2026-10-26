defmodule MisRedesSocialesWeb.PageControllerTest do
  use MisRedesSocialesWeb.ConnCase

  test "GET / redirects unauthenticated user to /pin", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/pin"
  end
end
