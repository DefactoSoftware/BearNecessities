defmodule Bear do
  defstruct id: nil,
            pos_x: nil,
            pos_y: nil,
            dead: nil,
            honey: nil,
            display_name: nil,
            started: false,
            direction: :down,
            moving: false,
            clawing: false

  def create_bear(%{height: height, width: width}, id, display_name, started) do
    pos_x = Enum.random(0..height)
    pos_y = Enum.random(0..width)

    %Bear{
      id: id,
      pos_x: 5,
      pos_y: 5,
      honey: 10,
      display_name: display_name,
      started: started
    }
  end

  @doc """
  Tries to change the position of a bear , up, left, down or right.
  The game will decide if the action is permitted and returns the
  actual state of the bear.
  """
  def move(id, action) do
    id
    |> GameServer.get_bear()
    |> _move(action)
  end

  defp _move(bear, :down), do: GameServer.move(bear, :down, to: {bear.pos_x + 1, bear.pos_y})
  defp _move(bear, :up), do: GameServer.move(bear, :up, to: {bear.pos_x - 1, bear.pos_y})
  defp _move(bear, :left), do: GameServer.move(bear, :left, to: {bear.pos_x, bear.pos_y - 1})
  defp _move(bear, :right), do: GameServer.move(bear, :right, to: {bear.pos_x, bear.pos_y + 1})

  def stop(id) do
    GenServer.call(GameServer, {:stop, id})
  end

  def claw(id) do
    id
    |> GameServer.get_bear()
    |> GameServer.claw()
  end
end
