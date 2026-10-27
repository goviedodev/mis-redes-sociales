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
end
