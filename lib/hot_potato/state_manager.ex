defmodule HotPotato.StateManager do
  use Agent
  alias HotPotato.GameState
  alias HotPotato.Message

  @moduledoc """
  Functions to update game state when Slack messages or timer events are received
  """

  @doc "Starts the agaent using the module name as its name with an empty map as its state"
  def start_link(_) do
    Agent.start_link(fn -> GameState.new end, name: __MODULE__)
  end

  @doc """
  Start the game when someone requests it
  """
  def start_game(slack, channel, player_id) do
    Image.send_image(channel, "images/countdown.gif", "countdown.gif")
    Agent.update(__MODULE__, fn state ->
      if state.state == :stopped do
        GameState.startGame(state, slack, channel)
      else
        Message.send_warning(slack, channel, "<@#{player_id}> a game is already running")
        state
      end
    end)
  end

  @doc """
  Add a player to the game
  """
  def add_player(slack, channel, player_id) do
    Agent.update(__MODULE__, fn state ->
      if state.state == :waiting_for_joiners do
        GameState.join(state, player_id)
      else
        Message.send_warning(slack, channel, "<@#{player_id}> you can't join right now")
        state
      end
    end)
  end

  def do_countdown() do
    Agent.update(__MODULE__, fn state ->
      GameState.do_countdown(state)
    end)
  end

  @doc """
  Begin the round
  """
  def begin_round() do
    IO.puts("Beginning round")
    Agent.update(__MODULE__, fn state ->
      GameState.start_round(state)
    end)
    # Agent.cast(__MODULE__, fn  state ->
    #   GameState.start_round(state)
    # end)
  end

  @doc """
  Pass the potato from one player to another
  """
  def pass_to(from_player_id, to_player_id) do
    Agent.update(__MODULE__, fn state ->
      GameState.pass(state, from_player_id, to_player_id)
    end)
  end

  def explode() do
    Agent.update(__MODULE__, fn state ->
      GameState.explode(state)
    end)
  end

  @doc "Get the list of players in the current game"
  def players() do
    Agent.get(__MODULE__, fn state ->
      Map.get(state.data, :players, [])
    end)
  end

  # def running?() do
  #   Agent.get(__MODULE__, fn state ->
  #     Map.get(state, :game_state, []) == :running
  #   end)
  # end
end
