defmodule BearNecessitiesWeb.Game do
  use Phoenix.LiveView
  require Logger
  @up_key 38
  @down_key 40
  @left_key 11
  @right_key 39
  def render(assigns) do
    ~L"""
    <div>
      <button phx-click="left">left</button>
      <button phx-click="down">down</button>
      <button phx-click="up">up</button>
      <button phx-click="right">right</button>
    <div phx-keyup="key_move" phx-target="window"></div>
      <div class="bear">
        <h1>PosX <%= @pos_x %></h1>
        <h1>PosY <%= @pos_y %></h1>
      </div>
    </div>
    """
  end

  def mount(_session, %{id: id} = socket) do
    bear = Player.start("fatboypunk", id)

    socket =
      socket
      |> assign(:pos_x, bear.pos_x)
      |> assign(:pos_y, bear.pos_y)

    {:ok, socket}
  end

  def handle_event(_, "Meta", socket) do
    IO.inspect("hoi")
    {:noreply, socket}
  end

  def handle_event("key_move", key, %{id: id} = socket) do
    key
    |> IO.inspect(label: "key")

    bear = Player.move(id, move_to(key))

    socket =
      socket
      |> update(:pos_x, fn _ -> bear.pos_x end)
      |> update(:pos_y, fn _ -> bear.pos_y end)

    {:noreply, socket}
  end

  def move_to("ArrowRight"), do: :right_arrow
  def move_to("ArrowLeft"), do: :left_arrow
  def move_to("ArrowUp"), do: :up_arrow
  def move_to("ArrowDown"), do: :down_arrow
end
