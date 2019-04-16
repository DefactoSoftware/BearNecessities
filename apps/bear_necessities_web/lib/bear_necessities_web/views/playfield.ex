defmodule BearNecessitiesWeb.Playfield do
  use BearNecessitiesWeb, :view

  def tile_class(tile) do
    case tile do
      %Tile{type: :grass, texture: texture} -> "grass-#{texture}"
      %Tile{type: :nothing} -> "nothing"
    end
  end

  def item_class(item, player_id) do
    case item do
      %Bear{id: id, direction: direction, moving: moving} when id == player_id ->
        ["bear", "self", direction]
        |> bear_idle_class(moving)
        |> Enum.join(" ")

      %Bear{direction: direction, moving: moving} ->
        ["bear", "opponent", direction]
        |> bear_idle_class(moving)
        |> Enum.join(" ")

      %Tree{} ->
        "tree"

      %HoneyDrop{} ->
        "honey"

      nil ->
        nil
    end
  end

  defp bear_idle_class(classes, false), do: ["idle" | classes]
  defp bear_idle_class(classes, _), do: classes
end
