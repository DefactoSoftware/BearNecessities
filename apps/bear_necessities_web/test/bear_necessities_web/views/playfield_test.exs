defmodule BearNecessitiesWeb.PlayfieldTest do
  use BearNecessitiesWeb.ConnCase
  import Phoenix.LiveViewTest

  test "Start with a player name", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "What is Your Name?"

    {:ok, view, _html} = live(conn)

    template = render_submit(view, "start", %{player: %{display_name: "PhoenixPlayer"}})

    assert template =~ "<h1>Hello, PhoenixPlayer</h1>"
    assert template =~ "<span>X: 5</span>"
    assert template =~ "<span>Y: 5</span>"
  end

  test "move the player up", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "What is Your Name?"

    {:ok, view, _html} = live(conn)

    render_submit(view, "start", %{player: %{display_name: "PhoenixPlayer"}})
    template = render_keydown(view, "key_move", %{"key" => "ArrowUp"})

    assert template =~ "<span>X: 4</span>"
    assert template =~ "<span>Y: 5</span>"
  end

  test "move the player down", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "What is Your Name?"

    {:ok, view, _html} = live(conn)

    render_submit(view, "start", %{player: %{display_name: "PhoenixPlayer"}})
    template = render_keydown(view, "key_move", %{"key" => "ArrowDown"})

    assert template =~ "<span>X: 6</span>"
    assert template =~ "<span>Y: 5</span>"
  end

  test "move the player left", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "What is Your Name?"

    {:ok, view, _html} = live(conn)

    render_submit(view, "start", %{player: %{display_name: "PhoenixPlayer"}})
    template = render_keydown(view, "key_move", %{"key" => "ArrowLeft"})

    assert template =~ "<span>X: 5</span>"
    assert template =~ "<span>Y: 4</span>"
  end

  test "move the player right", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "What is Your Name?"

    {:ok, view, _html} = live(conn)

    render_submit(view, "start", %{player: %{display_name: "PhoenixPlayer"}})
    template = render_keydown(view, "key_move", %{"key" => "ArrowRight"})

    assert template =~ "<span>X: 5</span>"
    assert template =~ "<span>Y: 6</span>"
  end
end
