defmodule GameTest do
  use ExUnit.Case

  test "greets the world" do
    Game.start_link([])
  end

  test "create_bear" do
    Game.start_link([])
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
           } = Game.get_bear("phx-1")
  end

  describe "move_player" do
    setup do
      Game.start_link([])
      {player_pid, bear} = Player.start("fatboypunk", "phx-1")

      {:ok, player_pid: player_pid, bear: bear}
    end

    test "move to a working place", %{player_pid: player_pid} do
      Player.move(player_pid, "phx-1", :up_arrow)
    end
  end

  describe "#try_to_sting/2" do
    test "the bee successfully stings the bear when next to it" do
      bee = %Bee{id: "bee-1", pos_x: 2, pos_y: 3}
      bear = %Bear{id: "bear-1", pos_x: 3, pos_y: 3, honey: 10}

      assert [%Bear{honey: 9}] = Bee.try_to_sting(bee, [bear])
    end

    test "the bee is unsuccessful when diagonal from a bear" do
      bee = %Bee{id: "bee-1", pos_x: 4, pos_y: 4}
      bear = %Bear{id: "bear-1", pos_x: 3, pos_y: 3, honey: 10}

      assert [%Bear{honey: 10}] = Bee.try_to_sting(bee, [bear])
    end
  end
end
