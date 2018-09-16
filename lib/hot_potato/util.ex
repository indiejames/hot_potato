defmodule HotPotato.Util do
  # run a function after the given delay (in ms)
  def run_after_delay(delay, fun) do
    spawn(fn ->
      receive do
        {:not_gonna_happen, msg} -> msg
      after
        delay -> fun.()
      end
    end)
  end
end
