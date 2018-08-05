defmodule HotPotato.Message do
  use Slack

  @moduledoc """
  Provides functios to send messages for various games states to Slack
  """

  def send_start_notice(slack, channel) do
    IO.inspect(channel)
    send_message("Hot Potato starting in 30 seconds - message 'join' to play", channel, slack)
  end
end
