defmodule HotPotato do
  @moduledoc """
  Documentation for HotPotato.
  """

  use Slack
  use HotPotato.Matcher

  def connect() do
    token = System.get_env("TOKEN")
    IO.puts("TOKEN: #{token}")
    {:ok, agent} = HotPotato.Agent.start_link([])
    Slack.Bot.start_link(__MODULE__, agent, token)
  end

  match ~r/Hello, how are you <@(.+?)> and <@(.+?)>\?$/, :hellos

  match ~r/Hello,\s+<@(.+)>/, :hello

  match ~r/Go potato!/, :start_game

  def hellos(slack, channel, from_user, to_user1, to_user2) do
    send_message("Hello from <@#{from_user}> to <@#{to_user1}> and <@#{to_user2}>", channel, slack)
  end

  def hello(slack, channel, from_user, to_user) do
    IO.inspect(slack)
    send_message("Hello from <@#{from_user}> to <@#{to_user}>", channel, slack)
  end

  def start_game(slack, channel, from_user) do
    IO.puts("User #{from_user} has requested a game")
    HotPotato.Agent.start_game(slack, channel)
  end

  def handle_connect(slack, state) do
    IO.puts "Connected as #{slack.me.name}"
    {:ok, state}
  end

  def handle_event(message = %{type: "message"}, slack, state) do
    # send_message("I got a message from <@#{user}>!", message.channel, slack)
    do_match(slack, message)
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
