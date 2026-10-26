defmodule MisRedesSocialesWeb.AdminLiveTest do
  use MisRedesSocialesWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  defp unlocked_conn(conn) do
    Plug.Test.init_test_session(conn, %{pin_unlocked: true})
  end

  test "redirects unauthenticated user from /admin to /pin", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/pin"}}} = live(conn, ~p"/admin")
  end

  test "submitting a valid category name on /admin saves it and renders it in the categories list",
       %{conn: conn} do
    {:ok, view, _html} = live(unlocked_conn(conn), ~p"/admin")

    assert has_element?(view, "#category-form")
    assert has_element?(view, "a[href='/']")

    view
    |> form("#category-form", form: %{name: "IA"})
    |> render_submit()

    assert has_element?(view, "#categories", "IA")
    assert [%{name: "IA"}] = MisRedesSociales.Links.list_categories!()
  end

  test "submitting an empty or duplicate category name on /admin does not save and shows a Spanish validation error",
       %{conn: conn} do
    {:ok, _} = MisRedesSociales.Links.create_category(%{name: "IA"})

    {:ok, view, _html} = live(unlocked_conn(conn), ~p"/admin")

    empty_html =
      view
      |> form("#category-form", form: %{name: ""})
      |> render_submit()

    assert empty_html =~ "es obligatorio"

    dup_html =
      view
      |> form("#category-form", form: %{name: "IA"})
      |> render_submit()

    assert dup_html =~ "ya existe"
    assert [%{name: "IA"}] = MisRedesSociales.Links.list_categories!()
  end
end
