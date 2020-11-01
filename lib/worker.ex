defmodule Primy.Worker do
  use Task
  alias Primy.{Prime, Server}

  def start_link() do
    Task.start_link(__MODULE__, :init, [])
  end

  def init() do
    run()
  end

  def run() do
    n = Server.request_number()

    case Prime.is_prime?(n) do
      true ->
        Server.assign_prime(n)
        run()

      false ->
        run()
    end
  end
end
