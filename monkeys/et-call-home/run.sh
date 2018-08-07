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

	echo -n "Trying to call home ($URL): "

	time curl -4 -s $CURL_OPTIONS 10 $URL > /dev/null
	CODE=$?
	echo "$CODE"

	stop_monitor
	stop_tcpdump

	[ "$CODE" -ne "0" ] && {
		notify_slack ":fire: *E.T. ($HOSTNAME) cannot call home!* (exit code $CODE) :face_palm:"
		test_failed
		exit 1
	}

	sleep $SLEEP
done
