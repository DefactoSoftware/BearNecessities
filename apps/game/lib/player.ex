defmodule Player do
  use GenServer
  require Logger

  defstruct [:display_name, :score, :bear]

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  @impl true
  def init([]) do
    {:ok, []}
  end

  @impl true
  def handle_call({:action, user_input, id}, _pid, _) do
    bear =
      case user_input do
        :up_arrow -> Bear.move(id, :up)
        :down_arrow -> Bear.move(id, :down)
        :left_arrow -> Bear.move(id, :left)
        :right_arrow -> Bear.move(id, :right)
        :space -> Bear.claw(id)
      end

    {:reply, bear, []}
  end

  def move(player_id, way) do
    GenServer.call(Player, {:action, way, player_id})
  end

  def start(display_name, id) do
    Player.start_link([])
    Game.create_bear(display_name: display_name, id: id, started: true)
  end
end
