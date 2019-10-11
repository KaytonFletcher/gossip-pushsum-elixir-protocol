# Project 2: Gossip Simulator

**This program prints the time of convergence, and completion rate (more on this later) of networks using the push-sum and gossip algorithms with various topological configurations**
## Running the program

To run use the command:  

```./my_program numNodes topology algorithm```

Where: 
 **numNodes -** The number of nodes in the network

**topology -** choice between full, line, rand2D, 3Dtorus, honeycomb and randhoneycomb. The topology determines how the nodes are connected to each other. Realistically this means it determines what neighbors the nodes are aware of. 

**algorithm -** choice between gossip and push-sum. The gossip algorithm passing a rumor (message) from node to node until all nodes have heard the rumor 10 times. Push-sum computes the average value from the values stored at each node in the network. Ending when each node has an estimate of the average that has not changed by 10^-10 in 3 rounds of the algorithm.

### Topology Caveats 
For the 3Dtorus topology, the number of nodes will be rounded up to a cubic number. Ex. A numNodes of 29 or 60 would get rounded to 64 (4^3)

For both honeycomb topologies, numNodes is rounded to the nearest "complete" honeycomb. These come in the form 6t^2 (6, 24, 54, etc...), where t is the last "layer" of the honeycomb. This enabled me to use a 3 coordinate system without worrying about incomplete honeycomb "layers".

For rand2D, small numbers of nodes < 400 may fail to run. Due to the randomness of the neighbors of each node, a node may be generated without any neighbors at all. If this happens, it will never be a part of the gossip or aggregation, and thus the algorithm will not be able to complete.

### Algorithm Caveats
For both gossip and push-sum, when a node reaches its termination condition, it is removed from the network (the reference other nodes have to it are removed). This means that often a node will run out of neighbors to send a message to, before reaching its own ending condition. When a node goes to send a message, it is terminated prematurely if it has no neighbors. This is not necessarily a failure of the algorithm, but it is a necessary condition to have in some form. **The percentage of nodes that reach the proper ending condition is printed as the completion rate.**

## Performance

Largest network ran for each algorithm and topology:

gossip full: 1000
gossip line: 1000
gossip rand2D: 10000
gossip 3Dtorus: 
gossip honeycomb 
gossip randhoneycomb

push-sum full: 1000
push-sum line: 1000	
push-sum rand2D: 6000
push-sum 3Dtorus: 300000 WOW
push-sum honeycomb: 1500 
push-sum randhoneycomb: 3000

**I measured the time by getting the system time before sending a message to a random node. I then got the system time once the last node had converged and subtracted the two times**