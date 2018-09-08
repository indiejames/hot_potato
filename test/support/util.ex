defmodule HotPotato.Test.Util do
  @moduledoc """
  Utility functions to support tests
  """

  @doc """
  Returns a tuple containt the timestamp, level, and base message from the given message log entry
  """
  def parse_message_log_entry(entry) do
    regex = ~r/(\d\d:\d\d:\d\d\.\d\d\d)\s\[(.+?)\]\s+Sending message:\s'(.*)'/
    [_, time_stamp, level, message] = Regex.run(regex, entry)
    entries = Regex.scan(regex, entry)
    Enum.map(entries, fn [_, time_stamp, level, message] ->
      {time_stamp, level, message}
    end)
  end
end
