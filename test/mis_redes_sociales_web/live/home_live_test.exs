defmodule MisRedesSocialesWeb.HomeLiveTest do
  use MisRedesSocialesWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  defp unlocked_conn(conn) do
    Plug.Test.init_test_session(conn, %{pin_unlocked: true})
  end

  test "submitting the Spanish link form with valid category, link type, URL, and short description saves the link and renders it in the saved links stream",
       %{conn: conn} do
    {:ok, view, _html} = live(unlocked_conn(conn), ~p"/")

    assert has_element?(view, "#link-form")

    view
    |> form("#link-form",
      form: %{
        category: "IA",
        link_type: "Youtube",
        url: "https://www.youtube.com/shorts/KigUHSCgDNo",
        short_description: "AI Creator Studio"
      }
    )
    |> render_submit()

    assert has_element?(view, "#links", "AI Creator Studio")
    assert has_element?(view, "#links", "IA")
    assert has_element?(view, "#links", "Youtube")
    assert has_element?(view, "#links a[href='https://www.youtube.com/shorts/KigUHSCgDNo']")
  end

  test "reloading the main screen lists previously saved links in newest-first order",
       %{conn: conn} do
    {:ok, first} =
      MisRedesSociales.Links.create_link(%{
        category: "IA",
        link_type: "Youtube",
        url: "https://www.youtube.com/watch?v=111",
        short_description: "Primer Enlace"
      })

    {:ok, second} =
      MisRedesSociales.Links.create_link(%{
        category: "Diseño",
        link_type: "Instagram",
        url: "https://www.instagram.com/p/222",
        short_description: "Segundo Enlace"
      })

    {:ok, _view, html} = live(unlocked_conn(conn), ~p"/")

    {second_pos, _} = :binary.match(html, "links-#{second.id}")
    {first_pos, _} = :binary.match(html, "links-#{first.id}")
    assert second_pos < first_pos
  end

  test "submitting the link form with missing required fields does not save the link and displays validation errors",
       %{conn: conn} do
    {:ok, view, _html} = live(unlocked_conn(conn), ~p"/")

    html =
      view
      |> form("#link-form",
        form: %{
          category: "",
          link_type: "",
          url: "",
          short_description: ""
        }
      )
      |> render_submit()

    assert html =~ "es obligatorio"
    assert MisRedesSociales.Links.list_links!() == []
  end
end
