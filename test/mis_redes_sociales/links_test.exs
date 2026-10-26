defmodule MisRedesSociales.LinksTest do
  use MisRedesSociales.DataCase, async: false

  alias MisRedesSociales.Links

  test "creates a category and lists categories in alphabetical order" do
    assert {:ok, _} = Links.create_category(%{name: "Programación"})
    assert {:ok, _} = Links.create_category(%{name: "IA"})

    categories = Links.list_categories!()
    assert Enum.map(categories, & &1.name) == ["IA", "Programación"]
  end
end
