defmodule GameStateMachineTest do
  use ExUnit.Case
  use Mix.Config

  config :slack, url: "http://localhost:8000"

  doctest HotPotato.GameStateMachine

  test "Join even" do
    assert 1 + 1 == 2
  end
end
