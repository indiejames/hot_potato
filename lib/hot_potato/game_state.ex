defmodule HotPotato.GameState do
  alias HotPotato.Message

  @game_start_delay 30_000 # time players have to join a new game (msec)

  @initial_state %{
    :players => MapSet.new, # all players in the current game (alive or dead)
    :live_players => MapSet.new, # active players
    :potato_lifespan => 0, # lifespan of potato in milliseconds
    :start_time => 0 # start time in milliseconds since epoch
  }

  use Fsm, initial_state: :stopped, initial_data: @initial_state

  defstate stopped do
    defevent startGame(slack, channel) do
      Message.send_start_notice(slack, channel)

      # set a timer to begin the first round after players have joined
      # :timer.apply_after(@game_start_delay, HotPotato.StateManager, HotPotato.StateManager.begin_round, [])
      spawn(fn ->
        receive do
          {:hello, msg}  -> msg
          after
            @game_start_delay -> HotPotato.StateManager.begin_round()
          end
      end)


      state = @initial_state
      |> Map.put(:slack, slack)
      |> Map.put(:channel, channel)
      next_state(:waiting_for_joiners, state)
    end
  end

  defstate waiting_for_joiners do
    defevent join(player_id), data: state do
      %{:slack => slack, :channel => channel, :players => players} = state

      new_state = if !MapSet.member?(players, player_id) do
        Message.send_join_notice(slack, channel, player_id)

        state
        |> update_in([:players], &(MapSet.put(&1, player_id)))
        |> update_in([:live_players], &(MapSet.put(&1, player_id)))
      else
        Message.send_warning(slack, channel, "I heard you the first time, <@#{player_id}>")
        state
      end

      IO.inspect(Map.get(new_state, :players))
      next_state(:waiting_for_joiners, new_state)
    end

    defevent start_round(), data: state do
      %{:slack => slack, :channel => channel, :players => players} = state
      IO.puts("Starting the round")
      if Enum.count(players) < 2 do
        Message.send_warning(slack, channel, "Not enough players")
        next_state(:stopped, @initial_state)
      else
        Message.send_started_notice(slack, channel)
        next_state(:playing, state)
      end
    end
  end

  defstate playing do
    defevent slowdown(by), data: speed do
      next_state(:playing, speed - by)
    end

    defevent stop do
      next_state(:stopped, 0)
    end
  end

  # prevent exceptions for unknown or improper events
  # defevent _ do
  # end

end
