alias Primy.{Server, WorkerRegistry, Worker, Prime}

# fetch the server_addr from the SERVER_ADDR env variable
server =
  case System.get_env("SERVER_ADDR") do
    nil -> nil
    server_addr -> String.to_atom(server_addr)
  end

# if the current node addr is not the server one
# it means the current node is a worker.
# connects to the server node and return Node.self/0 for testing convenience in IEx
worker = if server && Node.self() != server, do: Node.connect(server) && Node.self()
