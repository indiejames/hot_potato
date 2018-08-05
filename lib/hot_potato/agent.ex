defmodule HotPotato.Agent do
  use Agent
  alias HotPotato.GameState

  @doc "Starts the agaent using the module name as its name with an empty map as its state"
  def start_link(_) do
    Agent.start_link(fn -> GameState.new end, name: __MODULE__)
  end

  def start_game(slack, channel) do
    Agent.get(__MODULE__, fn state ->
      GameState.startGame(state, slack, channel)
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
