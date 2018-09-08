defmodule GameStateMachineTest do
  use ExUnit.Case, async: false
  use Mix.Config
  import ExUnit.CaptureLog
  alias HotPotato.GameStateMachine

  @moduledoc """
  Test module for the GameStateMachine functions. These tests rely on the MockSlackWebUsers
  module that defines users 'user1', 'user2', and 'user3'
  """

  doctest HotPotato.GameStateMachine

  # set up state once before tests run
  # setup_all do
  #   {:ok, gsm_agent} = Agent.start_link(fn -> GameStateMachine.new() end)
  #   {:ok, gsm_agent: gsm_agent}
  # end

  describe "Pre start game checks" do

    setup do
      {:ok, gsm: GameStateMachine.new()}
    end

    test "Games initial state is stopped", state do
      assert state.gsm.state == :stopped
    end

    test "Initial player list is empty", state do
      assert Enum.count(state.gsm.data.players) == 0
    end
  end

  describe "Pre start round checks" do

    setup do
      {:ok, gsm: GameStateMachine.new() |> GameStateMachine.game_started(nil, "#hp")}
    end

    test "game_started event starts join period", state do
      assert state.gsm.state == :waiting_for_joiners
    end

    test "Player joining gets added to players list", state do
        new_gsm = GameStateMachine.join_request(state.gsm, "user1")
        # should still be waiting for joiners
        assert new_gsm.state == :waiting_for_joiners
        # player should be added to players list
        assert new_gsm.data.live_players == MapSet.new(["user1"])
    end

    test "Countdown event starts the countdown", state do
      new_gsm = GameStateMachine.countdown_started(state.gsm)
      assert new_gsm.state == :countdown
    end

    test "Game will not start with less than two players", state do
      new_gsm = GameStateMachine.countdown_started(state.gsm) |> GameStateMachine.start_round()
      assert new_gsm.state == :stopped
    end

    test "Game warns users that try to join more than once", state do
      gsm = state.gsm
      |> GameStateMachine.join_request("user1")
      |> GameStateMachine.join_request("user2")
      entry = capture_log(fn -> GameStateMachine.join_request(gsm, "user2") end)
      [{_time_stamp, _level, message}] = HotPotato.Test.Util.parse_message_log_entry(entry)
      assert message == "I heard you the first time, <@user2> :warning:"
    end

    test "Game will not let users join after the countdown starts", state do
      gsm = state.gsm
      |> GameStateMachine.countdown_started()
      |> GameStateMachine.join_request("user3")
      assert gsm.data.players == MapSet.new([])
    end
  end

  describe "Post start round checks" do
    setup do
      gsm = GameStateMachine.new()
      |> GameStateMachine.game_started(nil, "#hp")
      |> GameStateMachine.join_request("user1")
      |> GameStateMachine.join_request("user2")
      |> GameStateMachine.countdown_started()
      {:ok, gsm: gsm}
    end

    test "Game starts correctly with two or more players", state do
      gsm = state.gsm
      |> GameStateMachine.start_round()
      assert gsm.state == :playing
    end

    test "Game makes announcemnets when round starts", state do
      expected_messages = [
        ~r/Starting round 1!/,
        ~r/The players are <@user1>,<@user2>/,
        ~r/<@user\d> has the potato/
      ]

      entries = capture_log(fn -> GameStateMachine.start_round(state.gsm) end)
      messages = HotPotato.Test.Util.parse_message_log_entry(entries)
      |> Enum.map(fn {_time_stamp, _level, message} -> message end)
      expected_messages |>
      Enum.zip(messages) |>
      Enum.each(fn {regex, message} ->
        assert Regex.match?(regex, message)
      end)
    end

    test "Player that has the potato can pass it to another player", state do
      gsm = state.gsm |> GameStateMachine.start_round()

      player = gsm.data.player_with_potato
      pass_to_player = gsm.data.live_players
      |> Enum.filter(&(&1 != player))
      |> List.first()

      entry = capture_log(fn -> GameStateMachine.pass(gsm, player, pass_to_player) end)
      [{_time_stamp, _level, message}] = HotPotato.Test.Util.parse_message_log_entry(entry)
      assert message == "<@#{pass_to_player}> has the potato"
    end

    test "Game warns user that tries to pass the potato when they don't have it", state do
      gsm = state.gsm |> GameStateMachine.start_round()

      player = gsm.data.player_with_potato
      non_potato_player = gsm.data.live_players
      |> Enum.filter(&(&1 != player))
      |> List.first()

      entry = capture_log(fn -> GameStateMachine.pass(gsm, non_potato_player, player) end)
      [{_time_stamp, _level, message}] = HotPotato.Test.Util.parse_message_log_entry(entry)
      assert message == "<@#{non_potato_player}>, you can't pass a potato you don't have! :warning:"
    end

    test "Game warns user when they try to pass the potato to a non-player", state do
      gsm = state.gsm |> GameStateMachine.start_round()

      player = gsm.data.player_with_potato

      entry = capture_log(fn -> GameStateMachine.pass(gsm, player, "user3") end)
      [{_time_stamp, _level, message}] = HotPotato.Test.Util.parse_message_log_entry(entry)
      assert message == "<@#{player}>, <@user3> is not playing! :warning:"
    end

    test "Game warns user when they try to pass the potato to a non-user", state do
      gsm = state.gsm |> GameStateMachine.start_round()

      player = gsm.data.player_with_potato

      entry = capture_log(fn -> GameStateMachine.pass(gsm, player, "user4") end)
      [{_time_stamp, _level, message}] = HotPotato.Test.Util.parse_message_log_entry(entry)
      assert message == "<@#{player}>, <@user4> is not playing! :warning:"
    end

    test "User with potato is removed from players when potato explodes", state do

    end

    test "Award is given to winner", state do

    end
  end
end
