defmodule Primy.ApplicationTest do
  use ExUnit.Case, async: true
  alias Primy.{Server, TaskSupervisor}
  import Primy.TestSetup

  setup_all do
    maybe_kill_app_supervisor()
    start_test_app_supervisor()

    :ok
  end

  describe "Primy.Server" do
    test "is restarted once it crashes" do
      server_pid = Process.whereis(Server)
      ref = Process.monitor(server_pid)

      Process.exit(server_pid, :kill)

      assert process_was_restarted?(ref, server_pid, Server)
    end
  end

  describe "Primy.TaskSupervisor" do
    test "is restarted, once it crashes" do
      task_supervisor_pid = Process.whereis(TaskSupervisor)
      ref = Process.monitor(task_supervisor_pid)

      Process.exit(task_supervisor_pid, :kill)

      assert process_was_restarted?(ref, task_supervisor_pid, TaskSupervisor)
    end

    test "is restarted, once Primy.Server crashes" do
      server_pid = Process.whereis(Server)
      task_supervisor_pid = Process.whereis(TaskSupervisor)
      ref = Process.monitor(task_supervisor_pid)

      Process.exit(server_pid, :kill)

      assert process_was_restarted?(ref, task_supervisor_pid, TaskSupervisor)
    end
  end

  defp process_was_restarted?(ref, pid, module) do
    receive do
      {:DOWN, ^ref, :process, ^pid, _reason} ->
        case Process.whereis(module) do
          nil -> send(self(), {:DOWN, ref, :process, pid, :killed})
          pid -> assert Process.alive?(pid)
        end
    after
      500 ->
        false
    end
  end
end
