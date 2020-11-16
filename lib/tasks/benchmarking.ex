defmodule Mix.Tasks.Primy.Benchmarking do
  use Mix.Task
  alias Primy.Server

  @app_dir "_build/dev/lib/primy/ebin"

  def run([]) do
    run(100, 5_000)
  end

  def run([n]) do
    n = String.to_integer(n)
    run(n, 5_000)
  end

  def run([n, t]) do
    n = String.to_integer(n)
    t = String.to_integer(t)

    run(n, t)
  end

  def run(n, t) do
    true = Code.prepend_path(@app_dir)
    :ok = Application.start(:primy)
    for _ <- 1..n, do: Server.assign_worker()
    :timer.sleep(t)
    status = Server.status()
    Application.stop(:primy)

    append_to_file(filename(), content(status, n, t))
  end

  defp append_to_file(filename, content) do
    {:ok, file} = File.open(filename, [:append])
    IO.binwrite(file, content)
    File.close(file)
  end

  defp filename do
    today = Date.utc_today() |> Date.to_string()
    "benchmarking-" <> today <> ".txt"
  end

  defp content(status, n, t) do
    """
    #{Date.utc_today() |> Date.to_string()}
    Benchmarking Primy.Server
    Number of spawned worker: #{n}
    Duration: #{t} milliseconds
    Highest prime found in duration: #{status.highest_prime}

    """
  end
end
