defmodule HotPotato.SlackMessenger do
  @behaviour HotPotato.Messenger
  use Slack

  def send_text_message(message, channel, slack) do
    send_message(message, channel, slack)
  end

end
