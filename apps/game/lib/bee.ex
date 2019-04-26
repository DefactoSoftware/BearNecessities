defmodule Bee do
  use Genserver

  @directions [:up, :left, :right, :down]
  @enforce_keys [:pos_x, :pos_y]
  defstruct [:id, :catching, :pos_x, :pos_y]

  def start_link(defaults) do
    GenServer.start_link(__MODULE__, defaults)
  end

  def init(position) do
    :timer.send_interval(100, self(), :update)
    GenServer.cast(Game, {:create_bee, self})
    {:ok, pid}
  end

  @impl true
  def handle_info(:update, pid) do
    bee = GenServer.call(Game, {:get_bee, pid})
    bear = GenServer.call(Game, {:get_bear, bee.catching})

    unless GenServer.call(Game, {:try_to_sting, bee}) do
      bee
      |> direction_lengths(bear)
      |> move_to(bee)
    end

    {:noreply, pid}
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
    do: abs(obj.pos_x - new_pos.pos_x - 1) + abs(obj.pos_y - new_pos.pos_y)

  def distance(:down, obj, new_pos),
    do: abs(obj.pos_x - new_pos.pos_x + 1) + abs(obj.pos_y - new_pos.pos_y)

  def distance(:left, obj, new_pos),
    do: abs(obj.pos_x - new_pos.pos_x) + abs(obj.pos_y - new_pos.pos_y - 1)

  def distance(:right, obj, new_pos),
    do: abs(obj.pos_x - new_pos.pos_x) + abs(obj.pos_y - new_pos.pos_y + 1)
end
