defmodule HotPotato.GameStateMachine do
  alias HotPotato.Actions

  @initial_data %{
    :players => MapSet.new, # all players in the current game (alive or dead)
    :live_players => MapSet.new, # active players
    :potato_lifespan => 0, # lifespan of potato in milliseconds
    :start_time => 0 # start time in milliseconds since epoch
  }

  use Fsm, initial_state: :stopped, initial_data: @initial_data

  #
  # These are all the states and the various events pertinent to each state
  #

  # STOPPED
  defstate stopped do
    # start game event
    defevent game_started(slack, channel) do
      # penatly for bots - they will need to wait at least this long before passing the potato
      {bot_penalty, ""} = (System.get_env("BOT_PENALTY") || "0")
      |> Integer.parse()

      # we need the map of user ids to user names so we can send awards later
      users = Slack.Web.Users.list(%{token: System.get_env("TOKEN")})
      |> Map.get("members")
      |> Enum.reduce(%{}, fn(member, acc) ->
        Map.put(acc, member["id"], %{:name => member["real_name"], :is_bot => member["is_bot"]})
      end)
      data = @initial_data
      |> Map.put(:slack, slack)
      |> Map.put(:channel, channel)
      |> Map.put(:users, users)
      |> Map.put(:bot_penalty, bot_penalty)

      new_data = Actions.start_game(data)

      next_state(:waiting_for_joiners, new_data)
    end
  end

  # WAITING_FOR_JOINERS
  defstate waiting_for_joiners do
    # player join event
    defevent join_request(player_id), data: data do
      new_data = Actions.add_player(data, player_id)
      next_state(:waiting_for_joiners, new_data)
    end

    # start the countdown
    defevent countdown_started(), data: data do
      new_data = Actions.do_countdown(data)
      next_state(:countdown, new_data)
    end
  end

  # COUNT_DOWN
  defstate countdown do
    # defevent do_countdown, data: state do
    #   new_data = Actions.do_countdown(state)
    #   next_state(:countdown, new_data)
    # end

    # start round event
    defevent start_round, data: data do
      new_data = Actions.start_round(data)
      %{:live_players => players} = new_data
      next_state_atom = if Enum.count(players) < 2 do
        :stopped
      else
        :playing
      end

      next_state(next_state_atom, new_data)
    end
  end

  # PLAYING
  defstate playing do
    # player pass potato event
    defevent pass(from_user_id, to_player_id), data: data do
      new_data = Actions.pass(data, from_user_id, to_player_id)
      next_state(:playing, new_data)
    end

    # potato exploded event
    defevent explode(), data: data do
      new_data = Actions.kill_player(data)
      %{:live_players => live_players} = new_data
      {next_state_atom, new_data} =
        if Enum.count(live_players) == 1 do
          {:award_ceremony, new_data}
        else
          {:countdown, Actions.do_countdown(new_data)}
        end

      next_state(next_state_atom, new_data)
    end

    defevent stop do
      next_state(:stopped, %{})
    end
  end

  # AWARD_CEREMONY WINNER
  defstate award_ceremony do
    # a timer expired indicating it's time to show something
    defevent tick(), data: data do
      new_data = Actions.announce_winner(data)
      next_state(:award_ceremony_2nd_place, new_data)
    end
  end

  # AWARD CEREMONY 2ND PLACE
  defstate award_ceremony_2nd_place do
    # a timer expired indicating it's time to show something
    defevent tick(), data: data do
      Actions.announce_second_place(data)
      next_state(:stopped, data)
    end
  end

  # prevent exceptions for unknown or improper events
  defevent _ do
  end

end
