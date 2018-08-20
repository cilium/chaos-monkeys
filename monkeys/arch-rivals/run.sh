#!/bin/bash

. $(dirname ${BASH_SOURCE})/helpers.bash

init_monkey

[ -z "$SLEEP" ] && {
	SLEEP="10"
}

# run simple http server for other pod to connect to
RESPONSE="HTTP/1.1 200 OK\r\nConnection: keep-alive\r\n\r\n${2:-"OK"}\r\n"
while { echo -e "$RESPONSE"; } | nc -l -s 0.0.0.0 -p 80 -q 1 > /dev/null; do
	:
done &

endpoint_debug_enable

echo "Sleeping 30 seconds for arch-rivals to establish"
sleep 30

if [ "$POD_NAME" = "chaos-arch-rivals-0" ]
then
	target="chaos-arch-rivals-wario"
else
	target="chaos-arch-rivals-mario"
fi

while :
do
	start_monitor
	start_tcpdump

	echo -n "Trying to talk to $target: "

	time curl -s $CURL_OPTIONS $target> /dev/null
	CODE=$?
	echo "$CODE"

	stop_monitor
	stop_tcpdump

	[ "$CODE" -eq "0" ] && {
		notify_slack ":fire: *Arch-rival $target took a hit from $HOSTNAME!* (exit code $CODE) :face_with_head_bandage:"
		test_fail
		exit 1
	}

	sleep $SLEEP
done
