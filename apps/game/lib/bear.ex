defmodule Bear do
  defstruct [:pid, :pos_x, :pos_y, :honey, :display_name]

  def create_bear(%{height: height, width: width}, pid, display_name) do
    pos_x = Enum.random(0..height)
    pos_y = Enum.random(0..width)
    %Bear{pid: pid, pos_x: pos_x, pos_y: pos_y, honey: 10, display_name: display_name}
  end

  def move(pid, action) do
    bear = Game.get_bear(pid)
    _move(bear, action)
  end

  defp _move(bear, :up), do: Game.move(bear, to: {bear.pos_x + 1, bear.pos_y})
  defp _move(bear, :down), do: Game.move(bear, to: {bear.pos_x - 1, bear.pos_y})
  defp _move(bear, :left), do: Game.move(bear, to: {bear.pos_x, bear.pos_y - 1})
  defp _move(bear, :right), do: Game.move(bear, to: {bear.pos_x, bear.pos_y - 1})

  def claw(bear) do
    Game.claw(bear)
  end
end
