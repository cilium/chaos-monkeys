# Chaos Test: E.T. calls home FQDN Edition

![](https://github.com/cilium/chaos-monkeys/raw/master/monkeys/et-call-home/.img/et.jpg)

## Test Description

Continuously reaches to an external URL to allow E.T. to call home while an
FQDN policy allows for it. Test fails if a request to the external URL is *not*
successful.

## Configuration

* `URL`: External URL to reach out to
* `SLEEP`: Sleep interval between attempt to reach `URL`
* `CURL_OPTIONS`: Option passed on to curl
