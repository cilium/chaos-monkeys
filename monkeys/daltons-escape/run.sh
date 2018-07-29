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

while :
do
	echo -n "Trying to escape ($URL): "

	time curl -s $CURL_OPTIONS $URL > /dev/null && {
		echo "failed"
		MSG="{\"text\": \":fire: *:daltons: :daltons: :daltons: :daltons: ($HOSTNAME) has escaped!* :face_palm:\"}"
		curl -XPOST -d "$MSG" $SLACK_HOOK
		exit 1
	}

	echo ""
	sleep $SLEEP
done
