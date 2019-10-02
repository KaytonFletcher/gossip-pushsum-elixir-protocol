defmodule Gossip.Worker do
  use GenServer, restart: :transient

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, [])
  end

  # init function for gossip algorithm
  @impl GenServer
  def init(%{algorithm: :gossip, index: _index}) do
    {:ok, %{data: %{times_heard: 0}, neighbors: []}}
  end

  # init function for push sum algorithm
  @impl GenServer
  def init(%{index: index, algorithm: :push_sum}) do
    IO.puts(index)
    {:ok, %{data: %{sum: index, weight: 1, repeated: 0, ratio: index}, neighbors: []}}
  end

  def add_neighbors(pid, nodes) do
    :ok = GenServer.call(pid, {:add_neighbors, nodes})
  end

  @impl GenServer
  def handle_call({:add_neighbors, nodes}, _from, %{data: data, neighbors: neighbors}) do
    new_state = %{data: data, neighbors: nodes ++ neighbors}
    {:reply, :ok, new_state}
  end

  def handle_info(_anything, %{data: _data, neighbors: []}) do
    Gossip.Collector.finished(false)
    {:stop, :normal, nil}
  end

  def handle_info(:next_round, %{data: %{times_heard: times_heard}, neighbors: neighbors}) do
    send(Enum.random(neighbors), :gossip)
    Process.send_after(self(), :next_round, 500)

    {:noreply, %{data: %{times_heard: times_heard}, neighbors: neighbors}}
  end

  # message handling for gossip from one node to another
  @impl GenServer
  def handle_info(:gossip, %{data: %{times_heard: times_heard}, neighbors: neighbors}) do
    if(times_heard == 0) do
      Process.send_after(self(), :next_round, 500)
    end

    if(times_heard + 1 == 10) do
      remove_self_from_neighbors(neighbors)
      Gossip.Collector.finished(true)
      {:stop, :normal, nil}
    else
      # Increments the number of times this node has heard the message
      {:noreply, %{data: %{times_heard: times_heard + 1}, neighbors: neighbors}}
    end
  end

  @impl GenServer
  def handle_info({:push_sum, %{s: sent_s, w: sent_w}}, %{
        data: %{sum: s, weight: w, repeated: t, ratio: r},
        neighbors: neighbors
      }) do
    new_s = (s + sent_s) / 2
    new_w = (w + sent_w) / 2
    new_r = new_s / new_w

    if(abs(new_r - r) < :math.pow(10, -10)) do
      if(t + 1 == 3) do
        remove_self_from_neighbors(neighbors)
        Enum.each(neighbors, fn pid ->
          Process.send(pid, {:push_sum, %{s: 0, w: 0}}, [])
        end)
        Gossip.Collector.finished(true)
        {:stop, :normal, nil}
      else
        Process.send(Enum.random(neighbors), {:push_sum, %{s: new_s, w: new_w}}, [])

        {:noreply,
         %{
           data: %{sum: new_s, weight: new_w, repeated: t + 1, ratio: new_r},
           neighbors: neighbors
         }}
      end
    else
      Process.send(Enum.random(neighbors), {:push_sum, %{s: new_s, w: new_w}}, [])
      {:noreply,
       %{
         data: %{sum: new_s, weight: new_w, repeated: 0, ratio: new_r},
         neighbors: neighbors
       }}
    end
  end

  @impl GenServer
  def handle_cast({:remove, pid}, %{data: data, neighbors: neighbors}) do
    {:noreply, %{data: data, neighbors: List.delete(neighbors, pid)}}
  end

  def remove_self_from_neighbors(neighbors) do
    Enum.each(neighbors, fn pid ->
      GenServer.cast(pid, {:remove, self()})
    end)
  end
end
