defmodule Game do
  use GenServer
  @vertical_field_of_view 200
  @horizontal_field_of_view 200

  defstruct [:field, :bears, :bees, :trees]

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  @impl true
  def init([]) do
    {:ok, %Game{field: %Field{height: 1000, width: 1000}, bears: [], bees: [], trees: []}}
  end

  @impl true
  def handle_call({:create_bear, display_name: display_name}, pid, state) do
    field = Map.get(state, :field)
    bear = Bear.create_bear(field, pid, display_name)
    {:reply, bear, %{state | bears: [bear | Map.get(state, :bears)]}}
  end

  @impl true
  def handle_call({:move, %Bear{} = bear, [to: {pos_x, pos_y} = position]}, pid, state) do
    bear =
      if move_to?(position, pid, state),
        do: %{bear | pos_x: pos_x, pos_y: pos_y},
        else: bear

    state = update_state_with(state, bear)

    {:reply, bear, state}
  end

  @impl true
  def handle_call({:get_bear, pid}, _pid, %{bears: bears} = state) do
    bear =
      bears
      |> Enum.filter(fn bear ->
        {bear_pid, _} = bear.pid
        {pid, _} = pid
        bear_pid == pid
      end)
      |> List.last()

    {:reply, bear, state}
  end

  def update_state_with(%{bears: bears} = state, bear = %Bear{}) do
    bears =
      Enum.map(bears, fn list_bear ->
        if list_bear.pid == bear.pid,
          do: bear,
          else: list_bear
      end)

    %{state | bears: bears}
  end

  def move(bear, position) do
    GenServer.call(Game, {:move, bear, position})
  end

  def get_bear(pid) do
    GenServer.call(Game, {:get_bear, pid})
  end

  defp view_elements({x, y}, bears) do
    Enum.filter(bears, &(&1.pos_x < x + @horizontal_field_of_view))
  end

  defp move_to?(position, pid, %{trees: trees, bears: bears, field: field}) do
    pid_trees =
      Task.async(fn ->
        Enum.any?(trees, fn tree -> tree.position == position end)
      end)

    pid_bears =
      Task.async(fn ->
        Enum.any?(bears, fn bear ->
          {bear.pos_x, bear.pos_y} == position and bear.pid != pid
        end)
      end)

    Task.await(pid_bears) and Task.await(pid_trees) and pos_within_field?(position, field)
  end

  def pos_within_field?({pos_x, pos_y} = position, %{height: height, width: width}) do
    pos_x > 0 and pos_y > 0 and pos_x < height and pos_y < width
  end

  def create_bear(display_name: display_name) do
    GenServer.call(Game, {:create_bear, display_name: display_name})
  end
end
