defmodule Primy.Server do
  use GenServer
  alias Primy.Worker
  require Logger

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, [0], name: name)
  end

  def request_number do
    GenServer.call({__MODULE__, server_addr()}, :request_number)
  end

  def assign_prime(n) do
    GenServer.cast({__MODULE__, server_addr()}, {:assign_prime, n})
  end

  def highest_prime do
    GenServer.call({__MODULE__, server_addr()}, :highest_prime)
  end

  def status do
    GenServer.call({__MODULE__, server_addr()}, :status)
  end

  def assign_worker do
    GenServer.cast({__MODULE__, server_addr()}, :assign_worker)
  end

  @impl GenServer
  def init([n]) do
    state = %{number: n, highest_prime: nil, worker_pids: [], primes: []}
    {:ok, state}
  end

  @impl GenServer
  def handle_call(:highest_prime, _from, %{highest_prime: highest_prime} = state) do
    {:reply, highest_prime, state}
  end

  @impl GenServer
  def handle_call(:request_number, _from, %{number: n} = state) do
    state = %{state | number: n + 1}
    {:reply, n, state}
  end

  @impl GenServer
  def handle_call(:status, _from, state) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_cast({:assign_prime, n}, %{primes: primes} = state) do
    primes = [n | primes]
    highest_prime = Enum.max(primes)
    state = %{state | primes: primes, highest_prime: highest_prime}
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:assign_worker, %{worker_pids: worker_pids} = state) do
    {:ok, worker_pid} =
      Task.Supervisor.start_child(
        {Primy.TaskSupervisor, worker_addr()},
        Worker,
        :run,
        []
      )

    state = %{state | worker_pids: [worker_pid | worker_pids]}

    {:noreply, state}
  end

  defp server_addr do
    Application.get_env(:primy, :server_addr)
  end

  defp worker_addr do
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
end
