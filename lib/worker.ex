defmodule Primy.Worker do
  use Task
  alias Primy.{Prime, Server, WorkerRegistry}

  def start_link(_) do
    start_link()
  end

  def start_link() do
    Task.start_link(__MODULE__, :init, [])
  end

  def init() do
    WorkerRegistry.register(self())
    run()
  end

  def init(n) do
    WorkerRegistry.register(self())
    run(n)
  end

  def run() do
    Server.request_number()
    |> do_run()
  end

  def run(n) do
    do_run(n)
  end

  defp do_run(n) do
    WorkerRegistry.update(self(), assigned_number: n, returned: false)

    case Prime.is_prime?(n) do
      true ->
        Server.assign_prime(n)
        WorkerRegistry.update(self(), assigned_number: n, returned: true)
        run()

      false ->
        run()
    end
  end
end
