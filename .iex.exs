alias Primy.{Server, WorkerRegistry, Worker, Prime}

# fetch the server_addr from the SERVER_ADDR env variable
server = "SERVER_ADDR" |> System.get_env() |> String.to_atom()

# if the current node addr is not the server one
# it means the current node is a worker.
# connects to the server node and return Node.self/0 for testing convenience in IEx
worker = if Node.self() != server, do: Node.connect(server) && Node.self()
