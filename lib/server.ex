defmodule Primy.Server do
  use GenServer

  alias Primy.Worker
  import Primy.Utils

  def start do
    DynamicSupervisor.start_child(Primy.DynamicSupervisor, Primy.Server)
  end

  def start_link do
    start_link([])
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [0])
  end

  def request_number do
    GenServer.call(random_server_pid(), :request_number)
  end

  def assign_prime(n) do
    GenServer.cast(random_server_pid(), {:assign_prime, n})
  end

  def highest_prime do
    GenServer.call(random_server_pid(), :highest_prime)
  end

  def status do
    GenServer.call(random_server_pid(), :status)
  end

  def assign_worker do
    GenServer.cast(random_server_pid(), :assign_worker)
  end

  def assign_worker(n) do
    GenServer.cast(random_server_pid(), {:assign_worker, n})
  end

  @impl GenServer
  def init([n]) do
    state = %{number: n, highest_prime: nil, primes: []}
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
  def handle_cast(:assign_worker, state) do
    {:ok, _worker_pid} = do_assign_worker()

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:assign_worker, n}, state) do
    {:ok, _worker_pid} = do_assign_worker([n])

    {:noreply, state}
  end

  defp do_assign_worker(arg \\ []) do
    Task.Supervisor.start_child(
      {Primy.TaskSupervisor, worker_addr()},
      Worker,
      :init,
      arg
    )
  end
end
