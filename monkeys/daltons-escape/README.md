# Chaos Test: The Daltons Escape

![](https://github.com/cilium/chaos-monkeys/raw/master/monkeys/daltons-escape/.img/daltons-escape.jpg)

## Test Description

Continuously reaches to an external URL while a network policy is loaded that
prevents access. Test fails if a request to the external URL is successful.

## Configuration

* `URL`: External URL to reach out to
* `SLEEP`: Sleep interval between attempt to reach `URL`
* `CURL_OPTIONS`: Option passed on to curl
