defmodule GameTest do
  use ExUnit.Case

  test "greets the world" do
    Game.start_link([])
  end

  test "create_bear" do
    Game.start_link([])
    {:ok, player} = Player.start_link([])
    Player.start("fatboypunk")
  end

  describe "move_player" do
    setup do
      Game.start_link([])
      {:ok, player} = Player.start_link([])
      Player.start("fatboypunk")

      {:ok, player: player}
    end

    test "move to a working place", %{player: player} do
      Player.move(player, :up_arrow)
    end
  end
end
