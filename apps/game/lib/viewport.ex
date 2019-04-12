defmodule ViewPort do
  defstruct fields: []

  def get_viewport(id) do
    GenServer.call(Game, {:get_viewport, id})
  end
end
