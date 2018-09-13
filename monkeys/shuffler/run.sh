#!/bin/bash

set -o pipefail

ERROR_MSG="oh noez! shuffler monkey failed"

. $(dirname ${BASH_SOURCE})/helpers.bash

init_monkey

if [ ${DEBUG} ]; then
  set -x
fi

API_TOKEN_PATH=${API_TOKEN_PATH:-/var/run/secrets/kubernetes.io/serviceaccount/token}
KUBE_TOKEN=$(< ${API_TOKEN_PATH})
KUBERNETES_PORT_443_TCP_ADDR=${KUBERNETES_PORT_443_TCP_ADDR:-kubernetes}

endpoint_debug_enable

# TODO - would be good to factor this out into helpers.bash or something since
# it is used elsewhere.
ERROR_MSG="No-one is listening to chatty-cathy!"

phrases[0]="Just gotta hash it and cache it"
phrases[1]="Less talking man, more eating"
phrases[2]="It's possible that cheeseburger got into a weird state"
phrases[3]="Let’s move forward. Let’s not move back"
phrases[4]="Life goes on man... life goes on..."
phrases[5]="It’s okay man, rhotimatic, gotta get it man"
phrases[6]="Go to the max!"
phrases[7]="I went to the dentist today, and they had this really nice heater"

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
	DST="shuffler"
}

function start_server() {
  while :
  do
    start_monitor
    start_tcpdump
    nc -l -p $PORT -v -v
    CODE=$?
    echo "$CODE"

    stop_monitor
    stop_tcpdump

    [ "$CODE" -ne "0" ] && {
      notify_slack "*$ERROR_MSG* (exit code $CODE) :cry:"
      test_fail
      exit 1
    }

    sleep $SLEEP
  done
}

