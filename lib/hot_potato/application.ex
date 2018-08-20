defmodule HotPotato.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # connect to Slack
    HotPotato.connect()

    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: HotPotato.Worker.start_link(arg1, arg2, arg3)
      # worker(HotPotato.Worker, [arg1, arg2, arg3]),

    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HotPotato.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
