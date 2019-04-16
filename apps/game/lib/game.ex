defmodule Game do
  use GenServer
  @vertical_view_distance 5
  @horizontal_view_distance 5
  @number_of_trees 20

  defstruct [:field, :bears, :bees, :trees]

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  @impl true
  def init([]) do
    field = Field.create_field(40, 40)

    game = %Game{
      field: field,
      bears: [],
      bees: [],
      trees: spawn_trees()
    }

    {:ok, game}
  end

  @impl true
  def handle_call(
        {:get_viewport, id},
        _pid,
        %{bears: bears} = state
      ) do
    %{pos_x: x, pos_y: y} = get_bear_from_list(id, bears)
    position = {x, y}
    viewport = create_viewport(position, state)
    {:reply, viewport, state}
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
  def handle_call(
        {:move, %Bear{id: id} = bear, direction, [to: {pos_x, pos_y} = position]},
        _pid,
        state
      ) do
    bear =
      if move_to?(position, id, state),
        do: %{bear | pos_x: pos_x, pos_y: pos_y, direction: direction},
        else: %{bear | direction: direction}

    state = update_state_with(state, bear)

    {:reply, bear, state}
  end

  @impl true
  def handle_call(
        {:claw, %Bear{honey: bear_honey, direction: direction, pos_x: x, pos_y: y} = bear},
        _pid,
        state
      ) do
    {bear, state} =
      case target(direction, x, y, state) do
        %Tree{honey: tree_honey} = tree when tree_honey > 0 ->
          new_bear = %{bear | honey: bear_honey + 1}

          new_state =
            state
            |> update_state_with(new_bear)
            |> update_state_with(%{tree | honey: tree_honey - 1})

          {new_bear, new_state}

        %Bear{honey: other_bear_honey} = other_bear when other_bear_honey > 0 ->
          new_bear = %{bear | honey: bear_honey + 1}

          new_state =
            state
            |> update_state_with(new_bear)
            |> update_state_with(%{other_bear | honey: other_bear_honey - 1})

          {new_bear, new_state}

        %Tree{honey: 0} ->
          {bear, state}

        %Bear{honey: 0} ->
          {bear, state}

        _ ->
          {bear, state}
      end

    {:reply, bear, state}
  end

  @impl true
  def handle_call({:get_bear, id}, _pid, %{bears: bears} = state) do
    bear = get_bear_from_list(id, bears)
    {:reply, bear, state}
  end

  @impl true
  def handle_call({:get_field, id}, _pid, %{field: field} = state) do
    {:reply, field, state}
  end

  @impl true
  def handle_call(:get_players, _pid, %{bears: bears} = state) do
    {:reply, bears, state}
  end

  @impl true
  def handle_cast({:remove_bear, id}, %{bears: bears} = state) do
    bears = Enum.reject(bears, &(&1.id == id))

    {:noreply, %{state | bears: bears}}
  end

  def target(direction, x, y, %{bears: bears, trees: trees}) do
    {target_x, target_y} =
      case direction do
        :down -> {x + 1, y}
        :up -> {x - 1, y}
        :left -> {x, y - 1}
        :right -> {x, y + 1}
      end

    Enum.find(bears, &(&1.pos_x == target_x and &1.pos_y == target_y)) ||
      Enum.find(trees, &(&1.pos_x == target_x and &1.pos_y == target_y))
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

  def update_state_with(%{trees: trees} = state, tree = %Tree{}) do
    trees =
      Enum.map(trees, fn list_tree ->
        if list_tree.pos_y == tree.pos_y and list_tree.pos_x == tree.pos_x,
          do: tree,
          else: list_tree
      end)

    %{state | trees: trees}
  end

  def move(bear, direction, position) do
    GenServer.call(Game, {:move, bear, direction, position})
  end

  def claw(bear) do
    GenServer.call(Game, {:claw, bear})
  end

  def get_bear(id) do
    GenServer.call(Game, {:get_bear, id})
  end

  defp get_bear_from_list(id, bears) do
    bears
    |> Enum.filter(fn bear ->
      bear.id == id
    end)
    |> List.last()
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
        not Enum.any?(trees, fn tree -> {tree.pos_x, tree.pos_y} == position end)
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
    pos_x >= 0 and pos_y >= 0 and pos_x <= height and pos_y <= width
  end

  def create_bear(display_name: display_name, id: id, started: started) do
    GenServer.call(Game, {:create_bear, display_name: display_name, id: id, started: started})
  end

  def get_from_list_task({item_x, item_y}, list) do
    Task.async(fn ->
      Enum.filter(list, fn %{pos_x: pos_x, pos_y: pos_y} ->
        pos_x <= item_x + @horizontal_view_distance and
          pos_x >= item_x - @horizontal_view_distance and
          pos_y <= item_y + @vertical_view_distance and pos_y >= item_y - @vertical_view_distance
      end)
    end)
  end

  def item_from_list({row, column}, list) do
    list
    |> Enum.filter(fn %{pos_x: x, pos_y: y} = item -> x == row and y == column end)
    |> List.last()
  end

  def create_viewport({bear_x, bear_y} = position, %Game{field: field, bears: bears, trees: trees}) do
    bears_task = get_from_list_task(position, bears)
    trees_task = get_from_list_task(position, trees)

    list = Task.await(bears_task) ++ Task.await(trees_task)

    Enum.reduce(
      (bear_x - @horizontal_view_distance)..(bear_x + @horizontal_view_distance),
      [],
      fn row, outer ->
        List.insert_at(
          outer,
          -1,
          Enum.reduce(
            (bear_y - @vertical_view_distance)..(bear_y + @vertical_view_distance),
            [],
            fn column, inner ->
              inner ++
                [
                  cond do
                    not is_nil(item = item_from_list({row, column}, list)) ->
                      {get_tile(field, row, column), item}

                    pos_within_field?({row, column}, field) ->
                      {get_tile(field, row, column), nil}

                    true ->
                      {%Tile{type: :nothing}, nil}
                  end
                ]
            end
          )
        )
      end
    )
  end

  def get_tile(field, row, column) do
    field.tiles
    |> Enum.at(row - 1)
    |> Enum.at(column - 1)
  end

  def get_players() do
    GenServer.call(Game, :get_players)
  end

  @doc """
  This will remove the bear from the game, only use this when player is disconnected. It is a cast and will not return return anything.
  """
  def remove_bear(id) do
    GenServer.cast(Game, {:remove_bear, id})
  end

  defp spawn_trees() do
    all_x = Enum.to_list(0..40)
    all_y = Enum.to_list(0..40)

    create_tree(all_x, all_y)
  end

  defp create_tree(possible_x, possible_y, trees \\ []) do
    if Enum.count(trees) < @number_of_trees do
      x = Enum.random(possible_x)
      y = Enum.random(possible_y)
      tree = %Tree{pos_x: x, pos_y: y, honey: 1..15 |> Enum.to_list() |> Enum.random()}

      create_tree(possible_x -- [x], possible_y -- [y], [tree | trees])
    else
      trees
    end
  end

  def handle_info(pid, state) do
    {:noreply, state}
  end

  # def handle_info({:DOWN, _, :process, _, reason}, _) do
  #   {:stop, reason, []}
  # end
end
