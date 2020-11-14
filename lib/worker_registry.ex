defmodule Primy.WorkerRegistry do
  use GenServer
  require Logger
  import Primy.Utils
  alias Primy.Server

  def start_link do
    start_link([])
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def register(worker_pid) do
    GenServer.cast({__MODULE__, server_addr()}, {:register, worker_pid})
  end

  def lookup(worker_pid) do
    GenServer.call({__MODULE__, server_addr()}, {:lookup, worker_pid})
  end

  def update(worker_pid, metadata) do
    GenServer.cast({__MODULE__, server_addr()}, {:update, worker_pid, metadata})
  end

  def unregister(worker_pid) do
    GenServer.cast({__MODULE__, server_addr()}, {:unregister, worker_pid})
  end

  @impl GenServer
  def init(_) do
    :ets.new(__MODULE__, [:set, :public, :named_table])
    state = %{}

    {:ok, state}
  end

  @impl GenServer
  def handle_cast({:register, worker_pid}, state) do
    _ref = Process.monitor(worker_pid)
    :ets.insert(__MODULE__, {worker_pid, [assigned_prime: nil, returned: false]})

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:update, worker_pid, metadata}, state) do
    :ets.insert(__MODULE__, {worker_pid, metadata})

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:unregister, worker_pid}, state) do
    do_unregister(worker_pid)

    {:noreply, state}
  end

  defp do_unregister(worker_pid) do
    :ets.delete(__MODULE__, worker_pid)
  end

  @impl GenServer
  def handle_call({:lookup, worker_pid}, _from, state) do
    entry = do_lookup(worker_pid)

    {:reply, entry, state}
  end

  defp do_lookup(worker_pid) do
    :ets.lookup(__MODULE__, worker_pid)
  end

  @impl GenServer
  def handle_info({:DOWN, _ref, :process, dead_worker_pid, _reason}, state) do
    case do_lookup(dead_worker_pid) do
      [{^dead_worker_pid, [assigned_number: assigned_number, returned: false]}] ->
        reassign_work(dead_worker_pid, assigned_number)

      [{^dead_worker_pid, [assigned_number: _assigned_number, returned: true]}] ->
        reassign_work(dead_worker_pid)

      _ ->
        nil
    end

    do_unregister(dead_worker_pid)

    {:noreply, state}
  end

  defp reassign_work(dead_worker_pid) do
    log_worker_death(dead_worker_pid)

    case Node.list() do
      [] ->
        Server.assign_worker()
        log_worker_birth(Node.self())

      nodes ->
        node = Enum.random(nodes)
        Node.spawn_link(node, Server, :assign_worker, [])
        log_worker_birth(node)
    end
  end

  defp reassign_work(dead_worker_pid, assigned_number) do
    log_worker_death(dead_worker_pid, assigned_number)

    case Node.list() do
      [] ->
        Server.assign_worker(assigned_number)
        log_worker_birth(Node.self(), assigned_number)

      nodes ->
        node = Enum.random(nodes)
        Node.spawn_link(node, Server, :assign_worker, [assigned_number])
        log_worker_birth(node, assigned_number)
    end
  end

  defp log_worker_death(dead_worker_pid) do
    IO.inspect(Server.status())

    Logger.warn("Worker #{inspect(dead_worker_pid)} died.")
  end

  defp log_worker_death(dead_worker_pid, assigned_number) do
    IO.inspect(Server.status())

    Logger.warn(
      "Worker #{inspect(dead_worker_pid)} died while checking if #{assigned_number} is prime."
    )
  end

  defp log_worker_birth(node, assigned_number) do
    Logger.warn(
      "Spawning new worker on node #{inspect(node)} with assigned number #{assigned_number}."
    )
  end

  defp log_worker_birth(node) do
    Logger.warn("Spawning new worker on node #{inspect(node)}.")
  end
end
