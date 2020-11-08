defmodule Primy.TestSetup do
  def maybe_kill_app_supervisor do
    case Process.whereis(Primy.ApplicationSupervisor) do
      nil ->
        nil

      pid when is_pid(pid) ->
        Process.exit(pid, :kill)
        :timer.sleep(500)
    end
  end

  def start_test_app_supervisor do
    children = [
      Primy.Server,
      {Task.Supervisor, name: Primy.TaskSupervisor}
    ]

    opts = [
      strategy: :rest_for_one,
      max_restarts: 999_999,
      max_seconds: 999_999,
      name: Primy.TestApplicationSupervisor
    ]

    Supervisor.start_link(children, opts)
  end

  def find_and_kill_process(process_name) do
    process_name
    |> Process.whereis()
    |> Process.exit(:kill)
  end

  def wait_until_restarted(process_name) do
    with pid when is_pid(pid) <- Process.whereis(process_name),
         true <- Process.alive?(pid) do
      nil
    else
      _ -> wait_until_restarted(process_name)
    end
  end
end
