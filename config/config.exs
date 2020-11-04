import Config

server_addr =
  case System.get_env("SERVER_ADDR") do
    nil -> Node.self()
    server_addr -> String.to_atom(server_addr)
  end

config :primy,
  server_addr: server_addr

import_config "#{Mix.env()}.exs"
