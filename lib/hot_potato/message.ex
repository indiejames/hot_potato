defmodule HotPotato.Message do
  @messenger Application.get_env(:hot_potato, :messenger)

  @moduledoc """
  Provides functios to send messages for various games states to Slack
  """

  @doc """
  Send a setup or punchline to a joke
  """
  def send_partial_joke(slack, channel, text) do
    @messenger.send_text_message(text, channel, slack)
  end

  @doc """
  Send a notifcation to the channel that the game is going to start soon
  """
  def send_start_notice(slack, channel, wait_sec) do
    @messenger.send_text_message(
      "Hot Potato starting in #{wait_sec / 1000} seconds - message 'join' to play",
      channel,
      slack
    )
  end

  @doc """
  Send a notifcation to the channel that a player has joined the game
  """
  def send_join_notice(slack, channel, player_id) do
    @messenger.send_text_message("<@#{player_id}> has joined the game!", channel, slack)
  end

  @doc """
  Send a notification to the channel that a bot player tried to pass the potato to quickly
  """
  def send_bot_time_penalty(slack, channel, player_id) do
    @messenger.send_text_message(
      "Naughty <@#{player_id}>, don't be so hasty! You get a penalty.",
      channel,
      slack
    )
  end

  @doc """
  Warn a player using the given message
  """
  def send_warning(slack, channel, message) do
    @messenger.send_text_message("#{message} :warning:", channel, slack)
  end

  def send_round_countdown_message(slack, channel, round) do
    @messenger.send_text_message("Round #{round} starting in", channel, slack)
  end

  @doc """
  Send a notication to the channel that a game has started and show a list of the players
  """
  def send_round_started_message(slack, channel, player_ids, round) do
    player_list =
      player_ids
      |> Enum.to_list()
      |> Enum.map(&"<@#{&1}>")
      |> Enum.join(",")

    @messenger.send_text_message("Starting round #{round}!", channel, slack)
    @messenger.send_text_message("The players are #{player_list}", channel, slack)
  end

  @doc """
  Let the players know who has the potato
  """
  def send_player_has_potato_message(slack, channel, player_id) do
    @messenger.send_text_message("<@#{player_id}> has the potato", channel, slack)
  end

  @doc """
  Let the players know that one of them is dead/out
  """
  def send_player_out_message(slack, channel, player_id) do
    @messenger.send_text_message("<@#{player_id}> is out!", channel, slack)
  end

  @doc """
  Send a notice that potato has exploded
  """
  def send_boom(slack, channel) do
    @messenger.send_text_message("BOOM!!!", channel, slack)
  end

  @doc """
  Send a message announcing the winner of the game
  """
  def announce_winner(slack, channel, player_id) do
    @messenger.send_text_message("<@#{player_id}> is the winner!", channel, slack)
  end

  @doc """
  Send a message announcing the second place player
  """
  def announce_second_place(slack, channel, player_id) do
    @messenger.send_text_message("In second place - <@#{player_id}>!", channel, slack)
  end

  @doc """
  Send a message announcing the third place player
  """
  def announce_third_place(slack, channel, player_id) do
    @messenger.send_text_message("And in third place - <@#{player_id}>!", channel, slack)
  end
end
