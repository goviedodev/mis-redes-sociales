defmodule MisRedesSocialesWeb.PwaTest do
  use MisRedesSocialesWeb.ConnCase, async: true

  test "root layout includes PWA manifest link, theme-color meta, and apple-touch-icon", %{
    conn: conn
  } do
    conn = get(conn, ~p"/pin")
    html = html_response(conn, 200)

    assert html =~ ~s(rel="manifest")
    assert html =~ ~s(href="/manifest.webmanifest")
    assert html =~ ~s(name="theme-color")
    assert html =~ ~s(name="mobile-web-app-capable")
    assert html =~ ~s(rel="apple-touch-icon")
    assert html =~ ~s(href="/images/icon-192.png")

    root_source =
      File.read!("lib/mis_redes_sociales_web/components/layouts/root.html.heex")

    refute root_source =~ ~s(~p"/manifest.webmanifest")
    assert root_source =~ ~s(href="/manifest.webmanifest")

    endpoint_source = File.read!("lib/mis_redes_sociales_web/endpoint.ex")
    assert endpoint_source =~ "only_matching:"
  end

  test "serves a valid web app manifest at /manifest.webmanifest with standalone display and icons",
       %{conn: conn} do
    conn = get(conn, "/manifest.webmanifest")
    assert conn.status == 200

    manifest = Jason.decode!(conn.resp_body)
    assert manifest["id"] == "/"
    assert manifest["name"] == "Mis Redes Sociales"
    assert manifest["short_name"] == "Mis Redes"
    assert manifest["display"] == "standalone"
    assert manifest["start_url"] == "/"

    sizes = Enum.map(manifest["icons"], & &1["sizes"])
    assert "192x192" in sizes
    assert "512x512" in sizes

    purposes = Enum.map(manifest["icons"], & &1["purpose"])
    assert "any" in purposes
  end

  test "serves the service worker at /sw.js and app icons from static assets", %{conn: conn} do
    sw_conn = get(conn, "/sw.js")
    assert sw_conn.status == 200
    assert sw_conn.resp_body =~ "respondWith"

    icon192_conn = get(conn, "/images/icon-192.png")
    assert icon192_conn.status == 200

    icon512_conn = get(conn, "/images/icon-512.png")
    assert icon512_conn.status == 200
  end
end
