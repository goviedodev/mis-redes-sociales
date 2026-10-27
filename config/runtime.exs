import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

if System.get_env("PHX_SERVER") do
  config :mis_redes_sociales, MisRedesSocialesWeb.Endpoint, server: true
end

config :mis_redes_sociales, MisRedesSocialesWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))]

if config_env() == :prod do
  database_path =
    System.get_env("DATABASE_PATH") ||
      raise """
      environment variable DATABASE_PATH is missing.
      For example: /app/data/mis_redes_sociales.db
      """

  artifacts_dir = System.get_env("ARTIFACTS_DIR") || "/app/artifacts"
  backups_dir = System.get_env("BACKUPS_DIR") || "/app/backups"

  config :mis_redes_sociales,
    artifacts_dir: artifacts_dir,
    backups_dir: backups_dir

  config :mis_redes_sociales, MisRedesSociales.Repo,
    database: database_path,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5")

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "redesgo.sevenit.cl"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :mis_redes_sociales, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :mis_redes_sociales, MisRedesSocialesWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    check_origin: false,
    http: [
      ip: {0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base
end
