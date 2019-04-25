defmodule Bee do
  use Genserver

  @enforce_keysa(:pos_x, :pos_y)
  defstruct(:pos_x, :pos_y)

  def start_link([pos_x: _, pos_y: _] = args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init([pos_x: x, pos_y: y] = args) do
    :timer.send_interval(100, self(), :update)
    {:ok, %Bee{pos_x: x, pos_y: y}}
  end

  @impl true
  def handle_info({:update}, %{pos_x: pos_x, pos_y: pos_y} = bee) do
    GenServer.call(Game, {:get_viewport, {pos_x, pos_y}})
    # move to closest bear

    updated_bee = GenServer.call(Game, {:move_bee, bee, direction})
    {:noreply, updated_bee}
  end
end
