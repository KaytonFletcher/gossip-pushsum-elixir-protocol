defmodule Gossip.Collector do
  use GenServer
  @me Gossip.Collecter

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, [name: @me])
  end

  @impl GenServer
  def init(num_nodes) do
    {:ok, {num_nodes, 0}}
  end

  # client
  def finished() do
    GenServer.cast(@me, :finished)
  end

  # server
  @impl GenServer
  def handle_cast(:finished, {num_nodes, nodes_finished}) do
    if(num_nodes == nodes_finished + 1) do
      IO.puts("APP FINISHED")
      System.halt(0)
      #{:stop, :normal, nil}
    else
      IO.inspect(nodes_finished+1, label: "finished")
      {:noreply, {num_nodes, nodes_finished+1}}
    end
  end
end
