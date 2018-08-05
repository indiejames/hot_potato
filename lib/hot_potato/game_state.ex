defmodule HotPotato.GameState do
  alias HotPotato.Message

  @initial_state %{
    :players => [], # all players in the current game (alive or dead)
    :live_players => [], # active players
    :potato_lifespan => 0, # lifespan of potato in milliseconds
    :start_time => 0 # start time in milliseconds since epoch
  }

  use Fsm, initial_state: :stopped, initial_data: @initial_state

  defstate stopped do
    defevent startGame(slack, channel) do
      IO.puts("About to send message")
      Message.send_start_notice(slack, channel)
      IO.puts("Message sent")
      state = @initial_state
      |> Map.put("slack", slack)
      |> Map.put("channel", channel)
      next_state(:waiting_for_joiners, state)           # changing state and data
    end
  end

  defstate waiting_for_joiners do
    defevent join(player_id), data: state do
      new_state = state
        |> update_in([:players], &([player_id | &1]))
        |> update_in([:live_players], &([player_id | &1]))
      next_state(:waiting_for_joiners, new_state)
    end

    defevent timeout(), data: state do
      if Enum.count(Map.get(state, :players)) > 0 do
        next_state(:stopped, @initial_state)
      else
        next_state(:playing, state)
      end
    end
  end

  defstate playing do
    defevent slowdown(by), data: speed do     # you can pattern match data with dedicated option
      next_state(:playing, speed - by)
    end

    defevent stop do
      next_state(:stopped, 0)
    end
  end

end
