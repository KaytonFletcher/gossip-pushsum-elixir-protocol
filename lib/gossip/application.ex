defmodule Gossip.Application do
  def spawn_workers(
        state = %{num_nodes: num_nodes, topology: topology, algorithm: algorithm},
        index \\ 0,
        nodes \\ []
      ) do
    if index == num_nodes do
      nodes
    else
      {:ok, pid} =
        Gossip.Worker.start_link(%{index: index, topology: topology, algorithm: algorithm})

      spawn_workers(state, index + 1, [pid | nodes])
    end
  end

  def parse_args(args) do
    if(length(args) != 3) do
      IO.inspect(args)
      raise(ArgumentError, "wrong number of arguments")
    else
      {num_nodes, _res} = Integer.parse(List.first(args))

      topology =
        case Enum.at(args, 1) do
          "full" ->
            :full

          "line" ->
            :line

          "rand2D" ->
            :rand2D

          "3dtorus" ->
            :torus3D

          "honeycomb" ->
            :honeycomb

          "randhoneycomb" ->
            :randhoneycomb

          bad_topology ->
            raise(ArgumentError, "topology provided is not an option: #{bad_topology}")
        end

      algorithm =
        case List.last(args) do
          "gossip" ->
            :gossip

          "push-sum" ->
            :push_sum

          bad_algorithm ->
            raise(ArgumentError, "algorithm provided is not an option: #{bad_algorithm}")
        end

      num_nodes =
        case topology do
          :torus3D ->
            ceil(:math.pow(num_nodes, 1 / 3))

          comb when comb in [:honeycomb, :randhoneycomb] ->
            t = ceil(:math.pow(num_nodes / 6, 1 / 2))
            trunc(:math.pow(t, 2) * 6)

          _topology ->
            num_nodes
        end

      IO.inspect(num_nodes)

      %{num_nodes: num_nodes, topology: topology, algorithm: algorithm}
    end
  end

  def main(args \\ []) do
    parsed_args =
      %{num_nodes: num_nodes, topology: topology, algorithm: algorithm} =
      case parse_args(args) do
        {_num, :ok, :ok} -> System.halt()
        :ok -> System.halt()
        args -> args
      end

    nodes = spawn_workers(parsed_args)

    case topology do
      top when top in [:torus3D, :honeycomb, :randhoneycomb] ->
        Gossip.Topology.get_neighbors(nodes, num_nodes, topology)

      _all ->
        Gossip.Topology.get_neighbors(nodes, topology)
    end

    {:ok, pid} = Gossip.Collector.start_link({num_nodes, System.monotonic_time(:millisecond)})

    # Sends a random node a message, starting the algorithm of choice
    case algorithm do
      :push_sum -> send(Enum.random(nodes), {:push_sum, %{s: 0, w: 0}})
      :gossip -> send(Enum.random(nodes), :gossip)
    end

    Process.monitor(pid)

    receive do
      {:DOWN, _ref, :process, _object, _reason} ->
        nil
    end
  end
end
