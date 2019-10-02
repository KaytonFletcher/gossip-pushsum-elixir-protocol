defmodule Gossip.Collector do
  use GenServer
  @me Gossip.Collecter

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: @me)
  end

  @impl GenServer
  def init({num_nodes, start_time}) do
    {:ok, {num_nodes, start_time, 0, 0}}
  end

  # client
  def finished(is_success) do
    GenServer.cast(@me, {:finished, is_success})
  end

  # server
  @impl GenServer
  def handle_cast({:finished, is_success}, {num_nodes, start_time, nodes_finished, num_success}) do
    if(num_nodes == nodes_finished + 1) do
      IO.inspect(num_success/nodes_finished * 100, label: "percentage that met end condition")
      IO.inspect(System.monotonic_time(:millisecond) - start_time, label: "Convergence Time")
      System.halt(0)
    else
      if(is_success) do
        {:noreply, {num_nodes, start_time, nodes_finished + 1, num_success + 1}}
      else
        {:noreply, {num_nodes, start_time, nodes_finished + 1, num_success}}
      end

    end
  end
end
