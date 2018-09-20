# Chaos Test: drip-drop

![](https://github.com/cilium/chaos-monkeys/raw/master/monkeys/drip-drop/.img/drip-drop.jpg)

## Test Description

Connect to an external service and drip bytes back.

## Configuration

* `SLEEP`: Sleep interval between attempt to reach `URL`
* `PERIOD`: Time (in seconds) over which a response will be returned
* `BYTES`: Total number of bytes to request
