defmodule HotPotato.StateManager do
  use Agent
  alias HotPotato.GameStateMachine
  alias HotPotato.Actions
  alias HotPotato.Message
  import HotPotato.Util

  @moduledoc """
  Functions to update game state when Slack messages or timer events are received
  """

  # default fuse time (per player) in ms
  @default_fuse_time "5000"

  # length of countdown animation in ms
  @countdown_delay 5_700

  # how long to wait between rounds
  @delay_between_rounds 5_000

  # delay between award notifications in ms
  @delay_between_awards 3000

  # mean delay between telling jokes in ms
  @mean_joke_delay 10_000

  @doc "Starts the agaent using the module name as its name with an empty map as its state"
  def start_link(_) do
    Agent.start_link(fn -> GameStateMachine.new() end, name: __MODULE__)
  end

  @doc """
  Start the game when someone requests it
  """
  def start_game(slack, channel, player_id) do
    Agent.update(__MODULE__, fn gsm ->
      if gsm.state == :stopped do
        game_start_delay = Application.get_env(:hot_potato, :game_start_delay)
        # set a timer to begin the first round after players have joined
        run_after_delay(game_start_delay - 5_000, &do_countdown/0)
        GameStateMachine.game_started(gsm, slack, channel)
      else
        Message.send_warning(slack, channel, "<@#{player_id}> a game is already running")
        gsm
      end
    end)
  end

  # create a timer to signal when the potato explodes
  defp start_potato_timer(game_data) do
    %{:players => players} = game_data
    min_potato_fuse_time = Application.get_env(:hot_potato, :min_potato_fuse_time)
    duration = System.get_env("FUSE_TIME") || @default_fuse_time
    IO.puts("duration = #{duration}")
    {duration, _} = Integer.parse(duration)
    IO.puts("duration = #{duration}")
    duration = duration * Enum.count(players)
    duration = duration + :rand.normal(0, 0.1) * duration
    duration = if duration < min_potato_fuse_time, do: min_potato_fuse_time, else: duration
    duration = Kernel.trunc(duration)
    IO.puts("duration = #{duration}")
    run_after_delay(duration, &explode/0)
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
      new_gsm = GameStateMachine.countdown_started(gsm)
      run_after_delay(@countdown_delay, &begin_round/0)
      new_gsm
    end)
  end

  @doc """
  Begin the round
  """
  def begin_round() do
    IO.puts("Beginning round")

    Agent.update(__MODULE__, fn gsm ->
      new_gsm = GameStateMachine.start_round(gsm)
      if System.get_env("JOKES") do
        delay = :rand.normal(0, 5) + @mean_joke_delay |> Kernel.trunc()
        run_after_delay(delay, &tell_joke/0)
      end
      start_potato_timer(new_gsm.data)
      new_gsm
    end)
  end

  @doc """
  Tell a joke if the game is in the :playing state
  """
  def tell_joke do
    Agent.update(__MODULE__, fn gsm ->
      if gsm.state == :playing do
        IO.puts("telling joke...")
        new_game_data = Actions.tell_joke(gsm.data)
        delay = :rand.normal(0, 5) + @mean_joke_delay |> Kernel.trunc()
        run_after_delay(delay, &tell_joke/0)
        Map.put(gsm, :data, new_game_data)
      else
        gsm
      end
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
      new_gsm = GameStateMachine.explode(gsm)

      if new_gsm.state === :pause_before_countdown do
        run_after_delay(@delay_between_rounds, &do_countdown/0)
      else
        # end of game
        run_after_delay(@delay_between_awards, &do_awards/0)
      end

      new_gsm
    end)
  end

  def do_awards() do
    Agent.update(__MODULE__, fn gsm ->
      new_gsm = GameStateMachine.tick(gsm)

      if new_gsm.state != :stopped do
        IO.puts("do_awards will run again")
        run_after_delay(@delay_between_awards, &do_awards/0)
      else
        IO.puts("do_awards will not run again")
      end

      new_gsm
    end)
  end

  @doc "Get the list of players in the current game"
  def players() do
    Agent.get(__MODULE__, fn gsm ->
      Map.get(gsm.data, :players, [])
    end)
  end
end
