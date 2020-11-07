defmodule Primy.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Primy.Server, 0},
      {DynamicSupervisor, strategy: :one_for_one, name: Primy.DynamicSupervisor}
    ]

    opts = [strategy: :one_for_one, name: Primy.ApplicationSupervisor]
    Supervisor.start_link(children, opts)
  end
end
