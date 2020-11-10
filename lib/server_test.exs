defmodule Primy.ServerTest do
  use ExUnit.Case, async: false
  alias Primy.Server
  import Support.TestHelpers

  @test_server_addr Application.get_env(:primy, :server_addr)

  setup_all do
    {"", 0} = System.cmd("epmd", ~w(-daemon))
    {:ok, _pid} = Node.start(@test_server_addr)

    :ok
  end

  setup do
    {:ok, server_pid} = Server.start_link()

    on_exit(fn -> assert true = Process.exit(server_pid, :kill) end)
  end

  describe "request_number/0" do
    test "return an integer and increments this integer by one" do
      assert 0 = Server.request_number()
      assert 1 = Server.request_number()
      assert 2 = Server.request_number()
      assert 3 = Server.request_number()
    end
  end

  describe "assign_prime/1" do
    test "assigns the integer to the Server's state" do
      assert :ok = Server.assign_prime(3)
      assert %{primes: [3]} = get_state(Server)
    end

    test "update the highest_prime attribute of the Server's state" do
      Server.assign_prime(3)
      assert %{highest_prime: 3} = get_state(Server)
    end
  end

  describe "status/0" do
    test "get the Server's state" do
      assert %{highest_prime: nil, primes: [], number: 0} == Server.status()
    end
  end

  describe "assign_worker/0" do
    setup do
      {:ok, supervisor_pid} =
        Supervisor.start_link(
          [{Task.Supervisor, name: Primy.TaskSupervisor}],
          strategy: :rest_for_one,
          name: Primy.ApplicationSupervisor
        )

      on_exit(fn -> assert true = Process.exit(supervisor_pid, :kill) end)
    end

    test "spawns a Worker process" do
      assert :ok = Server.assign_worker()
      assert [worker_pid] = wait_until(fn -> Task.Supervisor.children(Primy.TaskSupervisor) end)
      assert Process.alive?(worker_pid)

      assert Process.exit(worker_pid, :kill)
    end
  end

  defp get_state(Server) do
    Server
    |> Process.whereis()
    |> :sys.get_state()
  end

  # defp wait_until(func) when is_function(func) do
  #   case func.() do
  #     result when result == [] or is_nil(result) -> :timer.sleep(100) && func.()
  #     result -> result
  #   end
  # end
end
