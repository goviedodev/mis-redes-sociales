defmodule MisRedesSociales.DeploymentConfigTest do
  use ExUnit.Case, async: true

  test "Dockerfile and docker-compose.yml configure the Phoenix release with America/Santiago timezone, persistent volumes for database/artifacts/backups, and cloudflared tunnel for redesgo.sevenit.cl" do
    assert File.regular?("Dockerfile")
    dockerfile = File.read!("Dockerfile")
    assert dockerfile =~ "mix assets.deploy"
    assert dockerfile =~ "mix release"
    assert dockerfile =~ "/app/bin/server"

    assert File.regular?("docker-compose.yml")
    compose = File.read!("docker-compose.yml")
    assert compose =~ "TZ=America/Santiago"
    assert compose =~ "redesgo.sevenit.cl"
    assert compose =~ "./data:/app/data"
    assert compose =~ "./artifacts:/app/artifacts"
    assert compose =~ "./backups:/app/backups"
    assert compose =~ "cloudflare/cloudflared:latest"
    assert compose =~ "./cloudflared:/etc/cloudflared"

    assert File.regular?("setup-tunnel.sh")
    setup_tunnel = File.read!("setup-tunnel.sh")
    assert setup_tunnel =~ "redesgo.sevenit.cl"
    assert setup_tunnel =~ "http://app:4000"
    assert setup_tunnel =~ "protocol: http2"

    prod_config = File.read!("config/prod.exs")
    refute prod_config =~ "force_ssl:"

    runtime_config = File.read!("config/runtime.exs")
    assert runtime_config =~ "ARTIFACTS_DIR"
    assert runtime_config =~ "check_origin: false"
  end
end
