defmodule Bee do
  use GenServer

  @duration_ms 10000
  @directions [:up, :left, :right, :down]
  @enforce_keys [:pos_x, :pos_y]
  defstruct [:id, :catching, :pos_x, :pos_y]

  def start_link(defaults) do
    GenServer.start_link(__MODULE__, defaults)
  end

  @impl true
  def init(_) do
    :timer.send_interval(150, self(), :update)
    {:ok, @duration_ms}
  end

  @impl true
  def handle_info(:update, duration) when duration < 0 do
    {:stop, :shutdown, -1}
  end

  def handle_info(:update, duration) when duration > 0 do
    with %Bee{} = bee = GenServer.call(Game, {:get_bee, self()}),
         %Bear{} = bear <- GenServer.call(Game, {:get_bear, bee.catching}),
         true <- GenServer.call(Game, {:try_to_sting, bee}) do
      bee
      |> direction_lengths(bear)
      |> move_to(bee)
    end

    {:noreply, duration - 100}
  end

  def handle_info(:update, _) do
    {:stop, :normal, -1}
  end

  @impl true
  def terminate(reason, _) do
    GenServer.cast(Game, {:remove_bee, self()})
    reason
  end

  def move_to(directions, bee) do
    GenServer.cast(Game, {:move_bee, bee, directions})
  end

  def direction_lengths(bee, bear) do
    @directions
    |> Enum.reduce([], fn direction, acc ->
      [{direction, distance(direction, bee, bee) + distance(direction, bear, bee)} | acc]
    end)
    |> Enum.sort(fn {_, f}, {_, s} -> f <= s end)
    |> Keyword.keys()
  end

  def distance(:up, obj, new_pos),
    do: abs(obj.pos_x - new_pos.pos_x + 1) + abs(obj.pos_y - new_pos.pos_y)

  def distance(:down, obj, new_pos),
    do: abs(obj.pos_x - new_pos.pos_x - 1) + abs(obj.pos_y - new_pos.pos_y)

  def distance(:left, obj, new_pos),
    do: abs(obj.pos_x - new_pos.pos_x) + abs(obj.pos_y - new_pos.pos_y + 1)

  def distance(:right, obj, new_pos),
    do: abs(obj.pos_x - new_pos.pos_x) + abs(obj.pos_y - new_pos.pos_y - 1)

  def try_to_sting(bee, bears) do
    Enum.map(bears, fn bear ->
      if next_to_bee?(bee, bear),
        do: Game.remove_honey_from_bear(bear),
        else: bear
    end)
  end

  defp next_to_bee?(%Bee{pos_x: pos_x, pos_y: pos_y}, %{pos_x: bx, pos_y: by})
       when (pos_x == bx - 1 and pos_y == by) or
              (pos_x == bx + 1 and pos_y == by) or
              (pos_x == bx and pos_y == by - 1) or
              (pos_x == bx and pos_y == by + 1),
       do: true

  defp next_to_bee?(_, _), do: false
end
