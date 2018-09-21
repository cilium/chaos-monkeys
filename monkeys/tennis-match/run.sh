#!/bin/bash

set -o pipefail

ERROR_MSG="oh noez! $HOSTNAME failed"

. $(dirname ${BASH_SOURCE})/helpers.bash

init_monkey

function log_line() {
  MSG=$(/bin/date --rfc-3339=seconds)
  MSG="${MSG}  $*"
  echo "${MSG}"
}
export -f log_line

# Values we depend on:
#   API_TOKEN_PATH - file containing the token allowing access to the Kubernetes API
#   DEBUG (option) - to spit out diagnostics
#   DEBUG_EVENTS (optional) - write out event file to data
#   API_ADDR (optional) - [host:port] override the API server to use, rather than the default from KUBERNETES_PORT_443_TCP_ADDR

if [ ${DEBUG} ]; then
  set -x
fi

# Token for accessing kubernetes itself
API_TOKEN_PATH=${API_TOKEN_PATH:-/var/run/secrets/kubernetes.io/serviceaccount/token}
KUBE_TOKEN=$(< ${API_TOKEN_PATH})

# Host to reach kubernetes... plain 'kubernetes' is what worked in minikube
KUBERNETES_PORT_443_TCP_ADDR=${KUBERNETES_PORT_443_TCP_ADDR:-kubernetes}
# But allow API_ADDR to trump all
KUBERNETES_PORT_443_TCP_ADDR=${API_ADDR:-${KUBERNETES_PORT_443_TCP_ADDR}}

# Running namespace
NAMESPACE_NAME=${NAMESPACE_NAME:-default}

endpoint_debug_enable

# Entry point to execute appropriate mode
function read_endpoints() {
  log_line "Running against apiserver=${KUBERNETES_PORT_443_TCP_ADDR}"

  local ret
  while true; do

    curl -s -k --no-buffer -f -H "Authorization: Bearer $KUBE_TOKEN" "https://${KUBERNETES_PORT_443_TCP_ADDR}/api/v1/watch/namespaces/chaos-testing/endpoints" | \
    while read -r event; do
      # TODO: this will fail the first time because the curl output is directly piped into "while".
      stop_monitor
      stop_tcpdump
      log_line "Recieved raw event: ${event}"
      start_monitor
      start_tcpdump
    done
    ret=$?
    if [ $ret -ne 0 ] && [ $ret -ne 56 ]; then
      log_line "Reading event stream stopped abnormally (ret=${ret}); exiting"
      notify_slack ":fire: *$ERROR_MSG* (exit code $ret) :face_palm:"
      test_fail
      exit $ret
    else
      log_line "Reading event stream stopped unexpectedly (ret=${ret}) but will restart reading anyway"
    fi
  done
}

function create_services() {
  while true ; do
    echo "creating 100 monkey services"
    for i in {1..100} ; do
      echo "creating monkey-service-$i"
      curl -k -f -H "Authorization: Bearer $KUBE_TOKEN" -H "Content-Type: application/json" https://${KUBERNETES_PORT_443_TCP_ADDR}/api/v1/namespaces/chaos-testing/services --data '{"apiVersion":"v1","kind":"Service","metadata":{"name":"monkey-service-'$i'","namespace":"chaos-testing"},"spec":{"ports":[{"port":80}],"selector":{"name":"tennis-match"}}}'
      sleep $SLEEP
    done

    echo "deleting 100 monkey services"
    for i in {1..100} ; do
      echo "deleting monkey-service-$i"
      curl -k -f -H "Authorization: Bearer $KUBE_TOKEN" https://${KUBERNETES_PORT_443_TCP_ADDR}/api/v1/namespaces/chaos-testing/services/monkey-service-$i -XDELETE
      sleep $SLEEP
    done
  done
}

if [ "$POD_NAME" = "tennis-match-0" ]; then
  create_services
else
  read_endpoints
fi
