#!/bin/bash

[ -z "$SLACK_HOOK" ] && {
	echo "SLACK_HOOK not provided"
	exit 1
}

[ -z "$SLEEP" ] && {
	SLEEP="10"
}

# run simple http server for other pod to connect to
RESPONSE="HTTP/1.1 200 OK\r\nConnection: keep-alive\r\n\r\n${2:-"OK"}\r\n"
while { echo -e "$RESPONSE"; } | nc -l -s 0.0.0.0 -p 80 -q 1 > /dev/null; do
	:
done &

#make sure other pod is also up
sleep 30

ENDPOINT_IP=$(ip -4 a list dev eth0 | grep inet |  grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | head -1)
ENDPOINT_ID=$(cilium endpoint list | grep $ENDPOINT_IP | cut -d' ' -f 1)
cilium endpoint config $ENDPOINT_ID debug=true

while :
do
	if [ "$POD_NAME" = "chaos-clique-0" ]
	then
		target="chaos-clique-second"
	else
		target="chaos-clique-first"
	fi

	TMP=$(mktemp)
	cilium monitor -v > $TMP&
	MONITOR_PID=$!

	echo -n "Trying to talk to $target: "

	time curl -s $CURL_OPTIONS $target> /dev/null
	CODE=$?
	echo "$CODE"

	kill $MONITOR_PID || true
	sleep 2
	kill -9 $MONITOR_PID 2> /dev/null || true

	[ "$CODE" -ne "0" ] && {
		MSG="{\"text\": \":fire: *E.T. ($POD_NAME) cannot call $target!* (exit code $CODE) :face_palm:\"}"
		curl -XPOST -d "$MSG" $SLACK_HOOK

		echo 'Monitor log:'
		cat $TMP
		rm $TMP
		exit 1
	}

	rm $TMP

	sleep $SLEEP
done
