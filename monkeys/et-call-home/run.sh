#!/bin/bash

[ -z "$SLACK_HOOK" ] && {
	echo "SLACK_HOOK not provided"
	exit 1
}

[ -z "$URL" ] && {
	echo "URL not provided"
	exit 1
}

[ -z "$SLEEP" ] && {
	SLEEP="10"
}

ENDPOINT_IP=$(ip -4 a list dev eth0 | grep inet |  grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | head -1)
ENDPOINT_ID=$(cilium endpoint list | grep $ENDPOINT_IP | cut -d' ' -f 1)
cilium endpoint config $ENDPOINT_ID debug=true

while :
do
	TMP=$(mktemp)
	cilium monitor -v > $TMP&
	MONITOR_PID=$!

	echo -n "Trying to call home ($URL): "

	time curl -s $CURL_OPTIONS 10 $URL > /dev/null
	CODE=$?
	echo "$CODE"

	kill $MONITOR_PID || true
	sleep 2
	kill -9 $MONITOR_PID 2> /dev/null || true

	[ "$CODE" -ne "0" ] && {
		MSG="{\"text\": \":fire: *E.T. ($HOSTNAME) cannot call home!* (exit code $CODE) :face_palm:\"}"
		curl -XPOST -d "$MSG" $SLACK_HOOK

		echo 'Monitor log:'
		cat $TMP
		rm $TMP
		exit 1
	}

	rm $TMP

	sleep $SLEEP
done
