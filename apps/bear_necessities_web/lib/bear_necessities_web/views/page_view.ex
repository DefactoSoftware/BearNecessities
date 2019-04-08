defmodule BearNecessitiesWeb.PageView do
  # use BearNecessitiesWeb, :view
  use Phoenix.LiveView

  alias BearNecessitiesWeb.LeukDitView

  def render(assigns) do
    LeukDitView.render("index.html", assigns)
  end

  def mount(_session, socket) do
    {:ok, assign(socket, other_things: "echt knap dit")}
  end
end
