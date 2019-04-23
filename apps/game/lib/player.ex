defmodule Player do
  use GenServer
  require Logger

  @claw_time_ms 1000

  @enforce_keys [:id]
  defstruct [:id, :claw, :timer_pid]

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  @impl true
  def init(id: id) do
    {:ok, %Player{id: id}}
  end

  @impl true
  def handle_call({:action, user_input, id}, _pid, state) do
    bear =
      case user_input do
        :up_arrow ->
          Bear.move(id, :up)

        :down_arrow ->
          Bear.move(id, :down)

        :left_arrow ->
          Bear.move(id, :left)

        :right_arrow ->
          Bear.move(id, :right)
      end

    {:reply, bear, state}
  end

  @impl true
  def handle_call({:claw, id}, _pid, state) do
    bear = Bear.claw(id)
    {:ok, timer_pid} = :timer.send_interval(50, self(), :update_claw)
    state = %{state | claw: @claw_time_ms, timer_pid: timer_pid}

    {:reply, bear, state}
  end

  @impl true
  def handle_info(:update_claw, %{claw: nil} = state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(:update_claw, %{claw: claw_time} = state) when claw_time > 0 do
    state = %{state | claw: claw_time - 50}

    {:noreply, state}
  end

  @impl true
  def handle_info(:update_claw, %{id: id, claw: claw_time, timer_pid: timer_pid} = state)
      when claw_time < 1 do
    :timer.cancel(timer_pid)
    state = %{state | claw: nil, timer_pid: nil}
    Bear.stop(id)

    {:noreply, state}
  end

  @impl true
  def handle_info(:update_claw, state) do
    {:noreply, state}
  end

  def move(player_id, way) do
    GenServer.call(Player, {:action, way, player_id})
  end

  def claw(player_id) do
    GenServer.call(Player, {:claw, player_id})
  end

  def start(display_name, id) do
    Player.start_link(id: id)
    Game.create_bear(display_name: display_name, id: id, started: true)
  end
end
