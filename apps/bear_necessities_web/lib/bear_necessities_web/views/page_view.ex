defmodule BearNecessitiesWeb.PageView do
  # use BearNecessitiesWeb, :view
  use Phoenix.LiveView

  alias BearNecessitiesWeb.LeukDitView

  def handle_event("inc", _, socket) do
    {:noreply, update(socket, :counter, &(&1 + 1))}
  end

  def render(assigns) do
    LeukDitView.render("index.html", assigns)
  end

  def mount(_session, socket) do
    {:ok, assign(socket, counter: 1)}
  end
end
