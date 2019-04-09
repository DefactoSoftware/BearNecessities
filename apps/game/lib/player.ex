defmodule Player do
  use GenServer

  defstruct [:display_name, :score, :bear]

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default)
  end

  @impl true
  def init([]) do
    {:ok, []}
  end

  @impl true
  def handle_call({:action, user_input}, pid, _) do
    bear =
      case user_input do
        :up_arrow -> Bear.move(pid, :up)
        :down_arrow -> Bear.move(pid, :down)
        :left_arrow -> Bear.move(pid, :left)
        :right_arrow -> Bear.move(pid, :right)
        :space -> Bear.claw(pid)
      end

    {:reply, bear, []}
  end

  def move(player, way) do
    GenServer.call(player, {:action, way})
  end

  def start(display_name) do
    Game.create_bear(display_name: display_name)
  end
end
