# Primy

https://people.kth.se/~johanmon/dse/primy.pdf

Primy is a distributed prime number generator. It can run on one single machine or on several machines.

# I want to run Primy on a single machine / on a single node

First, fire up IEx
```bash
$ iex -S mix
```

Once in IEx, you can call the `Server.assign_worker/0` function to boot up a `Task` that will generate indefinitely a prime number.
You can check the Server's status by calling `Server.status/0` to find out what is the highest prime number found so far and which primes have been found so far:
```elixir
iex(1)> Server.assign_worker()
:ok
iex(2)> Server.status()
%{
  highest_prime: 292223,
  number: 292226,
  primes: [292223, 292183, 292181, 292157, 292147, 292141, 292133, 292093,
   292091, 292081, 292079, 292069, 292057, 292037, 292027, 292021, 291997,
   291983, 291979, 291971, 291923, 291901, 291899, 291887, 291877, 291869,
   291857, 291853, 291833, 291829, 291817, 291791, 291779, 291751, 291743,
   291727, 291721, 291701, 291691, 291689, 291677, 291661, 291649, 291647,
   291619, 291569, 291563, ...]
}
```

# I want to run Primy on multiple machines / on several nodes

For the sake of the example, let's say that you have two machines.
- the **machine A** will run one node, the server.
- the **machine B** will run three nodes, the workers.

You need to find the IP addresses of each machines. One way to do that (at least on Ubuntu), is to use the `hostname` command. Run this command first on **machine A** to get the server's address:
```bash
$ hostname -I
192.168.122.236 172.20.0.2 172.19.0.2 172.18.0.2 172.21.0.2 172.17.0.2 2a02:908:5b0:9060:e4c2:cff7:9d08:9e08 2a02:908:5b0:9060:8f69:a8b1:fdf4:aaf9
```

`hostname -I` displays a list of IP addresses. Take the first one.
Next, fire up IEx with a `SERVER_ADDR` environment variable:
```bash
SERVER_ADDR=192.168.122.236 iex --name server@192.168.122.236 --cookie primy -S mix
```

The server is now ready! Other nodes can connect to the server to create a cluster.


On your **machine B**, you will need three terminal tabs/windows each one representing a node connected to the server. If you do not have physical access to another computer, you can try to SSH into some instance in the cloud. As with the server, first find out the IP address of **machine B**:
```bash
$ hostname -I
192.168.122.276 172.20.0.4 172.19.0.4 172.18.0.4 172.21.0.4 172.17.0.4 2a02:908:5b0:9060:e4c2:caf7:9d08:9e08 2a02:908:5b0:9060:8e69:a8c1:fdf8:aaf9
```

Now fire up the first node in the first terminal tab/window with the server's and worker's addresses like so:
```bash
# on terminal tab or window n°1
SERVER_ADDR=192.168.122.236 iex --name worker1@192.168.122.276 --cookie primy -S mix
```

Do this for the two other terminal tabs/windows by just changing the name of the worker:
```bash
# on terminal tab or window n°2
SERVER_ADDR=192.168.122.236 iex --name worker2@192.168.122.276 --cookie primy -S mix
```
```bash
# on terminal tab or window n°3
SERVER_ADDR=192.168.122.236 iex --name worker3@192.168.122.276 --cookie primy -S mix
```

The code in `.iex.exs` will automatically connect the workers to the server and aliasing some modules:
```elixir
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
```

To verify that everything went well, go back to **machine A** and run the `Node.list/0` function to display the connected nodes:
```elixir
iex(:"server@192.168.122.236")1> Node.list()
[:"worker1@192.168.122.276", :"worker2@192.168.122.276", :"worker3@192.168.122.276"]
```

Nice! As you can see, the three workers are effectively connected to the server.
Now it's time to assign some work to those workers.
On whatever machines/terminal tabs or windows, simply call the function `Server.assign_worker/0` (let's say you call this function three times so that we have three worker tasks generating prime numbers):
```elixir
iex(:"server@192.168.122.236")2> Server.assign_worker()
:ok
iex(:"server@192.168.122.236")3> Server.assign_worker()
:ok
iex(:"server@192.168.122.236")4> Server.assign_worker()
:ok
```

You can also call here the `Server.status` function:
```elixir
iex(:"server@192.168.122.236")1> Server.status()
%{
  highest_prime: 329687,
  number: 329801,
  primes: [329687, 329683, 329663, 329677, 329671, 329657, 329639, 329627,
   329617, 329629, 329603, 329597, 329591, 329587, 329551, 329557, 329533,
   329489, 329519, 329503, 329473, 329471, 329419, 329431, 329393, 329401,
   329387, 329347, 329333, 329321, 329317, 329309, 329297, 329299, 329293,
   329281, 329269, 329267, 329257, 329233, 329243, 329209, 329207, 329191,
   329201, 329177, 329167, ...]
}
```

Now run the observer and inspect the architecture of the app:
```elixir
iex(:"server@192.168.122.236")1> :observer.start()
:ok
```

Inspect what happens in each differet nodes of the cluster.

Try to kill a task process and see what happens. The task process is immediately respawned and pick up where it left off!

You can also kill some node. If a worker node dies, another worker node will be reassigned the work of the dead node. If no worker nodes are alive, the work will be reassigned to the server node!
