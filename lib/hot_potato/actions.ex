defmodule HotPotato.Actions do
  alias HotPotato.Message

  @game_start_delay 5_000 # time players have to join a new game (msec)
  @min_potato_fuse_time 5_000

  @moduledoc """
  Functions that take a state, perform an action, then return a new game state
  """

  # choose a player at random
  defp choose_player(players) do
    Enum.random(players)
  end

  # create a timer to signal when the paotato explodes
  defp start_potato_timer(state) do
    %{:round => round, :players => players} = state
    player_count = Enum.count(players)
    duration = System.get_env("AVG_FUSE_TIME") || "10"
    {duration, _} = Integer.parse(duration)
    duration = duration * (1 - ((round - 1) / player_count)) * 1_000
    duration = duration + :rand.normal(0, 0.1) * duration
    duration = if duration < @min_potato_fuse_time, do: @min_potato_fuse_time, else: duration
    duration = Kernel.trunc(duration)
    IO.puts(duration)
    spawn(fn ->
      receive do
        {:not_gonna_happen, msg}  -> msg
        after
          duration -> HotPotato.StateManager.explode()
        end
    end)
  end

  @doc """
  Start the game
  """
  def start_game(state) do
    %{:slack => slack, :channel => channel} = state
    Message.send_start_notice(slack, channel, @game_start_delay)

      # set a timer to begin the first round after players have joined
      # :timer.apply_after(@game_start_delay, HotPotato.StateManager, HotPotato.StateManager.begin_round, [])
      spawn(fn ->
        receive do
          {:not_gonna_happen, msg}  -> msg
          after
            @game_start_delay -> HotPotato.StateManager.begin_round()
          end
      end)

     Map.put(state, :round, 0)
  end

  @doc """
  Add a player
  """
  def add_player(state, player_id) do
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

  def pass(state, player_id) do
    # TODO validate that the player is in the live players list
    %{:slack => slack, :channel => channel} = state
    Message.send_player_has_potato_message(slack, channel, player_id)
    Map.put(state, :player_with_potato, player_id)
  end

  @doc """
  Send a message that a player is dead and return an updated state with the player removed from
  the live players set
  """
  def kill_player(state) do
    %{:slack => slack, :channel => channel, :player_with_potato => player_id, :live_players => live_players} = state
    Message.send_boom(slack, channel)
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
