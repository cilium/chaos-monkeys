# Chaos Test: chatty-cathy

![](https://github.com/cilium/chaos-monkeys/raw/master/monkeys/chatty-cathy/.img/chatty-cathy.jpg)

## Test Description

Continously send traffic from one pod to another pod via a service IP. Test
fails if the connection is interrupted.

## Configuration

* `SLEEP`: Sleep interval between tests
* `INTERVAL`: Sleep interval between traffic bursts
* `DST`: The endpoint to constantly send messages to
* `PORT`: The port on the endpoint to send messages to (default: 5000)
