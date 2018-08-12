defmodule HotPotato.Actions do
  alias HotPotato.Message

  @moduledoc """
  Functions that take a state, perform an action, then return a new game state
  """

  # choose a player at random
  defp choose_player(players) do
    Enum.random(players)
  end

  # run a function after the given delay (in msec)
  defp run_after_delay(delay, fun) do
    spawn(fn ->
      receive do
        {:not_gonna_happen, msg}  -> msg
        after
          delay -> fun.()
        end
    end)
  end

  # create a timer to signal when the paotato explodes
  defp start_potato_timer(state) do
    %{:round => round, :players => players} = state
    player_count = Enum.count(players)
    min_potato_fuse_time = Application.get_env(:hot_potato, :min_potato_fuse_time)
    duration = System.get_env("FUSE_TIME") || "30"
    {duration, _} = Integer.parse(duration)
    duration = duration * (1 - ((round - 1) / player_count)) * 1_000
    duration = duration + :rand.normal(0, 0.1) * duration
    duration = if duration < min_potato_fuse_time, do: min_potato_fuse_time, else: duration
    duration = Kernel.trunc(duration)
    IO.puts(duration)
    run_after_delay(duration, &HotPotato.StateManager.explode/0)
    # spawn(fn ->
    #   receive do
    #     {:not_gonna_happen, msg}  -> msg
    #     after
    #       duration -> HotPotato.StateManager.explode()
    #     end
    # end)
  end

  @doc """
  Start the game
  """
  def start_game(state) do
    %{:slack => slack, :channel => channel} = state
    game_start_delay = Application.get_env(:hot_potato, :game_start_delay)
    Message.send_start_notice(slack, channel, game_start_delay)

    # set a timer to begin the first round after players have joined
    spawn(fn ->
      receive do
        {:not_gonna_happen, msg}  -> msg
        after
          (game_start_delay - 5_000) -> HotPotato.StateManager.do_countdown()
        end
    end)

     state
     |> Map.put(:round, 0)
     |> Map.put(:countdown, 5)
  end

  def do_countdown(state) do
    %{:channel => channel} = state
    file = Application.get_env(:hot_potato, :countdown_image)
    file_name = Path.basename(file)
    Image.send_image(channel, file, file_name)
    run_after_delay(5_500, &HotPotato.StateManager.begin_round/0)

    state
  end

  @doc """
  Add a player
  """
  def add_player(state, player_id) do
    IO.puts("Adding player")
    %{:slack => slack, :channel => channel, :players => players} = state

    if !MapSet.member?(players, player_id) do
      Message.send_join_notice(slack, channel, player_id)

      state
      |> update_in([:players], &(MapSet.put(&1, player_id)))
      |> update_in([:live_players], &(MapSet.put(&1, player_id)))
    else
      Message.send_warning(slack, channel, "I heard you the first time, <@#{player_id}>")
      state
    end
  end

  @doc """
  Start a round of the game
  """
  def start_round(state) do
    %{:slack => slack, :channel => channel, :live_players => players, :round => round} = state
    round = round + 1
    IO.puts("Starting the round")
    if Enum.count(players) < 2 do
      Message.send_warning(slack, channel, "Not enough players, aborting game")
      state
    else
      Message.send_round_started_message(slack, channel, players)
      player_id_with_potato = choose_player(players)
      Message.send_player_has_potato_message(slack, channel, player_id_with_potato)
      # start a timer for the potato
      start_potato_timer(state)

      state
      |> Map.put(:player_with_potato, player_id_with_potato)
      |> Map.put(:round, round)
    end
  end

  @doc """
  Pass the potato from one player to another
  """
  def pass(state, from_user_id, to_player_id) do
    %{:slack => slack, :channel => channel, :player_with_potato => player_with_potato, :live_players => players} = state
    cond do
      from_user_id != player_with_potato ->
        Message.send_warning(slack, channel, "<@#{from_user_id}> you can't pass a potato you don't have!")
        state
      !MapSet.member?(players, to_player_id) ->
        Message.send_warning(slack, channel, "<@#{from_user_id}> <@#{to_player_id}> is not playing!")
        state
      true ->
        Message.send_player_has_potato_message(slack, channel, to_player_id)
        Map.put(state, :player_with_potato, to_player_id)
    end
  end

  @doc """
  Send a message that a player is dead and return an updated state with the player removed from
  the live players set
  """
  def kill_player(state) do
    %{:slack => slack, :channel => channel, :player_with_potato => player_id, :live_players => live_players} = state
    Image.send_boom(channel)
    Message.send_player_out_message(slack, channel, player_id)
    new_live_players = live_players
      |> MapSet.delete(player_id)
    new_player_with_potato = choose_player(new_live_players)

    state
      |> Map.put(:player_with_potato, new_player_with_potato)
      |> Map.put(:live_players, new_live_players)
  end

  @doc """
  Send a message announcing the winner of the game
  """
  def announce_winner(state) do
    %{:slack => slack, :channel => channel, :player_with_potato => player_id} = state
    Message.announce_winner(slack, channel, player_id)
    state
  end
end
