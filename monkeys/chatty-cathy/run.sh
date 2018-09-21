#!/bin/bash

ERROR_MSG="No-one is listening to chatty-cathy!"

phrases[0]="Just gotta hash it and cache it"
phrases[1]="Less talking man, more eating"
phrases[2]="It's possible that cheeseburger got into a weird state"
phrases[3]="Let’s move forward. Let’s not move back"
phrases[4]="Life goes on man... life goes on..."
phrases[5]="It’s okay man, rhotimatic, gotta get it man"
phrases[6]="Go to the max!"
phrases[7]="I went to the dentist today, and they had this really nice heater"

. $(dirname ${BASH_SOURCE})/helpers.bash

init_monkey

[ -z "$SLEEP" ] && {
	SLEEP="10"
}

[ -z "$INTERVAL" ] && {
	INTERVAL="0.2"
}

[ -z "$PORT" ] && {
	PORT="5000"
}

[ -z "$DST" ] && {
	DST="chatty-cathy-server"
}

endpoint_debug_enable

while :
do
	start_monitor
	start_tcpdump

	if [ "$POD_NAME" = "chatty-cathy-0" ]; then
		nc -l -p $PORT -v -v
	else
		echo "Starting up cathy chatting to $DST:$PORT"
		while true; do
			rand=$[$RANDOM % ${#phrases[@]}]
			echo -e ${phrases[$rand]}
			sleep $INTERVAL
		done | nc $DST $PORT -q 0 -k -v -v
	fi
	CODE=$?
	echo "$CODE"

	stop_monitor
	stop_tcpdump

	[ "$CODE" -ne "0" ] && {
		notify_slack "*$ERROR_MSG* (pod $HOSTNAME, exit code $CODE) :cry:"
		test_fail
		exit 1
	}

	sleep $SLEEP
done
