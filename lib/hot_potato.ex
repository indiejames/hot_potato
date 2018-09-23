defmodule HotPotato do
  @moduledoc """
  Documentation for HotPotato.
  """

  use Slack
  use HotPotato.Matcher
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    connect()
    {:ok, %{}}
  end

  @doc """
  Connect to the Slack channel

  Returns {:ok, pid}
  """
  def connect() do
    token = System.get_env("TOKEN")
    IO.puts("TOKEN: #{token}")
    {:ok, agent} = HotPotato.StateManager.start_link([])
    Slack.Bot.start_link(__MODULE__, agent, token, %{:name => Slack.Bot})
  end

  # Messages to listen for and actions to take
  match(~r/go potato/, :start_game)

  match(~r/^join/, :join)

  match(~r/pass to <@(.+?)>/, :pass)

  match(~r/give to <@(.+?)>/, :pass)

  @doc """
  Start a new game. Called from the message matcher.

  Returns the new game state map
  """
  def start_game(slack, channel, from_player) do
    IO.puts("Player #{from_player} has requested a game")
    HotPotato.StateManager.start_game(slack, channel, from_player)
    # TODO remove this for real games - needed now for testing by myself
    HotPotato.StateManager.add_player(slack, channel, slack.me.id)
  end

  @doc """
  Add a player to the game. Called from the message matcher.

  Returns the new game state map
  """
  def join(slack, channel, from_player) do
    IO.puts("Player #{from_player} wants to join")
    HotPotato.StateManager.add_player(slack, channel, from_player)
  end

  @doc """
  Pass the potato from one player to another. Called from the message matcher.

  Returns the new game state map
  """
  def pass(_slack, _channel, from_player_id, to_player_id) do
    HotPotato.StateManager.pass_to(from_player_id, to_player_id)
  end

  @doc """
  Callback for when a connection is made to the Slack channel

  Returns {:ok, interaal_game_state}
  """
  def handle_connect(slack, state) do
    IO.puts("Connected as #{slack.me.name}")
    {:ok, state}
  end

  @doc """
  Callback for message events. Calls the matcher to handle actions triggered by Slack messages.

  @returns {:ok, internal_game_state}
  """
  def handle_event(message = %{type: "message"}, slack, state) do
    # send_message("I got a message from <@#{user}>!", message.channel, slack)
    do_match(slack, message)
    {:ok, state}
  end

  @doc """
  Catch-all event handler to prevent exceptions for unhandled events

  Returns {:ok, original_state}
  """
  def handle_event(_, _, state), do: {:ok, state}

  @doc """
  Handle process messages. Can be used programmatially send messages to slack.

  Returns {:ok, original_state}
  """
  def handle_info({:message, text, channel}, slack, state) do
    IO.puts("Sending your message, captain!")

    send_message(text, channel, slack)

    {:ok, state}
  end

  @doc """
  Catch-all handler to prevent unknown process messages from causing exceptions

  Returns {:ok, original_state}
  """
  def handle_info(_, _, state), do: {:ok, state}
end
