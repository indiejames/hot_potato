defmodule HotPotato.GameState do
  alias HotPotato.Actions

  @initial_state %{
    :players => MapSet.new, # all players in the current game (alive or dead)
    :live_players => MapSet.new, # active players
    :potato_lifespan => 0, # lifespan of potato in milliseconds
    :start_time => 0 # start time in milliseconds since epoch
  }

  use Fsm, initial_state: :stopped, initial_data: @initial_state

  # STOPPED
  defstate stopped do
    # start game event
    defevent startGame(slack, channel) do
      state = @initial_state
      |> Map.put(:slack, slack)
      |> Map.put(:channel, channel)

      new_state = Actions.start_game(state)

      next_state(:waiting_for_joiners, new_state)
    end
  end

  # WAITING_FOR_JOINERS
  defstate waiting_for_joiners do
    # player join event
    defevent join(player_id), data: state do
      new_state = Actions.add_player(state, player_id)
      next_state(:waiting_for_joiners, new_state)
    end

    # start round event
    defevent start_round(), data: state do
      new_state = Actions.start_round(state)
      %{:live_players => players} = new_state
      next_state_atom = if Enum.count(players) < 2 do
        :stopped
      else
        :playing
      end

      next_state(next_state_atom, new_state)
    end
  end

  # PLAYING
  defstate playing do
    # player pass potato event
    defevent pass(_from_user_id, to_player_id), data: state do
      new_state = Actions.pass(state, to_player_id)
      next_state(:playing, new_state)
    end

    # potato exploded event
    defevent explode(), data: state do
      new_state = Actions.kill_player(state)
      %{:live_players => live_players} = new_state
      {next_state_atom, new_state} =
        if Enum.count(live_players) == 1 do
          {:stopped, Actions.announce_winner(new_state)}
        else
          {:playing, Actions.start_round(state)}
        end

      next_state(next_state_atom, new_state)
    end

    defevent stop do
      next_state(:stopped, %{})
    end
  end

  # prevent exceptions for unknown or improper events
  # defevent _ do
  # end

end
