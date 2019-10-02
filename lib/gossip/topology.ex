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

  def get_neighbors(nodes, num_nodes, :honeycomb) do
    t = trunc(:math.pow(div(num_nodes, 6), 1 / 2))
    assign_coords(t, nodes)
  end

  def get_neighbors(nodes, num_nodes, :torus3D) do
    x = trunc(:math.pow(num_nodes, 1 / 3))
    cube = Enum.chunk_every(Enum.chunk_every(nodes, x), x)
    decomp(cube)
  end

  def get_neighbors(nodes, num_nodes, :randhoneycomb) do
    not_neighbors = get_neighbors(nodes, num_nodes, :honeycomb)

    Enum.each(not_neighbors, fn {pid, other} ->
      pid2 = Enum.random(Enum.filter(other, &(!is_nil(&1))))
      Gossip.Worker.add_neighbors(pid, [pid2])
      Gossip.Worker.add_neighbors(pid2, [pid])
    end)
  end

  def assign_coords(t, nodes) do
    # range of possible u,v,w values
    range = (-t + 1)..t

    coords =
      for u <- range, v <- range, w <- range, u + v + w <= 2, u + v + w >= 1 do
        {u, v, w}
      end

    li = Enum.zip(nodes, coords)

    for elem = {pid1, {u1, v1, w1}} <- li do
      {pid1,
       for {pid2, {u2, v2, w2}} <- li -- [elem] do
         if(abs(u1 - u2) + abs(v1 - v2) + abs(w1 - w2) === 1) do
           Gossip.Worker.add_neighbors(pid1, [pid2])
           nil
         else
           pid2
         end
       end}
    end
  end

  def decomp([h | t]) when is_list(h) do
    decomp(h)
    decomp(t)

    for x <- List.flatten([h]), y <- List.flatten(t) do
      Gossip.Worker.add_neighbors(x, [y])
      Gossip.Worker.add_neighbors(y, [x])
    end
  end

  def decomp(_elem), do: nil
end
