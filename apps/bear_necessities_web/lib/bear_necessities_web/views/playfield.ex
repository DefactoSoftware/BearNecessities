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
      %Bear{id: id, direction: direction, moving: moving, clawing: clawing, dead: nil} = bear
      when id == player_id ->
        ["bear", "self", direction]
        |> bear_action_class(moving, clawing)
        |> Enum.join(" ")

      %Bear{id: id, direction: direction, dead: _} when id == player_id ->
        "bear dead"

      %Bear{direction: direction, moving: moving, clawing: clawing, dead: nil} ->
        ["bear", "opponent", direction]
        |> bear_action_class(moving, clawing)
        |> Enum.join(" ")

      %Bear{direction: direction, dead: _dead} ->
        "bear opponent dead"

      %Bee{} ->
        "bee"

      %Tree{hive: %Hive{}} ->
        "tree hive"

      %Tree{} ->
        "tree"

      %HoneyDrop{} ->
        "honey"

      nil ->
        nil
    end
  end

  defp bear_action_class(classes, false, false), do: ["idle" | classes]
  defp bear_action_class(classes, _, true), do: ["clawing" | classes]
  defp bear_action_class(classes, _, _), do: classes
end
