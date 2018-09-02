defmodule HotPotato.SlackMessenger do
  @behaviour HotPotato.Messenger
  use Slack

  def send_text_message(message, channel, slack) do
    send_message(message, channel, slack)
  end

  def send_image(channel, file, file_name) do
    token = System.get_env("TOKEN")
    Slack.Web.Files.upload(file, file_name, %{token: token, as_user: true, channels: [channel]})
  end

end