function start_client() {
  while :
  do
    start_monitor
    start_tcpdump
    echo "Starting up cathy chatting to $DST:$PORT"
    while true; do
      rand=$[$RANDOM % ${#phrases[@]}]
      echo -e ${phrases[$rand]}
      sleep $INTERVAL
    done | nc $DST $PORT -q 0 -k -v -v
    CODE=$?
    echo "$CODE"

    stop_monitor
    stop_tcpdump

    [ "$CODE" -ne "0" ] && {
      notify_slack "*$ERROR_MSG* (exit code $CODE) :cry:"
      test_fail
      exit 1
    }     

    sleep $SLEEP
  done
}

function create_shuffler_service() {
  log_line "creating shuffler service"
  curl -k -f -H "Authorization: Bearer $KUBE_TOKEN" -H "Content-Type: application/json" https://${KUBERNETES_PORT_443_TCP_ADDR}/api/v1/namespaces/chaos-testing/services --data '{"apiVersion":"v1","kind":"Service","metadata":{"name":"shuffler","namespace":"chaos-testing"},"spec":{"ports":[{"port":80}],"selector":{"name":"shuffler"}}}'
}

function shuffle_services() {
  i=0
  log_line "creating Kubernetes Endpoints shuffler"
  curl -s -k -f -H "Authorization: Bearer $KUBE_TOKEN" -H "Content-Type: application/json" https://${KUBERNETES_PORT_443_TCP_ADDR}/api/v1/namespaces/chaos-testing/endpoints --data '{"apiVersion":"v1","kind":"Endpoints","metadata":{"annotations":{"iterNum":"'$i'"},"name":"shuffler","namespace":"chaos-testing"}}'
  while true ; do
    sleep $SLEEP
    i=$((i+1))
    log_line "annotating shuffler with iterNum: $i"
    curl -s -k -f -H "Authorization: Bearer $KUBE_TOKEN" -H "Accept: application/json"  -H "Content-Type: application/strategic-merge-patch+json" https://${KUBERNETES_PORT_443_TCP_ADDR}/api/v1/namespaces/chaos-testing/endpoints/shuffler  --request PATCH --data '{"apiVersion":"v1","kind":"Endpoints","metadata":{"annotations":{"iterNum":"'$i'"},"name":"shuffler","namespace":"chaos-testing"}}'
  done
}

function get_desired_replicas() {
  statefulset=$1
  kubectl get statefulset $statefulset -n chaos-testing -o json | jq '.spec.replicas'
}

function get_realized_replicas() {
  statefulset=$1
  kubectl get statefulset $statefulset -n chaos-testing -o json | jq '.status.replicas'
}

function cleanup_monkey() {
  kubectl delete -f test/client.yaml
  kubectl delete -f test/server.yaml
  kubectl delete service shuffler -n chaos-testing
}

if [[ "$POD_NAME" =~ shuffler-controller-* ]]; then
  # Make sure we clean up the mess the monkeys make :) 
  trap cleanup_monkey SIGTERM SIGINT EXIT
  create_shuffler_service
  shuffle_services &
  
  # Sleep 5 seconds to allow for shuffle_serivces to bootstrap.
  sleep 5 
  bootstrap_kubectl
  kubectl create -f test/server.yaml
  kubectl create -f test/client.yaml
 
  server_spec_replicas="$(get_desired_replicas shuffler-server )"
  client_spec_replicas="$(get_desired_replicas shuffler-client )"
  while true ; do 
    realized_client_replica="-1"
    realized_server_replica="-1"

    log_line "looping until number of running client replicas matches desired number of client replicas"
    while [[ "$realized_client_replica" != "$client_spec_replicas" ]] ; do 
      log_line "sleeping while waiting for statefulset realized replica count to match desired count; $realized_client_replica != $client_spec_replicas"
      sleep 1
      realized_client_replica=$(get_realized_replicas shuffler-client )
    done  

    # Allow for client to connect to one of the servers for some time.
    sleep 10  

    log_line "looping until number of running server replicas matches desired number of server replicas"
    while [[ "$realized_server_replica" != "$server_spec_replicas" ]] ; do
      log_line "sleeping while waiting for statefulset realized replica count to match desired count; $realized_server_replica != $server_spec_replicas"
      sleep 1
      realized_server_replica=$(get_realized_replicas shuffler-server)
    done
    
    # Scale up number of server replicas. No loss in connectivity should occur for client.
    log_line "scaling shuffler-server to 4 replicas"
    kubectl scale statefulset shuffler-server --replicas=4
    server_spec_replicas="$(get_desired_replicas shuffler-server )"

    log_line "looping until number of running server replicas matches desired number of server replicas"
    while [[ "$realized_server_replica" != "$server_spec_replicas" ]] ; do
      log_line "sleeping while waiting for statefulset realized replica count to match desired count; $realized_server_replica != $server_spec_replicas"
      sleep 1
      realized_server_replica=$(get_realized_replicas shuffler-server)
    done

    # Scale down client to 0 pods so we can scale down number of servers without worrying about
    # destroying the server which client was connected to, and causing errors.
    log_line "scaling shuffler-client to 0 replicas"
    kubectl scale statefulset shuffler-client --replicas=0
    while [[ "$realized_client_replica" != "$client_spec_replicas" ]] ; do      
      log_line "sleeping while waiting for statefulset realized replica count to match desired count; $realized_client_replica != $client_spec_replicas"
      sleep 1
      realized_client_replica=$(get_realized_replicas shuffler-client )
    done  
    
    num_client_pods=$(kubectl get pods -n chaos-testing -l name=shuffler-client -o json | jq '.items | length')
    while [[ "$num_client_pods" != "0" ]] ; do 
      log_line "sleeping while waiting for number of client pods to be 0: $num_client_pods != 0"
      num_client_pods=$(kubectl get pods -n chaos-testing -l name=shuffler-client -o json | jq '.items | length')
    done

    # Scale down servers now that zero clients are running.
    log_line "scaling shuffler-server to 3 replicas"
    kubectl scale statefulset shuffler-server --replicas=3
    server_spec_replicas=$(kubectl get statefulset shuffler-server -n chaos-testing -o json | jq '.spec.replicas')

    log_line "looping until number of running server replicas matches desired number of server replicas"
    while [[ "$realized_server_replica" != "$server_spec_replicas" ]] ; do
      log_line "sleeping while waiting for statefulset realized replica count to match desired count; $realized_server_replica != $server_spec_replicas"
      sleep 1
      realized_server_replica=$(get_realized_replicas shuffler-server )
    done
    
    # Scale up clients again now that servers are scaled down.
    log_line "scaling shuffler-client to 1 replica"
    kubectl scale statefulset shuffler-client --replicas=1

    # Do this forever!
  done
elif [[ $POD_NAME =~ shuffler-server-* ]]; then
  start_server
# All other endpoints are clients
else
  start_client
fi

