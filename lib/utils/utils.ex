defmodule Primy.Utils do
  require Logger

  def server_addr do
    Application.get_env(:primy, :server_addr)
  end

  def worker_addr do
    case Node.list() do
      [] ->
        Logger.info(
          "No worker nodes are actually connected to #{inspect(server_addr())}. Falling back to spawning worker on #{
            inspect(server_addr())
          }"
        )

        server_addr()

      worker_addrs ->
        Enum.random(worker_addrs)
    end
  end

  def random_server_pid do
    {_, server_pid, _, _} =
      Primy.DynamicSupervisor
      |> Supervisor.which_children()
      |> Enum.random()

    server_pid
  end
end
