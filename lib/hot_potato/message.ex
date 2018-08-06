defmodule HotPotato.Message do
  use Slack

  @moduledoc """
  Provides functios to send messages for various games states to Slack
  """

  @doc """
  Send a notifcation to the channel that the game is going to start soon
  """
  def send_start_notice(slack, channel) do
    send_message("Hot Potato starting in 30 seconds - message 'join' to play", channel, slack)
  end

   @doc """
  Send a notifcation to the channel that the game has started
  """
  def send_started_notice(slack, channel) do
    send_message("Begin!", channel, slack)
  end

  @doc """
  Send a notifcation to the channel that a player has joined the game
  """
  def send_join_notice(slack, channel, player_id) do
    send_message("<@#{player_id}> has joined the game!", channel, slack)
  end

  @doc """
  Warn a player using the given message
  """
  def send_warning(slack, channel, message) do
    send_message("#{message} :warning:", channel, slack)
  end

  @doc """
  Send a notication to the channel that a game has started and show a list of the players
  """
  def send_start_message(slack, channel, player_ids) do
    player_list = player_ids
    |> Enum.to_list()
    |> Enum.map(&("<@#{&1}>"))
    |> Enum.join(",")
    send_message("The has started!", channel, slack)
    send_message("The players are #{IO.inspect(player_list)}", channel, slack)
  end
end
