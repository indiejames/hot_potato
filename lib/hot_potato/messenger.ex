defmodule HotPotato.Messenger do
  @doc """
  Send a text message to the given channel
  """
  @callback send_text_message(message :: String.t(), channel :: String.t(), slack :: any) :: any
end
