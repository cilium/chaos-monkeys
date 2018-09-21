#!/bin/bash

URL="httpbin.org"
ERROR_MSG="$URL stopped dripping responses back!"

. $(dirname ${BASH_SOURCE})/helpers.bash

init_monkey

[ -z "$SLEEP" ] && {
	SLEEP="10"
}

endpoint_debug_enable

while :
do
	start_monitor
	start_tcpdump

	DST="http://$URL/drip?duration=$PERIOD&numbytes=$BYTES&code=200"
	echo "Curling \"$DST\"..."
	curl -s -X GET "$DST" -H "accept: application/octet-stream"
	CODE=$?
	echo "$CODE"

	stop_monitor
	stop_tcpdump

	[ "$CODE" -ne "0" ] && {
		notify_slack ":wrench: :droplet: *$ERROR_MSG* (pod $HOSTNAME, exit code $CODE)"
		test_fail
		exit 1
	}

	sleep $SLEEP
done
