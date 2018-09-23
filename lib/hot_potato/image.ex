defmodule Image do
  @messenger Application.get_env(:hot_potato, :messenger)

  @moduledoc """
  Functions to send images to the Slack channel
  """

  def send_countdown(channel) do
    file = Application.get_env(:hot_potato, :countdown_image)
    file_name = Path.basename(file)
    @messenger.send_image(channel, file, file_name)
  end

  @doc """
  Send an image of an exploding potato to the channel
  """
  def send_boom(channel) do
    @messenger.send_image(channel, Application.get_env(:hot_potato, :boom_image), "boom.jpg")
  end

  def create_award_annotated_image(file, text) do
    image_width = 128
    point_size = 20
    pixel_size = 11
    image_height = image_width + 2 * pixel_size
    label_width = String.length(text) * pixel_size
    image_width = if label_width > image_width, do: label_width, else: image_width
    x_offset = 0
    IO.puts("OFFSET: #{x_offset}")

    %Mogrify.Image{path: file}
    |> Mogrify.gravity("North")
    |> Mogrify.extent(~s(#{image_width}x#{image_height}))
    |> Mogrify.custom("font", "Courier")
    |> Mogrify.custom("pointsize", "#{point_size}")
    |> Mogrify.Draw.text(x_offset, 120, text)
    |> Mogrify.save()
    |> Map.get(:path)
  end

  @doc """
  Send an annotated image of an award to channel. The `file` argument specifies the image to use.
  The `text argument is used for hte annotation. Long annotations will probably not fit on the
  image.
  """
  def send_award(channel, file, text) do
    path = create_award_annotated_image(file, text)

    try do
      @messenger.send_image(channel, path, Path.basename(file))
    after
      File.rm(path)
    end
  end
end
