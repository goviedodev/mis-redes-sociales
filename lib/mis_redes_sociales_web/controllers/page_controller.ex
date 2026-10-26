defmodule MisRedesSocialesWeb.PageController do
  use MisRedesSocialesWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
