#!/bin/bash

ERROR_MSG="TODO: Update the error message"

. $(dirname ${BASH_SOURCE})/helpers.bash

init_monkey

[ -z "$SLEEP" ] && {
    SLEEP="10"
}

[ -z "$CONNECTTIMEOUT" ] && {
    $CONNECTTIMEOUT="5"
}
endpoint_debug_enable

while :
do
    start_monitor
    start_tcpdump
    curl --head --fail --connect-timeout "${CONNECTTIMEOUT}" "${TARGETURL}" \
        -w "RemoteIP: %{remote_ip}\nDNSLOOKUP: %{time_namelookup}\nTotalTime: %{time_total}\nResponse: %{http_code}\n"
    CODE=$?
    stop_monitor
    stop_tcpdump

    [ "$CODE" -ne "0" ] && {
        cilium identity list

        notify_slack ":fire: *$ERROR_MSG* (pod $HOSTNAME, exit code $CODE) :face_palm:"
        test_fail
        exit 1
    }

    sleep $SLEEP
done
