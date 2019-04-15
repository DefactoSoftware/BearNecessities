defmodule BearNecessitiesWeb.Playfield do
  use BearNecessitiesWeb, :view

  def terrain_class(tile) do
    case tile do
      :nothing -> "nothing"
      _ -> "grass-#{:rand.uniform(4)}"
    end
  end

  def sprite_class(tile, player_id) do
    case tile do
      %Bear{id: id, direction: direction} when id == player_id -> "bear self #{direction}"
      %Bear{} -> "bear opponent"
      %Tree{} -> "tree"
      _ -> nil
    end
  end
end
