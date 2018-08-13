defmodule Image do

  @moduledoc """
  Functions to send images to the Slack channel
  """

  # Send the given `file` to the channel using `fileName`
  def send_image(channel, file, file_name) do
    token = System.get_env("TOKEN")
    Slack.Web.Files.upload(file, file_name, %{token: token, as_user: true, channels: [channel]})
  end

  @doc """
  Send an image of an exploding potato to the channel
  """
  def send_boom(channel) do
    send_image(channel, Application.get_env(:hot_potato, :boom_image), "boom.jpg")
  end

  def create_award_annotated_image(file, text) do
    image_width = 166
    point_size = 20
    pixel_size = 11
    offset = image_width / 2 - (String.length(text) / 2) * pixel_size
    IO.puts(offset)

    %Mogrify.Image{path: file}
    |> Mogrify.custom("font", "Courier")
    |> Mogrify.custom("pointsize", "#{point_size}")
    |> Mogrify.Draw.text( offset, 90, text)
    |> Mogrify.save()
    |> Map.get(:path)
  end

  @doc """
  Send an annotated image of an ward to channel. The `file` argument specifies the image to use.
  The `text argument is used for hte annotation. Long annotations will probably not fit on the
  image.
  """
  def send_award(channel, file, text) do
    path = create_award_annotated_image(file, text)
    try do
      send_image(channel, path, Path.basename(file))
    after
      File.rm(path)
    end
  end
end
