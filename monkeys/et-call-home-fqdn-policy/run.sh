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

    echo -n "Trying to call 1.1.1.1: "
    time curl -vvv -I  -w "dns: %{time_namelookup} connect: %{time_connect} total: %{time_total}\n" -4 -s $CURL_OPTIONS -o /dev/null 1.1.1.1

    echo -n "Trying to call home ($URL): "
    time curl -vvv -I -w "dns: %{time_namelookup}(%{remote_ip}) connect: %{time_connect} total: %{time_total} localPort: %{local_port}\n" -4 -s $CURL_OPTIONS -o /dev/null $URL
    CODE=$?
    echo "$CODE"

    stop_monitor
    stop_tcpdump

    [ "$CODE" -ne "0" ] && {
        notify_slack ":fire: *E.T. ($HOSTNAME) cannot call home!* (exit code $CODE) :face_palm:"
        test_fail
        exit 1
    }

    sleep $SLEEP
done
