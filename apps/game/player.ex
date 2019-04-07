defmodule Player do
  use GenServer

  defstruct [:display_name, :score, :bear]

  def init(display_name: display_name) do
    Game.call(self, {:create_bear, display_name: display_name})
    :ok
  end

  def handle_call({:action, user_input}, _, ) do

    case user_input do
      :up_arrow -> Bear.move_bear(self, :up)
      :down_arrow -> Bear.move_bear(self, :down)
      :left_arrow -> Bear.move_bear(self, :left)
      :right_arrow -> Bear.move_bear(self, :right)
      :space -> Bear.claw(self)
    end
  end

  def handle_call(:map_update, _) do
  end
end
