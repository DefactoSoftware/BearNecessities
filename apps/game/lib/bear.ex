defmodule Bear do
  defstruct id: nil, pos_x: nil, pos_y: nil, honey: nil, display_name: nil, started: false

  def create_bear(%{height: height, width: width}, id, display_name, started) do
    pos_x = Enum.random(0..height)
    pos_y = Enum.random(0..width)

    %Bear{
      id: id,
      pos_x: pos_x,
      pos_y: pos_y,
      honey: 10,
      display_name: display_name,
      started: started
    }
  end

  @doc """
  Tries to the bear a positon, up, left, down or right.
  The game will decide if the action is permitted and returns the
  actual state of the bear.
  """
  def move(id, action) do
    id
    |> Game.get_bear()
    |> _move(action)
  end

  defp _move(bear, :up), do: Game.move(bear, to: {bear.pos_x + 1, bear.pos_y})
  defp _move(bear, :down), do: Game.move(bear, to: {bear.pos_x - 1, bear.pos_y})
  defp _move(bear, :left), do: Game.move(bear, to: {bear.pos_x, bear.pos_y - 1})
  defp _move(bear, :right), do: Game.move(bear, to: {bear.pos_x, bear.pos_y + 1})

  def claw(bear) do
    Game.claw(bear)
  end
end
