defmodule MisRedesSociales.Repo do
  use AshSqlite.Repo,
    otp_app: :mis_redes_sociales

  def min_sqlite_version do
    %Version{major: 3, minor: 40, patch: 0}
  end
end
