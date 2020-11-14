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
        Logger.warn(
          "Worker #{inspect(dead_worker_pid)} died while checking if #{assigned_number} is prime."
        )

        Logger.warn(
          "Spawning new worker with assigned number #{assigned_number} to replace #{
            inspect(dead_worker_pid)
          }"
        )

        Server.assign_worker(assigned_number)
        IO.inspect(Server.status())

      [{^dead_worker_pid, [assigned_number: _assigned_number, returned: true]}] ->
        Server.assign_worker()

      _ ->
        nil
    end

    do_unregister(dead_worker_pid)

    {:noreply, state}
  end
end
