defmodule HotPotato do
  @moduledoc """
  Documentation for HotPotato.
  """

  use Slack

  def connect() do
    token = System.get_env("TOKEN")
    Slack.Bot.start_link(HotPotato, [], token)
  end

  def handle_connect(slack, state) do
    IO.puts "Connected as #{slack.me.name}"
    {:ok, state}
  end


  def handle_event(message = %{type: "message"}, slack, state) do
    user = message.user
    send_message("I got a message from <@#{user}>!", message.channel, slack)
    {:ok, state}
  end
  def handle_event(_, _, state), do: {:ok, state}

  def handle_info({:message, text, channel}, slack, state) do
    IO.puts "Sending your message, captain!"

    send_message(text, channel, slack)

    {:ok, state}
  end
  def handle_info(_, _, state), do: {:ok, state}
end
