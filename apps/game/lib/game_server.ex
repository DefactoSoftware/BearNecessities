defmodule Game do
  use GenServer

  @vertical_view_distance 5
  @horizontal_view_distance 5
  @number_of_trees 20
  @max_honey_drops 8
  @field_height 40
  @field_width 40
  @miliseconds_dead_screen 2900

  defstruct [:field, :bears, :bees, :trees, :honey_drops]

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  @impl true
  def init([]) do
    field = Field.create_field(@field_height, @field_width)
    :timer.send_interval(3000, self(), :spawn_honey)

    game = %Game{
      field: field,
      bears: [],
      bees: [],
      honey_drops: [],
      trees: spawn_trees()
    }

    {:ok, game}
  end

  @impl true
  def handle_info(:spawn_honey, %{honey_drops: honey_drops} = state) do
    new_honey_drops =
      if Enum.count(honey_drops) < @max_honey_drops do
        spawn_honey_drop(state)
      else
        honey_drops
      end

    {:noreply, %{state | honey_drops: new_honey_drops}}
  end

  defp spawn_honey_drop(%{honey_drops: honey_drops, trees: trees}) do
    all_x = Enum.map(honey_drops ++ trees, & &1.pos_x)
    all_y = Enum.map(honey_drops ++ trees, & &1.pos_y)
    potential_x = Enum.to_list(0..@field_height) -- all_x
    potential_y = Enum.to_list(0..@field_width) -- all_y

    [
      %HoneyDrop{
        honey: Enum.random([1, 3, 5, 7]),
        pos_x: Enum.random(potential_x),
        pos_y: Enum.random(potential_y)
      }
      | honey_drops
    ]
  end

  @impl true
  def handle_call(
        {:get_viewport, id},
        _pid,
        %{bears: bears} = state
      ) do
    case get_bear_from_list(id, bears) do
      %{pos_x: x, pos_y: y} ->
        position = {x, y}
        viewport = create_viewport(position, state)
        {:reply, viewport, state}

      nil ->
        {:reply, [], state}
    end
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
        %{honey_drops: honey_drops} = state
      ) do
    bear = %{bear | direction: direction, moving: true}

    {bear, honey_drops} =
      if move_to?(position, id, state) do
        {bear, honey_drops} = fetch_honey_drop(bear, position, honey_drops)
        bear = %{bear | pos_x: pos_x, pos_y: pos_y}
        {bear, honey_drops}
      else
        {bear, honey_drops}
      end

    state = update_state_with(state, bear)

    {:reply, bear, %{state | honey_drops: honey_drops}}
  end

  @impl true
  def handle_call({:stop, id}, _pid, %{bears: bears} = state) do
    bear = get_bear_from_list(id, bears)
    bear = %{bear | moving: false, clawing: false}
    state = update_state_with(state, bear)

    {:reply, bear, state}
  end

  @impl true
  def handle_call(
        {:claw, %Bear{honey: bear_honey, direction: direction, pos_x: x, pos_y: y} = bear},
        _pid,
        state
      ) do
    bear = %{bear | clawing: true}

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
          other_bear = %{other_bear | honey: other_bear_honey - 1}

          other_bear =
            if other_bear.honey < 1,
              do: %{other_bear | dead: @miliseconds_dead_screen},
              else: other_bear

          new_state =
            state
            |> update_state_with(new_bear)
            |> update_state_with(other_bear)

          {new_bear, new_state}

        %Tree{honey: 0} ->
          {bear, update_state_with(state, bear)}

        %Bear{honey: 0} ->
          {bear, update_state_with(state, bear)}

        _ ->
          {bear, update_state_with(state, bear)}
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
    bears = Enum.sort(bears, &(&1.honey >= &2.honey))

    {:reply, bears, state}
  end

  @impl true
  def handle_call({:try_to_sting, bee}, _, %{bears: bears} = state) do
    stung = false

    bears =
      Enum.map(bears, fn bear ->
        if next_to_bee?(bee, bear) do
          stung = true
          bear = %{bear | honey: bear.honey - 1}
        else
          bear
        end
      end)

    {:reply, stung, %{state | bears: bears}}
  end

  @impl true
  def handle_cast({:move_bee, bee, directions}, state) do
    {x, y} =
      Enum.find(directions, fn direction ->
        direction
        |> position_for_direction(bee)
        |> move_to?(bee.id, state)
      end)
      |> position_for_direction(bee)

    state = update_state_with(state, %{bee | pos_x: x, pos_y: y})

    {:noreply, state}
  end

  def position_for_direction(:up, %{pos_x: pos_x, pos_y: pos_y}), do: {pos_x - 1, pos_y}
  def position_for_direction(:down, %{pos_x: pos_x, pos_y: pos_y}), do: {pos_x + 1, pos_y}
  def position_for_direction(:right, %{pos_x: pos_x, pos_y: pos_y}), do: {pos_x, pos_y + 1}
  def position_for_direction(:left, %{pos_x: pos_x, pos_y: pos_y}), do: {pos_x, pos_y - 1}
  def position_for_direction(nil, %{pos_x: pos_x, pos_y: pos_y}), do: {pos_x, pos_y}

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

  def update_state_with(%{bees: bees} = state, bee = %Bee{}) do
    bees =
      Enum.map(bees, fn list_bee ->
        if list_bee.id == bee.id,
          do: bee,
          else: list_bee
      end)

    %{state | bees: bees}
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

  defp move_to?(position, id, %{trees: trees, bears: bears, bees: bees, field: field}) do
    id_bees =
      Task.async(fn ->
        not Enum.any?(bees, fn bee -> {bee.pos_x, bee.pos_y} == position and bee.id != id end)
      end)

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

    Task.await(id_bees) and Task.await(id_bears) and Task.await(id_trees) and
      pos_within_field?(position, field)
  end

  defp fetch_honey_drop(%{honey: honey} = bear, position, honey_drops) do
    with %HoneyDrop{honey: dropped_honey} = honey_drop <-
           Enum.find(honey_drops, fn honey_drop ->
             {honey_drop.pos_x, honey_drop.pos_y} == position
           end) do
      new_bear = %{bear | honey: honey + dropped_honey}
      new_honey_drops = honey_drops -- [honey_drop]

      {new_bear, new_honey_drops}
    else
      nil ->
        {bear, honey_drops}
    end
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

  def create_viewport({bear_x, bear_y} = position, %Game{
        field: field,
        bears: bears,
        trees: trees,
        honey_drops: honey_drops
      }) do
    bears_task = get_from_list_task(position, bears)
    trees_task = get_from_list_task(position, trees)
    honey_drops_task = get_from_list_task(position, honey_drops)

    list = Task.await(bears_task) ++ Task.await(trees_task) ++ Task.await(honey_drops_task)

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

  defp nest_to_bee?(%Bee{pos_x: pos_x, pos_y: pos_y}, %{pos_x: bx, pos_y: by})
       when (pos_x == bx - 1 and pos_y == by) or
              (pos_x == bx + 1 and pos_y == by) or
              (pos_x == bx and pos_y == by - 1) or
              (pos_x == bx and pos_y == by + 1),
       do: true

  defp next_to_bee?(_, bear), do: false

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

  @doc """
  creates a tree on and returns a list of trees
  """
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
end
