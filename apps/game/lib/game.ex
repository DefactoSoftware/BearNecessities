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
  def handle_call(
        {:create_bear, [display_name: display_name, id: id, started: started]},
        _pid,
        state
      ) do
    field = Map.get(state, :field)
    bear = Bear.create_bear(field, id, display_name, started)
    {:reply, bear, %{state | bears: [bear | Map.get(state, :bears)]}}
  end

  @impl true
  def handle_call({:move, %Bear{id: id} = bear, [to: {pos_x, pos_y} = position]}, _pid, state) do
    bear =
      if move_to?(position, id, state),
        do: %{bear | pos_x: pos_x, pos_y: pos_y},
        else: bear

    state = update_state_with(state, bear)

    {:reply, bear, state}
  end

  @impl true
  def handle_call({:get_bear, id}, _pid, %{bears: bears} = state) do
    bear =
      bears
      |> Enum.filter(fn bear ->
        bear.id == id
      end)
      |> List.last()

    {:reply, bear, state}
  end

  @impl true
  def handle_call({:get_field, id}, _pid, %{field: field} = state) do
    {:reply, field, state}
  end

  def update_state_with(%{bears: bears} = state, bear = %Bear{}) do
    bears =
      Enum.map(bears, fn list_bear ->
        if list_bear.id == bear.id,
          do: bear,
          else: list_bear
      end)

    %{state | bears: bears}
  end

  def move(bear, position) do
    GenServer.call(Game, {:move, bear, position})
  end

  def get_bear(id) do
    GenServer.call(Game, {:get_bear, id})
  end

  def get_field(id) do
    GenServer.call(Game, {:get_field, id})
  end

  defp view_elements({x, y}, bears) do
    Enum.filter(bears, &(&1.pos_x < x + @horizontal_field_of_view))
  end

  defp move_to?(position, id, %{trees: trees, bears: bears, field: field}) do
    id_trees =
      Task.async(fn ->
        not Enum.any?(trees, fn tree -> tree.position == position end)
      end)

    id_bears =
      Task.async(fn ->
        not Enum.any?(bears, fn bear ->
          {bear.pos_x, bear.pos_y} == position and bear.id != id
        end)
      end)

    Task.await(id_bears) and Task.await(id_trees) and pos_within_field?(position, field)
  end

  def pos_within_field?({pos_x, pos_y} = position, %{height: height, width: width}) do
    pos_x > 0 and pos_y > 0 and pos_x < height and pos_y < width
  end

  def create_bear(display_name: display_name, id: id, started: started) do
    GenServer.call(Game, {:create_bear, display_name: display_name, id: id, started: started})
  end

  def handle_info(pid, state) do
    {:noreply, state}
  end

  # def handle_info({:DOWN, _, :process, _, reason}, _) do
  #   {:stop, reason, []}
  # end
end
