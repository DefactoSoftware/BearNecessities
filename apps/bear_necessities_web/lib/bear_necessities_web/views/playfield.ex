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
      %Bear{id: id, direction: direction} when id == player_id -> "bear self #{direction}"
      %Bear{direction: direction} -> "bear opponent #{direction}"
      %Tree{} -> "tree"
      nil -> nil
    end
  end
end
