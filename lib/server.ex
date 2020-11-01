defmodule Primy.Server do
  use GenServer
  alias Primy.Worker

  def start_link(n \\ 0) do
    GenServer.start_link(__MODULE__, [n], name: __MODULE__)
  end

  def request_number do
    GenServer.call(__MODULE__, :request_number)
  end

  def assign_prime(n) do
    GenServer.cast(__MODULE__, {:assign_prime, n})
  end

  def highest_prime do
    GenServer.call(__MODULE__, :highest_prime)
  end

  def status do
    GenServer.call(__MODULE__, :status)
  end

  def assign_worker do
    GenServer.cast(__MODULE__, :assign_worker)
  end

  @impl GenServer
  def init([n]) do
    state = %{number: n, highest_prime: nil, worker_pid: nil, primes: []}
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
    {:ok, worker_pid} = Worker.start_link()
    state = %{state | worker_pid: worker_pid}

    {:noreply, state}
  end
end
