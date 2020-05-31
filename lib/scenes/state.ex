defmodule ElixirSnake.Game.State do
  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives, only: [rrect: 3, text: 3]

  @graph Graph.build(font: :roboto, font_size: 36)
  @tile_size 20
  @snake_starting_size 5
  @tile_radius 8
  @frames_per_second 10
  @snake_color :lime
  @pellet_color :yellow
  @pellet_score 1

  def initial_state(viewport) do
    # Get viewport width and height
    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(viewport)

    # Split viewport into tiles using tile_size
    horizontal_tiles_count = trunc(vp_width / @tile_size)
    vertical_tiles_count = trunc(vp_height / @tile_size)

    # Snake starting tile. It is placed at center.
    snake_start_tile = {trunc(horizontal_tiles_count / 2), trunc(vertical_tiles_count / 2)}

    pellet_start_coords = {
      horizontal_tiles_count - 2,
      trunc(vertical_tiles_count / 2)
    }

    # Initialize time.
    {:ok, timer} = :timer.send_interval(trunc(1000 / @frames_per_second), :frame)

    # The entire game state will be held here
    %{
      viewport: viewport,
      horizontal_tiles_count: horizontal_tiles_count,
      vertical_tiles_count: vertical_tiles_count,
      graph: @graph,
      score: 0,
      timer: timer,
      frame_count: 1,
      frames_per_second: @frames_per_second,
      pellet_score: @pellet_score,
      objects: %{
        snake: %{body: [snake_start_tile], size: @snake_starting_size, direction: {1, 0}},
        pellet: pellet_start_coords
      }
    }
  end
  # Draw Score.
  def draw_score(graph, score) do
    graph
    |> text("Score: #{score}",
      fill: :white,
      translate: {2 * @tile_size, 2 * @tile_size},
      id: :score
    )
  end

  # Draw game objects.
  def draw_objects(graph, objects) do
    objects
    |> Enum.reduce(graph, fn {type, value}, graph ->
      graph |> draw_object(type, value)
    end)
  end

  # Draw individual objects.
  def draw_object(graph, :snake, %{body: body}) do
    body
    |> Enum.reduce(graph, fn {x, y}, graph ->
      graph |> draw_tile(x * @tile_size, y * @tile_size, @snake_color)
    end)
  end

  def draw_object(graph, :pellet, {x, y}) do
    graph |> draw_tile(x * @tile_size, y * @tile_size, @pellet_color)
  end

  # Draw tiles of game objects.
  def draw_tile(graph, x, y, color) do
    graph |> rrect({@tile_size, @tile_size, @tile_radius}, fill: color, translate: {x, y})
  end

end
