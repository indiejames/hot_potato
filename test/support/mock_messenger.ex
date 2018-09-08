defmodule HotPotato.MockMessenger do
  @behaviour HotPotato.Messenger
  require Logger

  @moduledoc """
  Provides a mock for the HotPotato.Messenger behaviour that can be used for tests
  """

  def send_text_message(message, _channel, _slack) do
    Logger.info("Sending message: '#{message}'")
  end

  def send_image(_channel, file, _file_name) do
    Logger.info("Sending image #{file}")
  end
end
