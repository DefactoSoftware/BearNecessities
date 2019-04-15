defmodule BearNecessitiesWeb.Playfield do
  use BearNecessitiesWeb, :view

  defp terrain_class(tile) do
    case tile do
      :nothing -> "nothing"
      _ -> "grass"
    end
  end

  defp sprite_class(tile, player_id) do
    case tile do
      %Bear{id: id, direction: direction} when id == player_id -> "bear self #{direction}"
      %Bear{} -> "bear opponent"
      %Tree{} -> "tree"
      _ -> nil
    end
  end
end
