# Chaos Test: Tennis Match

![](https://github.com/cilium/chaos-monkeys/raw/master/monkeys/tennis-match/.img/match.jpg)

## Test Description

Continuously create and delete services in one pod. In another pod, consume these events from Kubernetes.
If the events from Kubernetes cannot be consumed due to the connection getting closed, the pod crashes.
This is intended to test the durability of Kubernetes Services plumbed into Cilium over a long period of
time.

## Configuration

* `SLEEP`: Sleep interval between attempts to create and delete services
