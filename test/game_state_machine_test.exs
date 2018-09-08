defmodule GameStateMachineTest do
  use ExUnit.Case, async: false
  use Mix.Config
  import ExUnit.CaptureLog
  alias HotPotato.GameStateMachine

  doctest HotPotato.GameStateMachine

  # set up state once before tests run
  setup_all do
    {:ok, gsm_agent} = Agent.start_link(fn -> GameStateMachine.new() end)
    {:ok, gsm_agent: gsm_agent}
  end

  describe "State Machine Tests" do
    test "Games initial state is stopped", state do
      Agent.get(state.gsm_agent, fn gsm ->
        assert gsm.state == :stopped
      end)
    end

    test "Initial player list is empty", state do
      Agent.get(state.gsm_agent, fn gsm ->
        assert Enum.count(gsm.data.players) == 0
      end)
    end

    test "game_started event starts game", state do
      Agent.update(state.gsm_agent, fn gsm ->
        new_gsm = GameStateMachine.game_started(gsm, nil, "#hp")
        assert new_gsm.state == :waiting_for_joiners
        new_gsm
      end)
    end

    test "Player joining gets added to players list", state do
      Agent.update(state.gsm_agent, fn gsm ->
        new_gsm = GameStateMachine.join_request(gsm, "user1")
        assert new_gsm.state == :waiting_for_joiners
        assert new_gsm.data.live_players == MapSet.new(["user1"])
        new_gsm
      end)
    end

    test "Countdown event starts the countdown", state do
      Agent.update(state.gsm_agent, fn gsm ->
        new_gsm = GameStateMachine.countdown_started(gsm)
        assert new_gsm.state == :countdown
        new_gsm
      end)
    end

    test "Game will not start with less than two players", state do
      Agent.update(state.gsm_agent, fn gsm ->
        new_gsm = GameStateMachine.start_round(gsm)
        assert new_gsm.state == :stopped
        new_gsm
      end)
    end

    test "Game starts correctly with two or more players", state do
      Agent.update(state.gsm_agent, fn gsm ->
        new_gsm =
          GameStateMachine.reset(gsm)
          |> GameStateMachine.game_started(nil, "#hp")
          |> GameStateMachine.join_request("user1")
          |> GameStateMachine.join_request("user2")
          |> GameStateMachine.countdown_started()
          |> GameStateMachine.start_round()
          assert new_gsm.state == :playing
        new_gsm
      end)
    end

    test "Game will not let users join after the countdown starts", state do
      Agent.update(state.gsm_agent, fn gsm ->
        new_gsm =
          GameStateMachine.reset(gsm)
          |> GameStateMachine.game_started(nil, "#hp")
          |> GameStateMachine.join_request("user1")
          |> GameStateMachine.join_request("user2")
          |> GameStateMachine.countdown_started()
          |> GameStateMachine.join_request("user3")
          assert new_gsm.data.players == MapSet.new(["user1", "user2"])
        new_gsm
      end)
    end

    test "Game warns users that try to join more than once", state do
      Agent.update(state.gsm_agent, fn gsm ->
        new_gsm =
          GameStateMachine.reset(gsm)
          |> GameStateMachine.game_started(nil, "#hp")
          |> GameStateMachine.join_request("user1")
          |> GameStateMachine.join_request("user2")
          entry = capture_log(fn -> GameStateMachine.join_request(new_gsm, "user2") end)
          {_time_stamp, _level, message} = HotPotato.Test.Util.parse_message_log_entry(entry)
          assert message == "I heard you the first time, <@user2> :warning:"

          new_gsm
      end)
    end
  end
end
