# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :hot_potato, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:hot_potato, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

# time players have to join a new game (msec)
config :hot_potato, game_start_delay: 10_000
# minimum time a potato will last
config :hot_potato, min_potato_fuse_time: 5_000
# image sent to the channel when the potato explodes
config :hot_potato, boom_image: "images/potato_explosion.png"
# coundown image
config :hot_potato, countdown_image: "images/countdown.gif"
# image to use to render the winner award
config :hot_potato, winner_award_image: "images/first_prize.png"
# image to use to render second place award
config :hot_potato, second_place_award_image: "images/second_prize.png"

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
import_config "#{Mix.env()}.exs"
