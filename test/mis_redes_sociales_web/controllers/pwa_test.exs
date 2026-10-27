defmodule MisRedesSocialesWeb.PwaTest do
  use MisRedesSocialesWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "root layout includes literal /manifest.json link, theme-color meta, and apple-touch-icon",
       %{conn: conn} do
    conn = get(conn, ~p"/pin")
    html = html_response(conn, 200)

    assert html =~ ~s(rel="manifest")
    assert html =~ ~s(href="/manifest.json")
    assert html =~ ~s(name="theme-color")
    assert html =~ ~s(name="mobile-web-app-capable")
    assert html =~ ~s(name="apple-mobile-web-app-status-bar-style")
    assert html =~ ~s(rel="apple-touch-icon")
    assert html =~ ~s(href="/images/icon-192.png")

    root_source =
      File.read!("lib/mis_redes_sociales_web/components/layouts/root.html.heex")

    refute root_source =~ ~s(~p"/manifest.json")
    assert root_source =~ ~s(href="/manifest.json")

    endpoint_source = File.read!("lib/mis_redes_sociales_web/endpoint.ex")
    assert endpoint_source =~ "only_matching:"
  end

  test "serves a valid web app manifest at /manifest.json with standalone display and icons",
       %{conn: conn} do
    conn = get(conn, "/manifest.json")
    assert conn.status == 200

    manifest = Jason.decode!(conn.resp_body)
    assert manifest["id"] == "/?source=pwa"
    assert manifest["name"] == "Mis Redes Sociales"
    assert manifest["short_name"] == "Mis Redes"
    assert manifest["display"] == "standalone"
    assert manifest["start_url"] == "/"

    sizes = Enum.map(manifest["icons"], & &1["sizes"])
    assert "192x192" in sizes
    assert "512x512" in sizes

    purposes = Enum.map(manifest["icons"], & &1["purpose"])
    assert "any" in purposes
    assert "maskable" in purposes
  end

  test "serves /service-worker.js with LiveView-safe Network-First HTML strategy and static icons",
       %{conn: conn} do
    sw_conn = get(conn, "/service-worker.js")
    assert sw_conn.status == 200
    assert sw_conn.resp_body =~ ~s[event.request.url.includes("/live")]
    assert sw_conn.resp_body =~ ~s[event.request.mode === "navigate"]
    assert sw_conn.resp_body =~ "respondWith"

    icon192_conn = get(conn, "/images/icon-192.png")
    assert icon192_conn.status == 200

    icon512_conn = get(conn, "/images/icon-512.png")
    assert icon512_conn.status == 200
  end

  test "PinLive mounts PWAInstall hook and renders PWAInstallBtn when pwa_install_ready fires",
       %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/pin")

    assert has_element?(view, "#pin-pwa-container[phx-hook='PWAInstall']")
    refute has_element?(view, "#pwa-install-btn")

    render_hook(view, "pwa_install_ready", %{"ready" => true})
    assert has_element?(view, "#pwa-install-btn[phx-hook='PWAInstallBtn']", "Instalar App")

    render_hook(view, "pwa_install_ready", %{"ready" => false})
    refute has_element?(view, "#pwa-install-btn")
  end
end
