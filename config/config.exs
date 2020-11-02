import Mix.Config

server_addr = System.get_env("SERVER_ADDR")

config :primy,
  server_addr: if(server_addr, do: String.to_atom(server_addr), else: :nonode@nohost)
