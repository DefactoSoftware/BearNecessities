defmodule BearNecessitiesWeb.PageController do
  use BearNecessitiesWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
