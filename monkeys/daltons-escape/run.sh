#!/bin/bash

. $(dirname ${BASH_SOURCE})/helpers.bash

init_monkey

[ -z "$URL" ] && {
	echo "URL not provided"
	exit 1
}

[ -z "$SLEEP" ] && {
	SLEEP="10"
}

endpoint_debug_enable

while :
do
	start_monitor
	start_tcpdump

	echo -n "Trying to escape ($URL): "

	time curl -s $CURL_OPTIONS $URL > /dev/null
	CODE=$?
	echo "$CODE"

	stop_monitor
	stop_tcpdump

	[ "$CODE" -eq "0" ] && {
		notify_slack ":fire: *:daltons: :daltons: :daltons: :daltons: ($HOSTNAME) has escaped!* :face_palm:"
		test_fail
		exit 1
	}

	sleep $SLEEP
done
