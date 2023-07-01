# Chaos Test: Arch-rivals

## Test Description

Consists of two pods continuously talking to each other while a network policy
is loaded that prevents access. Test fails if one pod can talk to another pod.

## Configuration

* `SLEEP`: Sleep interval between attempt to reach `URL`
* `CURL_OPTIONS`: Option passed on to curl
