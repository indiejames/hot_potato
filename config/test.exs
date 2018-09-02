use Mix.Config
config :slack, url: "http://localhost:8000"
config :hot_potato, slack_module: MockSlack
config :hot_potato, files_module: MockSlack.Web.Files
