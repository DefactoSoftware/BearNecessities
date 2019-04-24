defmodule GameServerTest do
  use ExUnit.Case

  test "greets the world" do
    GameServer.start_link([])
  end

  test "create_bear" do
    GameServer.start_link([])
    Player.start("fatboypunk", "phx-1")

    assert %Bear{
             clawing: false,
             dead: nil,
             direction: :down,
             display_name: "fatboypunk",
             honey: 10,
             id: "phx-1",
             moving: false,
             pos_x: 5,
             pos_y: 5,
             started: true
           } = GameServer.get_bear("phx-1")
  end

  describe "move_player" do
    setup do
      GameServer.start_link([])
      {player_pid, bear} = Player.start("fatboypunk", "phx-1")

      {:ok, player_pid: player_pid, bear: bear}
    end

    test "move to a working place", %{player_pid: player_pid} do
      Player.move(player_pid, "phx-1", :up_arrow)
    end

    test "create a viewport for the current position of the bear" do
      GenServer.call(GameServer, {:get_viewport, "phx-1"})
    end
  end
end
