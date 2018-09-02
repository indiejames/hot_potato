defmodule HotPotato.Messenger do
  @doc """
  Send a text message to the given channel
  """
  @callback send_text_message(message :: String.t(), channel :: String.t(), slack :: any) :: any

  @doc """
  Send an image file to the given channel
  """
  @callback send_image(channel :: String.t(), file :: String.t(), file_name :: String.t()) :: any
end
