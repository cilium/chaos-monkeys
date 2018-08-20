# Chaos Test: Arch-rivals

![Mario VS Wario - N64 EDITION](https://github.com/cilium/chaos-monkeys/raw/master/monkeys/arch-rivals/.img/arch-rivals.png)

<sup>"Mario VS Wario - N64 EDITION" (C) 2016 [QuickestMario](https://www.deviantart.com/quickestmario), distributed under
Creative Commons [Attribution-ShareAlike 3.0 Unported \(CC BY-SA 3.0\)](https://creativecommons.org/licenses/by-sa/3.0/) license.</sup>

## Test Description

Consists of two pods continuously talking to each other while a network policy
is loaded that prevents access. Test fails if one pod can talk to another pod.

## Configuration

* `SLEEP`: Sleep interval between attempt to reach `URL`
* `CURL_OPTIONS`: Option passed on to curl
