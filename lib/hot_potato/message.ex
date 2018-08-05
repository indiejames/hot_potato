defmodule HotPotato.Message do
  use Slack

  @moduledoc """
  Provides functios to send messages for various games states to Slack
  """

  def send_start_notice(slack, channel) do
    IO.inspect(channel)
    send_message("Hot Potato starting in 30 seconds - message 'join' to play", channel, slack)
  end

  def send_join_notice(slack, channel, player_id) do
    send_message("<@#{player_id}> has joined the game!", channel, slack)
  end

  def send_warning(slack, channel, message) do
    send_message("#{message} :warning:", channel, slack)
  end
end
