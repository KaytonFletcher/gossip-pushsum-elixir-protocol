defmodule Gossip.Topology do

  


  def get_neighbors(nodes, :rand2D) do
    new_nodes =
      Map.new(nodes, fn pid -> {pid, {Enum.random(0..100) / 100, Enum.random(0..100) / 100}} end)

    for pid <- nodes, pid2 <- nodes -- [pid] do
      {x1, y1} = new_nodes[pid]
      {x2, y2} = new_nodes[pid2]
      dist = :math.sqrt(:math.pow(x2 - x1, 2) + :math.pow(y2 - y1, 2))
      if(dist < 0.1) do
        Gossip.Worker.add_neighbors(pid, [pid2])
      end
    end
  end

  def get_neighbors(nodes, :full) do
    Enum.each(nodes, fn pid ->
      Gossip.Worker.add_neighbors(pid, List.delete(nodes, pid))
    end)
  end

  def get_neighbors(nodes, :line) do
    get_neighbors(List.first(nodes), nodes, :line)
  end
  
  def get_neighbors(nodes, num_nodes, :torus3D) do
    Enum.chunk_every(enumerable, count)Enum.chunk_every(nodes, div(num_nodes, 3))
    
  end

  def get_neighbors(pid, nodes, :line) do
    case nodes do
      [] ->
        nil

      [_hd] ->
        nil

      [hd | [curr | [next | tl]]] ->
        if(pid == hd) do
          Gossip.Worker.add_neighbors(pid, [curr])
          get_neighbors(curr, nodes, :line)
        else
          Gossip.Worker.add_neighbors(pid, [hd, next])
          get_neighbors(next, [curr | [next | tl]], :line)
        end

      [hd | _tl] ->
        Gossip.Worker.add_neighbors(pid, [hd])
    end
  end
end
