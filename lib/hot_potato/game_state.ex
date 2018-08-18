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
      # we need the map of user ids to user names so we can send awards later
      users = Slack.Web.Users.list(%{token: System.get_env("TOKEN")})
      |> Map.get("members")
      |> Enum.reduce(%{}, fn(member, acc) ->
        Map.put(acc, member["id"], member["name"])
      end)
      state = @initial_state
      |> Map.put(:slack, slack)
      |> Map.put(:channel, channel)
      |> Map.put(:users, users)

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

    # start the countdown
    defevent do_countdown(), data: state do
      new_state = Actions.do_countdown(state)
      next_state(:countdown, new_state)
    end
  end

  # COUNT_DOWN
  defstate countdown do
    # defevent do_countdown, data: state do
    #   new_state = Actions.do_countdown(state)
    #   next_state(:countdown, new_state)
    # end

    # start round event
    defevent start_round, data: state do
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
    defevent pass(from_user_id, to_player_id), data: state do
      new_state = Actions.pass(state, from_user_id, to_player_id)
      next_state(:playing, new_state)
    end

    # potato exploded event
    defevent explode(), data: state do
      new_state = Actions.kill_player(state)
      %{:live_players => live_players} = new_state
      {next_state_atom, new_state} =
        if Enum.count(live_players) == 1 do
          {:award_ceremony, Actions.announce_winner(new_state)}
        else
          {:playing, Actions.start_round(new_state)}
        end

      next_state(next_state_atom, new_state)
    end

    defevent stop do
      next_state(:stopped, %{})
    end
  end

  # AWARD_CEREMONY
  defstate award_ceremony do
    defevent second_place_award(), data: state do
      Actions.announce_second_place(state)
      next_state(:stopped, state)
    end
  end

  # prevent exceptions for unknown or improper events
  defevent _ do
  end

end
