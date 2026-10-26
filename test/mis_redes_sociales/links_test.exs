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
end
