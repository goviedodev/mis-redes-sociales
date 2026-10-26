defmodule MisRedesSocialesWeb.HomeLiveTest do
  use MisRedesSocialesWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  defp unlocked_conn(conn) do
    Plug.Test.init_test_session(conn, %{pin_unlocked: true})
  end

  test "submitting the Spanish link form with valid category, link type, URL, and short description saves the link and renders it in the saved links stream",
       %{conn: conn} do
    {:ok, _} = MisRedesSociales.Links.create_category(%{name: "IA"})
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

  test "populates the category select dropdown on the home link form with created categories",
       %{conn: conn} do
    {:ok, _} = MisRedesSociales.Links.create_category(%{name: "Diseño"})
    {:ok, _} = MisRedesSociales.Links.create_category(%{name: "IA"})

    {:ok, view, _html} = live(unlocked_conn(conn), ~p"/")

    assert has_element?(view, "#link-form select[name='form[category]'] option[value='Diseño']")
    assert has_element?(view, "#link-form select[name='form[category]'] option[value='IA']")
    assert has_element?(view, "a[href='/admin']")
  end

  test "submitting the link form with optional subcategory and long description displays them on the saved link card",
       %{conn: conn} do
    {:ok, _} = MisRedesSociales.Links.create_category(%{name: "IA"})
    {:ok, view, _html} = live(unlocked_conn(conn), ~p"/")

    view
    |> form("#link-form",
      form: %{
        category: "IA",
        subcategory: "OCR",
        link_type: "Youtube",
        url: "https://www.youtube.com/shorts/KigUHSCgDNo",
        short_description: "AI Creator Studio",
        long_description: "Es un video corto con todos los pasos"
      }
    )
    |> render_submit()

    assert has_element?(view, "#links [data-role='subcategory']", "OCR")

    assert has_element?(
             view,
             "#links [data-role='long-description']",
             "Es un video corto con todos los pasos"
           )
  end

  test "submitting the link form without subcategory or long description omits empty subcategory and long description elements on the card",
       %{conn: conn} do
    {:ok, _} = MisRedesSociales.Links.create_category(%{name: "IA"})
    {:ok, view, _html} = live(unlocked_conn(conn), ~p"/")

    view
    |> form("#link-form",
      form: %{
        category: "IA",
        subcategory: "",
        link_type: "Youtube",
        url: "https://www.youtube.com/shorts/KigUHSCgDNo",
        short_description: "AI Creator Studio",
        long_description: ""
      }
    )
    |> render_submit()

    assert has_element?(view, "#links", "AI Creator Studio")
    refute has_element?(view, "#links [data-role='subcategory']")
    refute has_element?(view, "#links [data-role='long-description']")
  end

  test "uploading an optional artifact file when saving a link stores the file in artifacts/ and displays the download link with its filename on the card",
       %{conn: conn} do
    {:ok, _} = MisRedesSociales.Links.create_category(%{name: "IA"})
    {:ok, view, _html} = live(unlocked_conn(conn), ~p"/")

    artifact =
      file_input(view, "#link-form", :artifact, [
        %{
          name: "guia-ocr.pdf",
          content: "%PDF-1.4 sample content",
          type: "application/pdf"
        }
      ])

    assert render_upload(artifact, "guia-ocr.pdf") =~ "guia-ocr.pdf"

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

    [saved_link] = MisRedesSociales.Links.list_links!()
    stored_file = Path.join("artifacts", saved_link.artifact_path)
    on_exit(fn -> File.rm(stored_file) end)

    assert saved_link.artifact_name == "guia-ocr.pdf"
    assert File.read!(stored_file) == "%PDF-1.4 sample content"

    assert has_element?(
             view,
             "#links a[data-role='artifact-link'][href='/artifacts/#{saved_link.artifact_path}']",
             "guia-ocr.pdf"
           )
  end

  test "submitting the link form without an artifact file omits the artifact link on the card",
       %{conn: conn} do
    {:ok, _} = MisRedesSociales.Links.create_category(%{name: "IA"})
    {:ok, view, _html} = live(unlocked_conn(conn), ~p"/")

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
    refute has_element?(view, "#links [data-role='artifact-link']")
  end

  test "renders Nuevo Enlace and Enlaces Guardados tabs with Nuevo Enlace active by default and Enlaces Guardados panel hidden",
       %{conn: conn} do
    {:ok, view, _html} = live(unlocked_conn(conn), ~p"/")

    assert has_element?(view, "#tab-new.tab-active", "Nuevo Enlace")
    assert has_element?(view, "#tab-saved:not(.tab-active)", "Enlaces Guardados")
    assert has_element?(view, "#new-link-panel:not(.hidden)")
    assert has_element?(view, "#saved-links-panel.hidden")
  end

  test "clicking Enlaces Guardados and Nuevo Enlace tabs switches the visible panel",
       %{conn: conn} do
    {:ok, view, _html} = live(unlocked_conn(conn), ~p"/")

    view |> element("#tab-saved") |> render_click()

    assert has_element?(view, "#tab-saved.tab-active", "Enlaces Guardados")
    assert has_element?(view, "#tab-new:not(.tab-active)", "Nuevo Enlace")
    assert has_element?(view, "#saved-links-panel:not(.hidden)")
    assert has_element?(view, "#new-link-panel.hidden")

    view |> element("#tab-new") |> render_click()

    assert has_element?(view, "#tab-new.tab-active", "Nuevo Enlace")
    assert has_element?(view, "#new-link-panel:not(.hidden)")
    assert has_element?(view, "#saved-links-panel.hidden")
  end

  test "saving a valid link automatically switches the active tab to Enlaces Guardados",
       %{conn: conn} do
    {:ok, _} = MisRedesSociales.Links.create_category(%{name: "IA"})
    {:ok, view, _html} = live(unlocked_conn(conn), ~p"/")

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

    assert has_element?(view, "#tab-saved.tab-active", "Enlaces Guardados")
    assert has_element?(view, "#saved-links-panel:not(.hidden)")
    assert has_element?(view, "#new-link-panel.hidden")
    assert has_element?(view, "#links", "AI Creator Studio")
  end

  test "filtering saved links by category, subcategory, or link type in the Enlaces Guardados tab displays only matching links",
       %{conn: conn} do
    {:ok, _} = MisRedesSociales.Links.create_category(%{name: "IA"})
    {:ok, _} = MisRedesSociales.Links.create_category(%{name: "Diseño"})

    {:ok, _} =
      MisRedesSociales.Links.create_link(%{
        category: "IA",
        subcategory: "OCR",
        link_type: "Youtube",
        url: "https://www.youtube.com/watch?v=1",
        short_description: "Video de OCR"
      })

    {:ok, _} =
      MisRedesSociales.Links.create_link(%{
        category: "IA",
        subcategory: "Agentes",
        link_type: "TikTok",
        url: "https://www.tiktok.com/@user/video/2",
        short_description: "TikTok de Agentes"
      })

    {:ok, _} =
      MisRedesSociales.Links.create_link(%{
        category: "Diseño",
        subcategory: "UI",
        link_type: "Instagram",
        url: "https://www.instagram.com/p/3",
        short_description: "Post de Diseño UI"
      })

    {:ok, view, _html} = live(unlocked_conn(conn), ~p"/")

    view
    |> form("#filter-form", filter: %{category: "IA", subcategory: "", link_type: ""})
    |> render_change()

    assert has_element?(view, "#links", "Video de OCR")
    assert has_element?(view, "#links", "TikTok de Agentes")
    refute has_element?(view, "#links", "Post de Diseño UI")

    view
    |> form("#filter-form", filter: %{category: "IA", subcategory: "ocr", link_type: ""})
    |> render_change()

    assert has_element?(view, "#links", "Video de OCR")
    refute has_element?(view, "#links", "TikTok de Agentes")

    view
    |> form("#filter-form", filter: %{category: "", subcategory: "", link_type: "Instagram"})
    |> render_change()

    assert has_element?(view, "#links", "Post de Diseño UI")
    refute has_element?(view, "#links", "Video de OCR")
  end

  test "clearing active filters restores the full saved links list",
       %{conn: conn} do
    {:ok, _} = MisRedesSociales.Links.create_category(%{name: "IA"})
    {:ok, _} = MisRedesSociales.Links.create_category(%{name: "Diseño"})

    {:ok, _} =
      MisRedesSociales.Links.create_link(%{
        category: "IA",
        subcategory: "OCR",
        link_type: "Youtube",
        url: "https://www.youtube.com/watch?v=1",
        short_description: "Video de OCR"
      })

    {:ok, _} =
      MisRedesSociales.Links.create_link(%{
        category: "Diseño",
        subcategory: "UI",
        link_type: "Instagram",
        url: "https://www.instagram.com/p/3",
        short_description: "Post de Diseño UI"
      })

    {:ok, view, _html} = live(unlocked_conn(conn), ~p"/")

    view
    |> form("#filter-form", filter: %{category: "IA", subcategory: "ocr", link_type: ""})
    |> render_change()

    assert has_element?(view, "#links", "Video de OCR")
    refute has_element?(view, "#links", "Post de Diseño UI")

    view |> element("#clear-filters") |> render_click()

    assert has_element?(view, "#links", "Video de OCR")
    assert has_element?(view, "#links", "Post de Diseño UI")
  end

  test "editing a saved link in the Enlaces Guardados tab updates the card and supports canceling",
       %{conn: conn} do
    {:ok, _} = MisRedesSociales.Links.create_category(%{name: "IA"})
    {:ok, _} = MisRedesSociales.Links.create_category(%{name: "Programación"})

    {:ok, link} =
      MisRedesSociales.Links.create_link(%{
        category: "IA",
        subcategory: "OCR",
        link_type: "Youtube",
        url: "https://www.youtube.com/watch?v=1",
        short_description: "Video de OCR",
        long_description: "Nota original"
      })

    {:ok, view, _html} = live(unlocked_conn(conn), ~p"/")
    view |> element("#tab-saved") |> render_click()

    # Open edit form and cancel
    view |> element("#edit-link-#{link.id}") |> render_click()
    assert has_element?(view, "#edit-form-#{link.id}")

    view |> element("#cancel-edit-#{link.id}") |> render_click()
    refute has_element?(view, "#edit-form-#{link.id}")
    assert has_element?(view, "#links", "Video de OCR")

    # Open edit form and submit updated fields
    view |> element("#edit-link-#{link.id}") |> render_click()

    view
    |> form("#edit-form-#{link.id}",
      edit_form: %{
        category: "Programación",
        subcategory: "Elixir",
        link_type: "TikTok",
        url: "https://www.tiktok.com/@dev/video/10",
        short_description: "Video de Elixir actualizado",
        long_description: "Nota actualizada"
      }
    )
    |> render_submit()

    refute has_element?(view, "#edit-form-#{link.id}")
    assert has_element?(view, "#links", "Video de Elixir actualizado")
    assert has_element?(view, "#links", "Programación")
    assert has_element?(view, "#links", "Elixir")
    assert has_element?(view, "#links", "Nota actualizada")
  end

  test "deleting a saved link in the Enlaces Guardados tab removes it from the list and cleans up its artifact file",
       %{conn: conn} do
    artifacts_dir = Application.get_env(:mis_redes_sociales, :artifacts_dir, "artifacts")
    File.mkdir_p!(artifacts_dir)
    artifact_filename = "test-delete-#{System.unique_integer([:positive])}-manual.pdf"
    artifact_full_path = Path.join(artifacts_dir, artifact_filename)
    File.write!(artifact_full_path, "%PDF-1.4 dummy")

    {:ok, link} =
      MisRedesSociales.Links.create_link(%{
        category: "IA",
        link_type: "Youtube",
        url: "https://www.youtube.com/watch?v=del",
        short_description: "Enlace por eliminar",
        artifact_name: "manual.pdf",
        artifact_path: artifact_filename
      })

    {:ok, view, _html} = live(unlocked_conn(conn), ~p"/")
    view |> element("#tab-saved") |> render_click()

    assert has_element?(view, "#links", "Enlace por eliminar")
    assert File.exists?(artifact_full_path)

    view |> element("#delete-link-#{link.id}") |> render_click()

    refute has_element?(view, "#links", "Enlace por eliminar")
    assert MisRedesSociales.Links.list_links!() == []
    refute File.exists?(artifact_full_path)
  end
end
