defmodule Field do
  defstruct [:height, :width, :tiles]

  @textures %{
    grass: 4
  }

  def create_field(height, width) do
    tiles = create_tiles(height, width)

    %Field{
      height: height,
      width: width,
      tiles: tiles
    }
  end

  defp create_tiles(height, width) do
    Enum.map(1..height, fn _row ->
      Enum.map(1..width, fn _col ->
        create_tile(:grass)
      end)
    end)
  end

  defp create_tile(type) do
    texture_count = Map.get(@textures, type)

    %Tile{type: type, texture: :rand.uniform(texture_count)}
  end
end
