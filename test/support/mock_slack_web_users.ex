defmodule HotPotato.MockSlackWebUser do
  @moduledoc """
  Provides a mock of the Slack.Web.Users module for testing
  """

  def list(_slack) do
    %{
      "members" => [
        %{
          "id" => "user1",
          "real_name" => "User1",
          "is_bot" => false
        },
        %{
          "id" => "user2",
          "real_name" => "User2",
          "is_bot" => false
        },
        %{
          "id" => "user3",
          "real_name" => "User3",
          "is_bot" => false
        },
        %{
          "id" => "bot_user",
          "real_name" => "BotUser",
          "is_bot" => true
        }
      ]
    }
  end
end
