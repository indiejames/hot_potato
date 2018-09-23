defmodule HotPotato.Actions do
  alias HotPotato.Message
  import HotPotato.Util

  @moduledoc """
  Functions that take a game data map, perform an action, then return an updated game data map
  """

  # choose a player at random
  defp choose_player(players) do
    Enum.random(players)
  end

  @doc """
  Send joke/riddle in two parts (Question/Answer) to the channel
  """
  def tell_joke(game_data) do
    %{:jokes => jokes, :slack => slack, :channel => channel} = game_data
    joke = Enum.random(jokes)
    # send the setup
    Message.send_partial_joke(slack, channel, ~s(Q: #{joke["Q"]}))
    # send the punchline after a delay
    run_after_delay(3_000, fn ->
      Message.send_partial_joke(slack, channel, ~s(A: #{joke["A"]}))
    end)
    Map.put(game_data, :jokes, List.delete(jokes, joke))
  end

  @doc """
  Start the game
  """
  def start_game(game_data) do
    %{:slack => slack, :channel => channel} = game_data
    game_start_delay = Application.get_env(:hot_potato, :game_start_delay)
    Message.send_start_notice(slack, channel, game_start_delay)
    Map.put(game_data, :round, 0)
  end

  @doc """
  Show the countdown animation image and wait for a bit
  """
  def do_countdown(game_data) do
    %{:slack => slack, :channel => channel, :round => round} = game_data
    Message.send_round_countdown_message(slack, channel, round + 1)
    Image.send_countdown(channel)
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
      |> update_in([:players], &MapSet.put(&1, player_id))
      |> update_in([:live_players], &MapSet.put(&1, player_id))
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
      now = :os.system_time(:millisecond)
      Message.send_round_started_message(slack, channel, players, round)
      player_id_with_potato = choose_player(players)
      Message.send_player_has_potato_message(slack, channel, player_id_with_potato)

      game_data
      |> Map.put(:player_with_potato, player_id_with_potato)
      |> Map.put(:round, round)
      |> Map.put(:last_pass_time, now)
    end
  end

  # ehck to see if the bot pentaly has been paid
  defp bot_penalty_applies?(game_data) do
    now = :os.system_time(:millisecond)

    %{
      :last_pass_time => last_pass_time,
      :bot_penalty => bot_penalty
    } = game_data

    duration = now - last_pass_time
    IO.puts("duration = #{duration}")
    IO.puts("bot_penalty = #{bot_penalty}")
    now - last_pass_time < bot_penalty
  end

  # bot is attempting to pass the potato but hasn't waited long enough
  defp do_pass(game_data, from_player_id, _to_player_id, true) do
    now = :os.system_time(:millisecond)

    %{
      :slack => slack,
      :channel => channel
    } = game_data

    Message.send_bot_time_penalty(slack, channel, from_player_id)
    # reset the penalty time for the bot
    Map.put(game_data, :last_pass_time, now)
  end

  # penalty does not apply
  defp do_pass(game_data, _from_player_id, to_player_id, false) do
    now = :os.system_time(:millisecond)

    %{
      :slack => slack,
      :channel => channel
    } = game_data

    Message.send_player_has_potato_message(slack, channel, to_player_id)

    game_data
    |> Map.put(:player_with_potato, to_player_id)
    |> Map.put(:last_pass_time, now)
  end

  @doc """
  Pass the potato from one player to another
  """
  def pass(game_data, from_player_id, to_player_id) do
    %{
      :slack => slack,
      :channel => channel,
      :player_with_potato => player_with_potato,
      :live_players => players
    } = game_data

    IO.puts("pass() Line 140")

    do_penalty = game_data.users[from_player_id][:is_bot] && bot_penalty_applies?(game_data)
    IO.puts("do_penalty = #{do_penalty}")

    cond do
      # from user doesn't actually have the potato
      from_player_id != player_with_potato ->
        Message.send_warning(
          slack,
          channel,
          "<@#{from_player_id}>, you can't pass a potato you don't have!"
        )

        game_data

      # trying to pass to a user that isn't playing
      !MapSet.member?(players, to_player_id) ->
        Message.send_warning(
          slack,
          channel,
          "<@#{from_player_id}>, <@#{to_player_id}> is not playing!"
        )

        game_data

      # valid pass attempt
      true ->
        do_pass(game_data, from_player_id, to_player_id, do_penalty)
    end
  end

  @doc """
  Send a message that a player is dead and return an updated game_data with the player removed from
  the live players set
  """
  def kill_player(game_data) do
    %{
      :slack => slack,
      :channel => channel,
      :player_with_potato => player_id,
      :live_players => live_players,
      :dead_players => dead_players
    } = game_data

    Image.send_boom(channel)
    Message.send_player_out_message(slack, channel, player_id)

    new_live_players =
      live_players
      |> MapSet.delete(player_id)

    new_player_with_potato = choose_player(new_live_players)

    game_data
    |> Map.put(:player_with_potato, new_player_with_potato)
    |> Map.put(:live_players, new_live_players)
    |> Map.put(:dead_players, [player_id | dead_players])
  end

  @doc """
  Send a message announcing the winner of the game
  """
  def announce_winner(game_data) do
    # this is a little confusing beacuse it would seem like the player with the potato
    # would not be the winner, but in this case there is only one player and they
    # get handed the potato by the `kill_player` action when the second to last player
    # dies
    %{:slack => slack, :channel => channel, :player_with_potato => player_id, :users => users} =
      game_data

    Message.announce_winner(slack, channel, player_id)
    user_name = users[player_id][:name]
    Image.send_award(channel, Application.get_env(:hot_potato, :winner_award_image), user_name)
    game_data
  end

  defp announce_nth_place(game_data, message_fn, img_atom) do
    %{:slack => slack, :channel => channel, :dead_players => dead_players, :users => users} =
      game_data

    new_game_data = if Enum.count(dead_players) > 0 do
      [player_id | other_dead_players] = dead_players
      message_fn.(slack, channel, player_id)
      user_name = users[player_id][:name]

      Image.send_award(
        channel,
        Application.get_env(:hot_potato, img_atom),
        user_name
      )

      # remove the player from the list of dead players so other awards won't pick them up
      Map.put(game_data, :dead_players, other_dead_players)
    else
      game_data
    end

    new_game_data
  end

  @doc """
  Send a message announcing the second place player
  """
  def announce_second_place(game_data) do
    # %{:slack => slack, :channel => channel, :dead_players => dead_players, :users => users} =
    #   game_data
    # [player_id | other_dead_players] = dead_players
    # Message.announce_second_place(slack, channel, player_id)
    # user_name = users[player_id][:name]

    # Image.send_award(
    #   channel,
    #   Application.get_env(:hot_potato, :second_place_award_image),
    #   user_name
    # )

    # # remove the player from the list of dead players so other awards won't pick them up
    # Map.put(game_data, :dead_players, other_dead_players)
    announce_nth_place(game_data, &Message.announce_second_place/3, :second_place_award_image)
  end

  @doc """
  Send a message announcing the third place player
  """
  def announce_third_place(game_data) do
    announce_nth_place(game_data, &Message.announce_third_place/3, :third_place_award_image)
  end
end
