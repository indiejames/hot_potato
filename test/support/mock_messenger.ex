defmodule HotPotato.MockMessenger do
  @behaviour HotPotato.Messenger

  @moduledoc """
  Provides a mock for the HotPotato.Messenger behaviour that can be used for tests
  """

  def send_text_message(message, _channel, _slack) do
    IO.puts("Sending message: '#{message}")
  end

  def send_image(channel, file, file_name) do
    IO.put("Sending image #{file}")
  end
end
