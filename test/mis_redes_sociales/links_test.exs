defmodule MisRedesSociales.LinksTest do
  use MisRedesSociales.DataCase, async: false

  alias MisRedesSociales.Links

  test "creates a category and lists categories in alphabetical order" do
    assert {:ok, _} = Links.create_category(%{name: "Programación"})
    assert {:ok, _} = Links.create_category(%{name: "IA"})

    categories = Links.list_categories!()
    assert Enum.map(categories, & &1.name) == ["IA", "Programación"]
  end

  test "saves a link with optional subcategory and long description" do
    assert {:ok, link} =
             Links.create_link(%{
               category: "IA",
               subcategory: "OCR",
               link_type: "Youtube",
               url: "https://www.youtube.com/shorts/KigUHSCgDNo",
               short_description: "AI Creator Studio",
               long_description:
                 "Es un video corto que indica todos los pasos para crear videos para youtube"
             })

    assert link.subcategory == "OCR"

    assert link.long_description ==
             "Es un video corto que indica todos los pasos para crear videos para youtube"
  end

  test "saves a link with optional artifact_name and artifact_path" do
    assert {:ok, link} =
             Links.create_link(%{
               category: "IA",
               link_type: "Youtube",
               url: "https://www.youtube.com/shorts/KigUHSCgDNo",
               short_description: "AI Creator Studio",
               artifact_name: "guia-ocr.pdf",
               artifact_path: "1729950000-guia-ocr.pdf"
             })

    assert link.artifact_name == "guia-ocr.pdf"
    assert link.artifact_path == "1729950000-guia-ocr.pdf"
  end

  test "filters links by category, subcategory (case-insensitive), and link_type in newest-first order" do
    {:ok, link1} =
      Links.create_link(%{
        category: "IA",
        subcategory: "OCR",
        link_type: "Youtube",
        url: "https://www.youtube.com/watch?v=1",
        short_description: "IA OCR Youtube"
      })

    {:ok, link2} =
      Links.create_link(%{
        category: "IA",
        subcategory: "Agentes",
        link_type: "TikTok",
        url: "https://www.tiktok.com/@user/video/2",
        short_description: "IA Agentes TikTok"
      })

    {:ok, link3} =
      Links.create_link(%{
        category: "Diseño",
        subcategory: "UI",
        link_type: "Instagram",
        url: "https://www.instagram.com/p/3",
        short_description: "Diseño UI Instagram"
      })

    assert Enum.map(Links.list_links!(%{category: "IA"}), & &1.id) == [link2.id, link1.id]
    assert Enum.map(Links.list_links!(%{subcategory: "ocr"}), & &1.id) == [link1.id]
    assert Enum.map(Links.list_links!(%{link_type: "Instagram"}), & &1.id) == [link3.id]

    assert Enum.map(
             Links.list_links!(%{category: "IA", subcategory: "agentes", link_type: "TikTok"}),
             & &1.id
           ) == [link2.id]
  end

  test "updates an existing link's fields and destroys a link" do
    {:ok, link} =
      Links.create_link(%{
        category: "IA",
        subcategory: "OCR",
        link_type: "Youtube",
        url: "https://www.youtube.com/watch?v=1",
        short_description: "Descripción inicial",
        long_description: "Detalle inicial"
      })

    assert {:ok, updated} =
             Links.update_link(link, %{
               category: "Programación",
               subcategory: "Elixir",
               link_type: "TikTok",
               url: "https://www.tiktok.com/@user/video/99",
               short_description: "Descripción actualizada",
               long_description: "Detalle actualizado"
             })

    assert updated.category == "Programación"
    assert updated.subcategory == "Elixir"
    assert updated.link_type == "TikTok"
    assert updated.url == "https://www.tiktok.com/@user/video/99"
    assert updated.short_description == "Descripción actualizada"
    assert updated.long_description == "Detalle actualizado"

    assert {:ok, fetched} = Links.get_link(link.id)
    assert fetched.short_description == "Descripción actualizada"

    assert :ok = Links.destroy_link(updated)
    assert Links.list_links!() == []
  end
end
