# Chaos Test: Apple Tree

## Test Description

This monkey has two pods: a controller which adds and deletes CIDR policies
which refer to the same CIDR, and another pod which the CIDR policy selects,
which queries the CIDR allowed by the policy. The monkey will complain via Slack
if it cannot connect to the external CIDR.

## Configuration

* `MAXTIMEOUT`: if the entire request takes longer than this amount of time (in seconds), will be considered a failure. 
* `CONNECTTIMEOUT`: if a request takes longer than this amount of time (in seconds) to connect, will be considered a failure.
* `SLEEP`: time to sleep after both calls to Kubernetes and URL have completed.
