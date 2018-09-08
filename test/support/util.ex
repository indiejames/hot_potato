defmodule HotPotato.Test.Util do
  @moduledoc """
  Utility functions to support tests
  """

  @doc """
  Returns a tuple containt the timestamp, level, and base message from the given message log entry
  """
  def parse_message_log_entry(entry) do
    regex = ~r/(\d\d:\d\d:\d\d\.\d\d\d)\s\[(.+?)\]\s+Sending message:\s'(.*)'/
    entries = Regex.scan(regex, entry)
    Enum.map(entries, fn [_, time_stamp, level, message] ->
      {time_stamp, level, message}
    end)
  end

   @doc """
  Returns a tuple containt the timestamp, level, and file name from the given image log entry
  """
  def parse_image_log_entry(entry) do
    IO.inspect(entry)
    regex = ~r/(\d\d:\d\d:\d\d\.\d\d\d)\s\[(.+?)\]\s+Sending image\s(.*)/
    entries = Regex.scan(regex, entry)
    Enum.map(entries, fn [_, time_stamp, level, file_path] ->
      {time_stamp, level, file_path}
    end)
  end

end
