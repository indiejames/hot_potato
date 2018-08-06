defmodule HotPotato.StateManager do
  use Agent
  alias HotPotato.GameState
  alias HotPotato.Message

  @doc "Starts the agaent using the module name as its name with an empty map as its state"
  def start_link(_) do
    Agent.start_link(fn -> GameState.new end, name: __MODULE__)
  end

  def start_game(slack, channel) do
    Agent.update(__MODULE__, fn state ->
      GameState.startGame(state, slack, channel)
    end)
  end

  def add_player(slack, channel, player_id) do
    Agent.update(__MODULE__, fn state ->
      IO.inspect(state.state)
      if state.state == :waiting_for_joiners do
        GameState.join(state, player_id)
      else
        Message.send_warning(slack, channel, "<@#{player_id}> you can't join right now")
        state
      end
    end)
  end

  def begin_round() do
    IO.puts("Beginning round")
    Agent.cast(__MODULE__, fn  state ->
      GameState.start_round(state)
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
