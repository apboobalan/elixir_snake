defmodule ElixirSnake.Scene.Game do
  use Scenic.Scene
  alias Scenic.ViewPort

  @game_over_scene ElixirSnake.Scene.GameOver
  # Initialize the game scene
  def init(_arg, opts) do
    viewport = opts[:viewport]

    state = ElixirSnake.Game.State.initial_state(viewport)

    {:ok, state, push: state |> update_graph()}
  end

  def handle_info(:frame, %{frame_count: frame_count} = state) do
    state = move_snake(state)

    {:noreply, %{state | frame_count: frame_count + 1}, push: state |> update_graph()}
  end

  # Update graph with score and objects.
  def update_graph(state) do
    state.graph
    |> ElixirSnake.Game.State.draw_score(state.score)
    |> ElixirSnake.Game.State.draw_objects(state.objects)
  end

  # Move the snake to its next position according to the direction. Also limits the size.
  defp move_snake(%{objects: %{snake: snake}} = state) do
    [head | _] = snake.body

    new_head_pos = head |> move_head(snake.direction) |> wrap_around_vp(state)

    new_body = [new_head_pos | snake.body] |> Enum.take(snake.size)

    put_in(state, [:objects, :snake, :body], new_body)
    |> maybe_eat_pellet(new_head_pos)
    |> maybe_end_game(new_head_pos)
  end

  defp move_head({pos_x, pos_y}, {vec_x, vec_y}) do
    {pos_x + vec_x, pos_y + vec_y}
  end

  def wrap_around_vp({x, y}, %{horizontal_tiles_count: h, vertical_tiles_count: v}) do
    # we add h and v before getting modulo to solve the negative case for pos_x and pos_y
    {(x + h) |> rem(h), (y + v) |> rem(v)}
  end

  # We're on top of a pellet! :)
  defp maybe_eat_pellet(state = %{objects: %{pellet: pellet_coords}}, snake_head_coords)
       when pellet_coords == snake_head_coords do
    state
    |> randomize_pellet()
    |> add_score()
    |> grow_snake()
  end

  # No pellet in sight. :(
  defp maybe_eat_pellet(state, _), do: state

  # Place the pellet somewhere in the map. It should not be on top of the snake.
  defp randomize_pellet(state = %{horizontal_tiles_count: w, vertical_tiles_count: h}) do
    pellet_coords = {
      Enum.random(0..(w - 1)),
      Enum.random(0..(h - 1))
    }

    state |> validate_pellet_coords(pellet_coords)
  end

  # Keep trying until we get a valid position
  defp validate_pellet_coords(state = %{objects: %{snake: %{body: snake}}}, coords) do
    if coords in snake,
      do: state |> randomize_pellet,
      else: state |> put_in([:objects, :pellet], coords)
  end

  # Increments the player's score.
  defp add_score(state = %{pellet_score: amount}) do
    state |> update_in([:score], &(&1 + amount)) |> update_in([:pellet_score], &(&1 + 1))
  end

  # Increments the snake size.
  defp grow_snake(state) do
    state
    |> update_in([:objects, :snake, :size], &(&1 + 1))
    |> increase_speed()
  end

  def increase_speed(state = %{timer: timer, frames_per_second: fps}) do
    timer |> :timer.cancel()
    {:ok, timer} = :timer.send_interval(trunc(1000 / (fps + 1)), :frame)
    %{state | timer: timer, frames_per_second: fps + 1}
  end

  def maybe_end_game(state = %{objects: %{snake: %{body: [_ | snake]}}}, coords) do
    if coords in snake,
      do: ViewPort.set_root(state.viewport, {@game_over_scene, state})

    state
  end

  def handle_input(
        {:key, {"up", :press, _}},
        _context,
        %{objects: %{snake: %{direction: {0, 1}}}} = state
      ) do
    {:noreply, state}
  end

  def handle_input({:key, {"up", :press, _}}, _context, state) do
    {:noreply, state |> change_snake_direction({0, -1})}
  end

  def handle_input(
        {:key, {"down", :press, _}},
        _context,
        %{objects: %{snake: %{direction: {0, -1}}}} = state
      ) do
    {:noreply, state}
  end

  def handle_input({:key, {"down", :press, _}}, _context, state) do
    {:noreply, state |> change_snake_direction({0, 1})}
  end

  def handle_input(
        {:key, {"left", :press, _}},
        _context,
        %{objects: %{snake: %{direction: {1, 0}}}} = state
      ) do
    {:noreply, state}
  end

  def handle_input({:key, {"left", :press, _}}, _context, state) do
    {:noreply, state |> change_snake_direction({-1, 0})}
  end

  def handle_input(
        {:key, {"right", :press, _}},
        _context,
        %{objects: %{snake: %{direction: {-1, 0}}}} = state
      ) do
    {:noreply, state}
  end

  def handle_input({:key, {"right", :press, _}}, _context, state) do
    {:noreply, state |> change_snake_direction({1, 0})}
  end

  def handle_input(_event, _context, state), do: {:noreply, state}

  def change_snake_direction(state, direction) do
    state |> put_in([:objects, :snake, :direction], direction)
  end
end
