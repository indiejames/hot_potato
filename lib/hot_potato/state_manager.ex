defmodule HotPotato.StateManager do
  use Agent
  alias HotPotato.GameStateMachine
  alias HotPotato.Message

  @moduledoc """
  Functions to update game state when Slack messages or timer events are received
  """

  @doc "Starts the agaent using the module name as its name with an empty map as its state"
  def start_link(_) do
    Agent.start_link(fn -> GameStateMachine.new end, name: __MODULE__)
  end

  @doc """
  Start the game when someone requests it
  """
  def start_game(slack, channel, player_id) do
    Agent.update(__MODULE__, fn gsm ->
      if gsm.state == :stopped do
        GameStateMachine.game_started(gsm, slack, channel)
      else
        Message.send_warning(slack, channel, "<@#{player_id}> a game is already running")
        gsm
      end
    end)
  end

  @doc """
  Add a player to the game
  """
  def add_player(slack, channel, player_id) do
    Agent.update(__MODULE__, fn gsm ->
      if gsm.state == :waiting_for_joiners do
        GameStateMachine.join_request(gsm, player_id)
      else
        Message.send_warning(slack, channel, "<@#{player_id}> you can't join right now")
        gsm
      end
    end)
  end

  @doc """
  Start the countdown
  """
  def do_countdown() do
    Agent.update(__MODULE__, fn gsm ->
      GameStateMachine.countdown_started(gsm)
    end)
  end

  @doc """
  Begin the round
  """
  def begin_round() do
    IO.puts("Beginning round")
    Agent.update(__MODULE__, fn gsm ->
      GameStateMachine.start_round(gsm)
    end)
  end

  @doc """
  Pass the potato from one player to another
  """
  def pass_to(from_player_id, to_player_id) do
    Agent.update(__MODULE__, fn gsm ->
      GameStateMachine.pass(gsm, from_player_id, to_player_id)
    end)
  end

  def explode() do
    Agent.update(__MODULE__, fn gsm ->
      GameStateMachine.explode(gsm)
    end)
  end

  def announce_second_place() do
    Agent.update(__MODULE__, fn gsm ->
      GameStateMachine.second_place_award(gsm)
    end)
  end

  @doc "Get the list of players in the current game"
  def players() do
    Agent.get(__MODULE__, fn gsm ->
      Map.get(gsm.data, :players, [])
    end)
  end

  # def running?() do
  #   Agent.get(__MODULE__, fn state ->
  #     Map.get(state, :game_state, []) == :running
  #   end)
  # end
end
