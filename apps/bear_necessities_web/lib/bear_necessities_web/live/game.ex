defmodule BearNecessitiesWeb.Game do
  use Phoenix.LiveView
  require Logger

  @action_keys ["ArrowRight", "ArrowLeft", "ArrowUp", "ArrowDown"]

  alias BearNecessitiesWeb.Playfield

  def render(assigns) do
    Playfield.render("template.html", assigns)
  end

  def mount(_session, %{id: id} = socket) do
    field = Game.get_field(id)

    socket =
      socket
      |> assign(:id, id)
      |> assign(:viewport, [])
      |> assign(:pos_x, nil)
      |> assign(:pos_y, nil)
      |> assign(:field, field)
      |> assign(:bear, %Bear{started: false})

    {:ok, socket}
  end

  def handle_event("start", %{"display_name" => display_name}, %{id: id} = socket) do
    if connected?(socket), do: :timer.send_interval(50, self(), :update_viewport)
    bear = Player.start(display_name, id)
    viewport = ViewPort.get_viewport(id)

    socket =
      socket
      |> assign(:id, id)
      |> assign(:viewport, viewport)
      |> assign(:pos_x, bear.pos_x)
      |> assign(:pos_y, bear.pos_y)
      |> assign(:bear, bear)

    {:noreply, socket}
  end

  def handle_event(_, "Meta", socket) do
    {:noreply, socket}
  end

  def handle_event("key_move", key, %{id: id} = socket)
      when key in @action_keys do
    bear = Player.move(id, move_to(key))

    viewport = ViewPort.get_viewport(id)

    socket =
      socket
      |> assign(:pos_x, bear.pos_x)
      |> assign(:pos_y, bear.pos_y)
      |> assign(:viewport, viewport)

    {:noreply, socket}
  end

  def handle_event("key_move", _, socket) do
    {:noreply, socket}
  end

  def handle_info(:update_viewport, %{id: id} = socket) do
    viewport = ViewPort.get_viewport(id)

    {:noreply, assign(socket, :viewport, viewport)}
  end

  def terminate(reason, %{id: id} = socket) do
    Game.remove_bear(id)

    reason
  end

  def move_to("ArrowRight"), do: :right_arrow
  def move_to("ArrowLeft"), do: :left_arrow
  def move_to("ArrowUp"), do: :up_arrow
  def move_to("ArrowDown"), do: :down_arrow
end
