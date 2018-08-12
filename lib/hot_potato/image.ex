defmodule Image do

  @moduledoc """
  Functions to send images to the Slack channel
  """

  # Send the given `file` to the channel using `fileName`
  def send_image(channel, file, fileName) do
    token = System.get_env("TOKEN")
    Slack.Web.Files.upload(file, fileName, %{token: token, as_user: true, channels: [channel]})
  end

  @doc """
  Send an image of an exploding potato to the channel
  """
  def send_boom(channel) do
    send_image(channel, Application.get_env(:hot_potato, :boom_image), "boom.jpg")
  end
end
