# Chaos Test: fqdn-s3

![](https://github.com/cilium/chaos-monkeys/raw/master/monkeys/fqdn-s3/.img/fqdn-s3.jpg)

## Test Description

This test make a HTTP HEAD call to a S3 file with a FQDN policy.

The reason for this test is to verify that a new IP is added to the allowed list
quickly enough to allow a HTTP connection.

## Configuration

* `SLEEP`: Sleep interval between attempt to reach `URL`
* `CONNECTTIMEOUT`: The time that a connection will be drop. Default 5
* `TARGETURL`: The target url to validate that the DNS works correctly.

## Notes:

* This monkey should create a lot of new identities, for cleanup in a faster
  way, `--tofqdns-min-ttl` can be used to force lower expire time.
