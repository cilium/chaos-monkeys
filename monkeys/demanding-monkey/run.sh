#!/bin/bash

set -o pipefail

ERROR_MSG="oh noez! demanding monkey got impatient."

. $(dirname ${BASH_SOURCE})/helpers.bash

init_monkey

if [ ${DEBUG} ]; then
  set -x
fi

[ -z "$MAXTIMEOUT" ] && {
  MAXTIMEOUT="10"
}

[ -z "$CONNECTTIMEOUT" ] && {
  CONNECTTIMEOUT=3
}

[ -z "$SLEEP" ] && {
  SLEEP=10
}

API_TOKEN_PATH=${API_TOKEN_PATH:-/var/run/secrets/kubernetes.io/serviceaccount/token}
KUBE_TOKEN=$(< ${API_TOKEN_PATH})
KUBERNETES_PORT_443_TCP_ADDR=${KUBERNETES_PORT_443_TCP_ADDR:-kubernetes}

# Running namespace
NAMESPACE_NAME=${NAMESPACE_NAME:-default}

endpoint_debug_enable

# access kubernetes and google.com - if MAXTIMEOUT or CONNECTTIMEOUT are
# exceeded, will fail.
function latency_test() {
  while true; do
    start_monitor
    start_tcpdump
    log_line "trying to get endpoints from Kubernetes"
    log_line "=========================================================="
    CURLOUT=$(curl -s -k -H "Authorization: Bearer $KUBE_TOKEN" -D /dev/stderr --fail --connect-timeout $CONNECTTIMEOUT --max-time $MAXTIMEOUT https://${KUBERNETES_PORT_443_TCP_ADDR}/api/v1/namespaces/chaos-testing/endpoints -w "@/test/curl-format.txt")
    CMDRES=$?
    log_line "=========================================================="
    if [[ "$CMDRES" != "0" ]]; then
      notify_slack "*$ERROR_MSG* unable to access kubernetes service: \`\`\`$CURLOUT\`\`\` (exit code $CODE) :cry:"
      test_fail
      exit 1
    fi
    log_line "trying to access google.com"
    log_line "=========================================================="
    CURLOUT=$(curl -s -D /dev/stderr --fail --connect-timeout $CONNECTTIMEOUT --max-time $MAXTIMEOUT "http://google.com" -w "@/test/curl-format.txt")
    CMDRES=$?
    log_line "=========================================================="
    if [[ "$CMDRES" != "0" ]]; then
      notify_slack "*$ERROR_MSG* unable to connect to http://google.com: \`\`\`$CURLOUT\`\`\` (exit code $CODE) :cry:"
      test_fail
      exit 1
    fi
    stop_monitor
    stop_tcpdump
    sleep $SLEEP
  done
}

latency_test
