defmodule BearNecessitiesWeb.PageController do
  use BearNecessitiesWeb, :controller

  alias BearNecessitiesWeb.PageView
  alias Phoenix.LiveView

  def index(conn, _params) do
    LiveView.Controller.live_render(conn, PageView, session: %{})
  end
end
