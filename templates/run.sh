#!/bin/bash

ERROR_MSG="TODO: Update the error message"

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

	# **TODO**: populate '$?' by running a legitimate command
	test_fail
	CODE=$?
	echo "$CODE"

	stop_monitor
	stop_tcpdump

	[ "$CODE" -ne "0" ] && {
		notify_slack ":fire: *$ERROR_MSG* (pod $HOSTNAME, exit code $CODE) :face_palm:"
		test_fail
		exit 1
	}

	sleep $SLEEP
done
