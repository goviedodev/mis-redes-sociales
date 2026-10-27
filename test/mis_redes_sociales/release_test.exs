defmodule MisRedesSociales.ReleaseTest do
  use MisRedesSociales.DataCase, async: false

  alias MisRedesSociales.Release

  test "Release.migrate/0 executes pending repository migrations without error" do
    assert :ok = Release.migrate()
    assert File.regular?("rel/overlays/bin/migrate")
    assert File.regular?("rel/overlays/bin/server")
  end
end
