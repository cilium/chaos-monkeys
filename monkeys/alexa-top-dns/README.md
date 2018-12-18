# Chaos Test: alexa-top-dns

![](https://github.com/cilium/chaos-monkeys/raw/master/monkeys/alexa-top-dns/.img/alexa-top-dns.jpg)

## Test Description

This monkey tries to reach 100 most popular domains with toFQDNs rule allowing
all traffic active.

## Configuration

* `SLEEP`: Sleep interval between attempt to reach 100 top alexa sites
