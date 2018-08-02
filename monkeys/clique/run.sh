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

echo "Sleeping 30 seconds for clique to establish"
sleep 30

if [ "$POD_NAME" = "chaos-clique-0" ]
then
	target="chaos-clique-second"
else
	target="chaos-clique-first"
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

	[ "$CODE" -ne "0" ] && {
		notify_slack ":fire: Clique ($HOSTNAME) can't chat anymore!* (exit code $CODE) :face_palm:"
		test_fail
		exit 1
	}

	sleep $SLEEP
done
