# Chaos Test: Shuffler

![](https://github.com/cilium/chaos-monkeys/raw/master/monkeys/shuffler/.img/shuffler.jpg)

## Test Description

Creates a deployment which manages the lifecycle of one service, shuffler, and 
two StatefulSets, shuffler-client, and shuffler-server. The server StatefulSet
creates pods that are Kubernetes Endpoints (backends) for the aforementioned
shuffler service. The client communicates to the servers via the shuffler 
Service IP. While this communication is ongoing, the deployment does the
following in an infinite loop:

* Scales the StatefulSet to contain more pods to ensure that scale-up events do
not affect existing connections via Service IPs
* Scales down all clients so that no clients are running. This is done because
the servers have to be scaled down, and we do not want to create noise by
causing client crashes due to scale-down events.
* Scales down the Endpoints / server StatefulSet back to their original amount. 
* Restarts the client, which reaches out to one of the servers.

If the client crashes, will complain and alert via Slack.

## Configuration

* `SLEEP`: Sleep interval between attempts to create and delete services
