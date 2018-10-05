#!/bin/bash

set -o pipefail


. $(dirname ${BASH_SOURCE})/helpers.bash

init_monkey


API_TOKEN_PATH=${API_TOKEN_PATH:-/var/run/secrets/kubernetes.io/serviceaccount/token}
KUBE_TOKEN=$(< ${API_TOKEN_PATH})
KUBERNETES_PORT_443_TCP_ADDR=${KUBERNETES_PORT_443_TCP_ADDR:-kubernetes}
EXTERNAL_CIDR="http://1.1.1.1"

ERROR_MSG="oh noez! the apple fell far from the tree; (pod: $POD_NAME) failed"

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


endpoint_debug_enable

function run_client() {
  while :
  do
    start_monitor
    start_tcpdump
    log_line "trying to access ${EXTERNAL_CIDR}"
    log_line "=========================================================="
    CURLOUT=$(curl -s -D /dev/stderr --fail --connect-timeout $CONNECTTIMEOUT --max-time $MAXTIMEOUT "${EXTERNAL_CIDR}" -w "@/test/curl-format.txt")
    CMDRES=$?
    log_line "=========================================================="
    if [[ "$CMDRES" != "0" ]]; then
      notify_slack "*$ERROR_MSG* unable to connect to ${EXTERNAL_CIDR} : \`\`\`$CURLOUT\`\`\` (pod $HOSTNAME, exit code $CODE) :cry:"
      test_fail
      exit 1
    fi


    stop_monitor
    stop_tcpdump

    sleep $SLEEP
  done
}

function cleanup_monkey() {
  kubectl delete -f test/egress-cidr-policy.yaml 
  kubectl delete -f test/egress-cidr-policy-dup.yaml
}

function add_delete_policies() {
  while true ; do 
    sleep 10
    kubectl delete -f test/egress-cidr-policy-dup.yaml
    sleep 10
    kubectl apply -f test/egress-cidr-policy-dup.yaml
    sleep 10
    kubectl delete -f test/egress-cidr-policy.yaml
    sleep 10
    kubectl apply -f test/egress-cidr-policy.yaml
  done
}

function run_controller() {
  # First, import both policies
  kubectl apply -f test/egress-cidr-policy.yaml
  kubectl apply -f test/egress-cidr-policy-dup.yaml
  kubectl apply -f test/client.yaml
  # Let client get ready.
  sleep 10
  add_delete_policies
}

if [[ "$POD_NAME" =~ apple-tree-controller-* ]]; then
  # Make sure we clean up the mess the monkeys make :) 
  trap cleanup_monkey SIGTERM SIGINT EXIT
  run_controller
else
  run_client
fi

