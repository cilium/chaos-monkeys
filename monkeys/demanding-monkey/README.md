# Chaos Test: Demanding Monkey 

![](https://github.com/cilium/chaos-monkeys/raw/master/monkeys/demanding-monkey/.img/impatience.jpg)

## Test Description

Continuously queries a URL and the Kubernetes API server. If requests fail or take above a certain amount of time,
will fail.

## Configuration

* `MAXTIMEOUT`: if the entire request takes longer than this amount of time (in seconds), will be considered a failure. 
* `CONNECTTIMEOUT`: if a request takes longer than this amount of time (in seconds) to connect, will be considered a failure.
* `SLEEP`: time to sleep after both calls to Kubernetes and URL have completed.
