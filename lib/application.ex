defmodule Primy.Application do
  use Application

  def start(_type, _args) do
    children = [
      Primy.WorkerRegistry,
      {DynamicSupervisor, strategy: :one_for_one, name: Primy.DynamicSupervisor},
      {Task.Supervisor, name: Primy.TaskSupervisor}
    ]

    opts = [strategy: :rest_for_one, name: Primy.ApplicationSupervisor]
    Supervisor.start_link(children, opts)
  end
end
