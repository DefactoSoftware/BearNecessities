defmodule Player do
  use GenServer
  require Logger

  @default_actions %{
    "ArrowUp" => "up",
    "ArrowDown" => "down",
    "ArrowLeft" => "left",
    "ArrowRight" => "right"
  }

  defstruct actions: @default_actions

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  @impl true
  def init(opts \\ %{}) do
    {:ok, %Player{}}
  end

  @impl true
  def handle_call({:update_movement, key, direction}, _pid, %{actions: actions} = state) do
    actions = Map.update(actions, key, "up", fn _ -> direction end)
    {:reply, actions, %{state | actions: actions}}
  end

  @impl true
  def handle_call({:action, user_input, id}, _pid, %{actions: actions} = state) do
    bear =
      case Map.get(actions, user_input) do
        "up" -> Bear.move(id, :up)
        "down" -> Bear.move(id, :down)
        "left" -> Bear.move(id, :left)
        "right" -> Bear.move(id, :right)
        :space -> Bear.claw(id)
        _ -> Game.get_bear(id)
      end

    {:reply, bear, state}
  end

  def move(player_id, pid, key) do
    GenServer.call(pid, {:action, key, player_id})
  end

  def setup_player() do
    case Player.start_link([]) do
      {:error, {:already_started, pid}} -> pid
      pid -> pid
    end
  end

  def start(display_name, id, opts \\ %{}) do
    Game.create_bear(display_name: display_name, id: id, started: true)
  end

  def set_setting("false"), do: "up"
  def set_setting("up"), do: "down"
  def set_setting("down"), do: "left"
  def set_setting("left"), do: "right"
  def set_setting("right"), do: false

  def update_movement(pid, key, direction) do
    GenServer.call(pid, {:update_movement, key, direction})
    set_setting(direction)
  end
end
