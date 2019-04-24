defmodule ViewPort do
  defstruct fields: []

  def get_viewport(id) do
    GenServer.call(GameServer, {:get_viewport, id})
  end
end
