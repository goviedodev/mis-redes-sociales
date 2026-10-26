defmodule MisRedesSocialesWeb.PinLiveTest do
  use MisRedesSocialesWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "redirects unauthenticated user visiting \"/\" to \"/pin\" and renders the Spanish phone keypad (digits 0-9 and Borrar button)",
       %{conn: conn} do
    assert {:error, {:redirect, %{to: "/pin"}}} = live(conn, ~p"/")

    {:ok, view, html} = live(conn, ~p"/pin")
    assert html =~ "Ingresa tu PIN"

    for digit <- 0..9 do
      assert has_element?(view, "#pin-key-#{digit}", Integer.to_string(digit))
    end

    assert has_element?(view, "#pin-clear", "Borrar")
  end

  test "entering an incorrect 4-digit PIN (\"1234\") via keypad clicks shows \"PIN incorrecto\", clears the digits, and stays on \"/pin\"",
       %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/pin")

    view |> element("#pin-key-1") |> render_click()
    view |> element("#pin-key-2") |> render_click()
    view |> element("#pin-key-3") |> render_click()
    view |> element("#pin-key-4") |> render_click()

    assert has_element?(view, "#pin-error", "PIN incorrecto")
    assert has_element?(view, "#pin-dot-0[data-filled='false']")
  end

  test "clicking \"Borrar\" removes the last clicked digit before completing 4 digits",
       %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/pin")

    view |> element("#pin-key-8") |> render_click()
    view |> element("#pin-key-7") |> render_click()

    assert has_element?(view, "#pin-dot-0[data-filled='true']")
    assert has_element?(view, "#pin-dot-1[data-filled='true']")

    view |> element("#pin-clear") |> render_click()

    assert has_element?(view, "#pin-dot-0[data-filled='true']")
    assert has_element?(view, "#pin-dot-1[data-filled='false']")
  end

  test "entering the valid 4-digit PIN (\"8751\") via keypad clicks unlocks the session and redirects to \"/\" showing the Spanish main screen",
       %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/pin")

    view |> element("#pin-key-8") |> render_click()
    view |> element("#pin-key-7") |> render_click()
    view |> element("#pin-key-5") |> render_click()

    assert {:error, {:redirect, %{to: "/pin/session?token=" <> _} = redirect_info}} =
             view |> element("#pin-key-1") |> render_click()

    conn = get(conn, redirect_info.to)
    assert redirected_to(conn) == ~p"/"

    {:ok, _home_view, home_html} = live(recycle(conn), ~p"/")
    assert home_html =~ "Mis Redes Sociales"
  end
end
