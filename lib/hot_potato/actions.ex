defmodule HotPotato.Actions do
  alias HotPotato.Message

  @moduledoc """
  Functions that take a game_data map, perform an action, then return a new game game_data map
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

  # create a timer to signal when the potato explodes
  defp start_potato_timer(game_data) do
    %{:round => round, :players => players} = game_data
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
  end

  @doc """
  Start the game
  """
  def start_game(game_data) do
    %{:slack => slack, :channel => channel} = game_data
    game_start_delay = Application.get_env(:hot_potato, :game_start_delay)
    Message.send_start_notice(slack, channel, game_start_delay)

    # set a timer to begin the first round after players have joined
    run_after_delay(game_start_delay - 5_000, &HotPotato.StateManager.do_countdown/0)

     Map.put(game_data, :round, 0)
  end

  @doc """
  Show the countdown animation image and wait for a bit
  """
  def do_countdown(game_data) do
    %{:slack => slack, :channel => channel, :round => round} = game_data
    Message.send_round_countdown_message(slack, channel, round + 1)
    file = Application.get_env(:hot_potato, :countdown_image)
    file_name = Path.basename(file)
    Image.send_image(channel, file, file_name)
    run_after_delay(5_500, &HotPotato.StateManager.begin_round/0)

    game_data
  end

  @doc """
  Add a player
  """
  def add_player(game_data, player_id) do
    IO.puts("Adding player #{player_id}")
    %{:slack => slack, :channel => channel, :players => players} = game_data

    if !MapSet.member?(players, player_id) do
      Message.send_join_notice(slack, channel, player_id)

      game_data
      |> update_in([:players], &(MapSet.put(&1, player_id)))
      |> update_in([:live_players], &(MapSet.put(&1, player_id)))
    else
      Message.send_warning(slack, channel, "I heard you the first time, <@#{player_id}>")
      game_data
    end
  end

  @doc """
  Start a round of the game
  """
  def start_round(game_data) do
    %{:slack => slack, :channel => channel, :live_players => players, :round => round} = game_data
    round = round + 1
    IO.puts("Starting the round")
    if Enum.count(players) < 2 do
      Message.send_warning(slack, channel, "Not enough players, aborting game")
      game_data
    else
      Message.send_round_started_message(slack, channel, players, round)
      player_id_with_potato = choose_player(players)
      Message.send_player_has_potato_message(slack, channel, player_id_with_potato)
      # start a timer for the potato
      start_potato_timer(game_data)

      game_data
      |> Map.put(:player_with_potato, player_id_with_potato)
      |> Map.put(:round, round)
    end
  end

  @doc """
  Pass the potato from one player to another
  """
  def pass(game_data, from_user_id, to_player_id) do
    %{:slack => slack, :channel => channel, :player_with_potato => player_with_potato, :live_players => players} = game_data
    cond do
      from_user_id != player_with_potato ->
        Message.send_warning(slack, channel, "<@#{from_user_id}> you can't pass a potato you don't have!")
        game_data
      !MapSet.member?(players, to_player_id) ->
        Message.send_warning(slack, channel, "<@#{from_user_id}> <@#{to_player_id}> is not playing!")
        game_data
      true ->
        Message.send_player_has_potato_message(slack, channel, to_player_id)
        Map.put(game_data, :player_with_potato, to_player_id)
    end
  end

  @doc """
  Send a message that a player is dead and return an updated game_data with the player removed from
  the live players set
  """
  def kill_player(game_data) do
    %{:slack => slack, :channel => channel, :player_with_potato => player_id, :live_players => live_players} = game_data
    Image.send_boom(channel)
    Message.send_player_out_message(slack, channel, player_id)
    new_live_players = live_players
      |> MapSet.delete(player_id)
    new_player_with_potato = choose_player(new_live_players)

    game_data
      |> Map.put(:player_with_potato, new_player_with_potato)
      |> Map.put(:live_players, new_live_players)
      # this is slightly tricky, because this may not be the final round, but by the end of the
      # game the :second_place value in the game_data map will have the right user_id
      |> Map.put(:second_place, player_id)
  end

  @doc """
  Send a message announcing the winner of the game
  """
  def announce_winner(game_data) do
    # this is a little confusing beacuse it would seem like the player with the potato
    # would not be the winner, but in this case there is only one player and they
    # get handed the potato by the `kill_player` action when the second to last player
    # dies
    %{:slack => slack, :channel => channel, :player_with_potato => player_id, :users => users} = game_data
    Message.announce_winner(slack, channel, player_id)
    user_name = users[player_id][:name]
    Image.send_award(channel, Application.get_env(:hot_potato, :winner_award_image), user_name)
    run_after_delay(750, &HotPotato.StateManager.announce_second_place/0)
    game_data
  end

  @doc """
  Send a message announcing the second placer player
  """
  def announce_second_place(game_data) do
    %{:slack => slack, :channel => channel, :second_place => player_id, :users => users} = game_data
    Message.announce_second_place(slack, channel, player_id)
    user_name = users[player_id][:name]
    Image.send_award(channel, Application.get_env(:hot_potato, :second_place_award_image), user_name)
    game_data
  end
end
