defmodule HotPotato.Test.Util do
  @moduledoc """
  Utility functions to support tests
  """

  @doc """
  Returns a tuple containt the timestamp, level, and base message from the given message log entry
  """
  def parse_message_log_entry(entry) do
    IO.puts("ENTRY: #{entry}")
    regex = ~r/.*?(\d\d:\d\d:\d\d\.\d\d\d)\s\[(.+?)\]\s+Sending message:\s'(.*)'.*?/s
    [_, time_stamp, level, message] = Regex.run(regex, entry)
    {time_stamp, level, message}
  end
end
