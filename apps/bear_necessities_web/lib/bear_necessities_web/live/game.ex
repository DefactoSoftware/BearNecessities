defmodule BearNecessitiesWeb.Game do
  use Phoenix.LiveView
  require Logger

  alias BearNecessitiesWeb.Playfield

  def render(assigns) do
    Playfield.render("template.html", assigns)
  end

  def mount(_session, %{id: id} = socket) do
    pid = Player.setup_player()
    field = Game.get_field(id)
    players = Game.get_players()

    socket =
      socket
      |> assign(:id, id)
      |> assign(:viewport, [])
      |> assign(:pos_x, nil)
      |> assign(:pos_y, nil)
      |> assign(:set_setting, false)
      |> assign(:player_id, pid)
      |> assign(:field, field)
      |> assign(:players, players)
      |> assign(:bear, %Bear{started: false})

    {:ok, socket}
  end

  def handle_event("start", %{"player" => %{"display_name" => display_name}}, %{id: id} = socket) do
    if connected?(socket), do: :timer.send_interval(50, self(), :update)

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

  def handle_event("key_move", key, %{id: id, assigns: %{player_id: pid}} = socket) do
    bear = Player.move(id, pid, key)
    viewport = ViewPort.get_viewport(id)

    socket =
      socket
      |> assign(:pos_x, bear.pos_x)
      |> assign(:pos_y, bear.pos_y)
      |> assign(:viewport, viewport)

    {:noreply, socket}
  end

  def handle_event("set_setting", value, socket) do
    socket = assign(socket, :set_setting, Player.set_setting(value))
    {:noreply, socket}
  end

  def handle_event(
        "set_movement",
        key,
        %{assigns: %{player_id: pid, set_setting: set_setting}} = socket
      ) do
    socket = assign(socket, :set_setting, Player.update_movement(pid, key, set_setting))
    {:noreply, socket}
  end

  def handle_info(:update, %{id: id} = socket) do
    players = Game.get_players()
    viewport = ViewPort.get_viewport(id)

    socket =
      socket
      |> assign(:viewport, viewport)
      |> assign(:players, players)

    {:noreply, socket}
  end

  def terminate(reason, %{id: id} = socket) do
    Game.remove_bear(id)

    reason
  end
end
