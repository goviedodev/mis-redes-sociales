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

  test "clicking 'Crear Respaldo Ahora' on /admin creates a backup file immediately and displays a confirmation message",
       %{conn: conn} do
    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "mrs_admin_backup_test_#{System.unique_integer([:positive])}"
      )

    previous_dir = Application.get_env(:mis_redes_sociales, :backups_dir)
    Application.put_env(:mis_redes_sociales, :backups_dir, tmp_dir)

    on_exit(fn ->
      if previous_dir do
        Application.put_env(:mis_redes_sociales, :backups_dir, previous_dir)
      else
        Application.delete_env(:mis_redes_sociales, :backups_dir)
      end

      File.rm_rf!(tmp_dir)
    end)

    {:ok, view, _html} = live(unlocked_conn(conn), ~p"/admin")

    assert has_element?(view, "#create-backup-btn", "Crear Respaldo Ahora")

    html =
      view
      |> element("#create-backup-btn")
      |> render_click()

    assert html =~ "Respaldo creado correctamente"
    assert [backup_file] = File.ls!(tmp_dir)
    assert String.starts_with?(backup_file, "backup_")
    assert String.ends_with?(backup_file, ".db")
  end

  test "renders empty backups state on /admin and updates the backups list with download links when backups exist or are created",
       %{conn: conn} do
    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "mrs_admin_backups_list_#{System.unique_integer([:positive])}"
      )

    previous_dir = Application.get_env(:mis_redes_sociales, :backups_dir)
    Application.put_env(:mis_redes_sociales, :backups_dir, tmp_dir)

    on_exit(fn ->
      if previous_dir do
        Application.put_env(:mis_redes_sociales, :backups_dir, previous_dir)
      else
        Application.delete_env(:mis_redes_sociales, :backups_dir)
      end

      File.rm_rf!(tmp_dir)
    end)

    {:ok, view, _html} = live(unlocked_conn(conn), ~p"/admin")

    assert has_element?(view, "#backups-empty", "No hay respaldos disponibles aún.")

    view
    |> element("#create-backup-btn")
    |> render_click()

    assert [backup_file] = File.ls!(tmp_dir)
    assert has_element?(view, "#backups", backup_file)
    assert has_element?(view, "a[href='/backups/#{backup_file}']", "Descargar")
  end

  test "clicking delete on a backup opens a confirmation modal, canceling keeps the backup, and accepting deletes the file and removes it from the list",
       %{conn: conn} do
    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "mrs_admin_backup_delete_#{System.unique_integer([:positive])}"
      )

    previous_dir = Application.get_env(:mis_redes_sociales, :backups_dir)
    Application.put_env(:mis_redes_sociales, :backups_dir, tmp_dir)

    on_exit(fn ->
      if previous_dir do
        Application.put_env(:mis_redes_sociales, :backups_dir, previous_dir)
      else
        Application.delete_env(:mis_redes_sociales, :backups_dir)
      end

      File.rm_rf!(tmp_dir)
    end)

    {:ok, view, _html} = live(unlocked_conn(conn), ~p"/admin")
    view |> element("#create-backup-btn") |> render_click()

    assert [backup_file] = File.ls!(tmp_dir)

    view |> element("[id='delete-backup-#{backup_file}']") |> render_click()
    assert has_element?(view, "#delete-backup-modal", backup_file)

    view |> element("#cancel-delete-backup") |> render_click()
    refute has_element?(view, "#delete-backup-modal")
    assert File.exists?(Path.join(tmp_dir, backup_file))
    assert has_element?(view, "#backups", backup_file)

    view |> element("[id='delete-backup-#{backup_file}']") |> render_click()
    assert has_element?(view, "#delete-backup-modal", backup_file)

    html = view |> element("#confirm-delete-backup") |> render_click()
    refute has_element?(view, "#delete-backup-modal")
    assert html =~ "Respaldo eliminado correctamente"
    refute File.exists?(Path.join(tmp_dir, backup_file))
    refute has_element?(view, "#backups", backup_file)
  end

  test "clicking restore on a backup opens a confirmation modal, and accepting restores the SQLite database to the backup state",
       %{conn: conn} do
    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "mrs_admin_backup_restore_#{System.unique_integer([:positive])}"
      )

    previous_dir = Application.get_env(:mis_redes_sociales, :backups_dir)
    Application.put_env(:mis_redes_sociales, :backups_dir, tmp_dir)

    on_exit(fn ->
      if previous_dir do
        Application.put_env(:mis_redes_sociales, :backups_dir, previous_dir)
      else
        Application.delete_env(:mis_redes_sociales, :backups_dir)
      end

      File.rm_rf!(tmp_dir)
    end)

    {:ok, _} = MisRedesSociales.Links.create_category(%{name: "OriginalCat"})

    {:ok, _} =
      MisRedesSociales.Links.create_link(%{
        category: "OriginalCat",
        link_type: "Youtube",
        url: "https://www.youtube.com/watch?v=orig",
        short_description: "Enlace Original"
      })

    {:ok, view, _html} = live(unlocked_conn(conn), ~p"/admin")
    view |> element("#create-backup-btn") |> render_click()
    assert [backup_file] = File.ls!(tmp_dir)

    {:ok, _} = MisRedesSociales.Links.create_category(%{name: "CategoriaTemporal"})

    {:ok, _} =
      MisRedesSociales.Links.create_link(%{
        category: "CategoriaTemporal",
        link_type: "TikTok",
        url: "https://www.tiktok.com/@temp",
        short_description: "Enlace Temporal"
      })

    assert Enum.map(MisRedesSociales.Links.list_categories!(), & &1.name) == [
             "CategoriaTemporal",
             "OriginalCat"
           ]

    view |> element("[id='restore-backup-#{backup_file}']") |> render_click()
    assert has_element?(view, "#restore-backup-modal", backup_file)

    view |> element("#cancel-restore-backup") |> render_click()
    refute has_element?(view, "#restore-backup-modal")

    view |> element("[id='restore-backup-#{backup_file}']") |> render_click()
    html = view |> element("#confirm-restore-backup") |> render_click()

    refute has_element?(view, "#restore-backup-modal")
    assert html =~ "Respaldo restaurado correctamente"

    assert [%{name: "OriginalCat"}] = MisRedesSociales.Links.list_categories!()
    assert [%{short_description: "Enlace Original"}] = MisRedesSociales.Links.list_links!()
  end

  test "lists preloaded default link types (Youtube, Facebook, Instagram, TikTok) on /admin and creates a new unique link type",
       %{conn: conn} do
    {:ok, view, _html} = live(unlocked_conn(conn), ~p"/admin")

    for default_type <- ["Youtube", "Facebook", "Instagram", "TikTok"] do
      assert has_element?(view, "#link-types", default_type)
    end

    view
    |> form("#link-type-form", link_type_form: %{name: "LinkedIn"})
    |> render_submit()

    assert has_element?(view, "#link-types", "LinkedIn")
    assert "LinkedIn" in Enum.map(MisRedesSociales.Links.list_link_types!(), & &1.name)
  end

  test "rejects creating a link type with an empty or duplicate name on /admin",
       %{conn: conn} do
    {:ok, view, _html} = live(unlocked_conn(conn), ~p"/admin")

    empty_html =
      view
      |> form("#link-type-form", link_type_form: %{name: ""})
      |> render_submit()

    assert empty_html =~ "es obligatorio"

    dup_html =
      view
      |> form("#link-type-form", link_type_form: %{name: "Youtube"})
      |> render_submit()

    assert dup_html =~ "ya existe"
  end

  test "renaming a link type on /admin updates its name in the list and automatically updates all saved links using that link type",
       %{conn: conn} do
    {:ok, _} = MisRedesSociales.Links.create_category(%{name: "IA"})

    {:ok, link} =
      MisRedesSociales.Links.create_link(%{
        category: "IA",
        link_type: "Youtube",
        url: "https://www.youtube.com/watch?v=123",
        short_description: "Video de Youtube"
      })

    {:ok, view, _html} = live(unlocked_conn(conn), ~p"/admin")

    youtube_type =
      MisRedesSociales.Links.list_link_types!()
      |> Enum.find(&(&1.name == "Youtube"))

    view |> element("#edit-link-type-#{youtube_type.id}") |> render_click()
    assert has_element?(view, "#edit-link-type-form-#{youtube_type.id}")

    view
    |> form("#edit-link-type-form-#{youtube_type.id}",
      edit_link_type_form: %{name: "YouTube Shorts"}
    )
    |> render_submit()

    assert has_element?(view, "#link-types", "YouTube Shorts")
    refute has_element?(view, "#edit-link-type-form-#{youtube_type.id}")

    updated_link = MisRedesSociales.Links.get_link!(link.id)
    assert updated_link.link_type == "YouTube Shorts"
  end

  test "deleting an unused link type on /admin after accepting the confirmation dialog removes it from the list",
       %{conn: conn} do
    {:ok, view, _html} = live(unlocked_conn(conn), ~p"/admin")

    tiktok_type =
      MisRedesSociales.Links.list_link_types!()
      |> Enum.find(&(&1.name == "TikTok"))

    view |> element("#delete-link-type-#{tiktok_type.id}") |> render_click()
    assert has_element?(view, "#delete-link-type-modal", "TikTok")

    view |> element("#cancel-delete-link-type") |> render_click()
    refute has_element?(view, "#delete-link-type-modal")
    assert has_element?(view, "#link-types", "TikTok")

    view |> element("#delete-link-type-#{tiktok_type.id}") |> render_click()
    view |> element("#confirm-delete-link-type") |> render_click()

    refute has_element?(view, "#delete-link-type-modal")
    refute has_element?(view, "#link-types", "TikTok")
    refute "TikTok" in Enum.map(MisRedesSociales.Links.list_link_types!(), & &1.name)
  end

  test "blocks deleting a link type on /admin when at least one saved link uses it and shows a Spanish error message",
       %{conn: conn} do
    {:ok, _} = MisRedesSociales.Links.create_category(%{name: "IA"})

    {:ok, _link} =
      MisRedesSociales.Links.create_link(%{
        category: "IA",
        link_type: "Youtube",
        url: "https://www.youtube.com/watch?v=inuse",
        short_description: "Enlace en uso"
      })

    {:ok, view, _html} = live(unlocked_conn(conn), ~p"/admin")

    youtube_type =
      MisRedesSociales.Links.list_link_types!()
      |> Enum.find(&(&1.name == "Youtube"))

    view |> element("#delete-link-type-#{youtube_type.id}") |> render_click()
    assert has_element?(view, "#delete-link-type-modal", "Youtube")

    html = view |> element("#confirm-delete-link-type") |> render_click()

    refute has_element?(view, "#delete-link-type-modal")
    assert html =~ "está siendo usado por enlaces guardados"
    assert has_element?(view, "#link-types", "Youtube")
    assert "Youtube" in Enum.map(MisRedesSociales.Links.list_link_types!(), & &1.name)
  end
end
