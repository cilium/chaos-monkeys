# Chaos Test: Clique

![](https://github.com/cilium/chaos-monkeys/raw/master/monkeys/clique/.img/click.png)

## Test Description

Consists of two pods continuosly talking to each other
Test fails if one pod cannot talk to the other pod.

## Configuration

* `URL`: External URL to reach out to
* `SLEEP`: Sleep interval between attempt to reach `URL`
* `CURL_OPTIONS`: Option passed on to curl
