#!/bin/bash

export ENDPOINT_IP=$(ip -4 a list dev eth0 | grep inet |  grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | head -1)
export ENDPOINT_ID=$(cilium endpoint list | grep $ENDPOINT_IP | cut -d' ' -f 1)


function init_monkey() {
	[ -z "$SLACK_HOOK" ] && {
		echo "SLACK_HOOK not provided"
		exit 1
	}
}

# bootstrap_kubectl configures the kubectl binary located within the pod to 
# run against the cluster of which the pod is a member. It will have access
# to any resource which is allowed in `rbac.yaml` at the root of this
# repository.
function bootstrap_kubectl() {
  # Note that POD_NAMESPACE environment variable is injected via template files
  # in templates/ 
  kubectl config set-cluster ${POD_NAMESPACE} --server=https://${KUBERNETES_PORT_443_TCP_ADDR} --certificate-authority=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
  kubectl config set-context ${POD_NAMESPACE} --cluster=${POD_NAMESPACE}
  kubectl config set-credentials user --token=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
  kubectl config set-context ${POD_NAMESPACE} --user=user
}

function endpoint_debug_enable() {
	cilium endpoint config $ENDPOINT_ID debug=true
}

function endpoint_debug_disable() {
	cilium endpoint config $ENDPOINT_ID debug=false
}

MONITOR_TMP="$(mktemp)"
MONITOR_PID="0"

function start_monitor() {
	[ "$MONITOR_PID" -ne "0" ] && {
		echo "Monitor is already running"
		return
	}

	cilium monitor -v | ts '[%Y-%m-%d %H:%M:%.S]' > $MONITOR_TMP&
	MONITOR_PID=$!
}

function stop_monitor() {
	[ "$MONITOR_PID" -ne "0" ] && {
		kill $MONITOR_PID || {
			kill -9 $MONITOR_PID 2> /dev/null || true
		}

		MONITOR_PID="0"
	}
}

function cleanup_monitor() {
	rm $MONITOR_TMP 2> /dev/null || true
}

TCPDUMP_TMP="$(mktemp)"
TCPDUMP_PID="0"

function start_tcpdump() {
	[ "$TCPDUMP_PID" -ne "0" ] && {
		echo "tcpdump is already running"
		return
	}

	tcpdump -n -i eth0 -s 0 -v > $TCPDUMP_TMP 2>&1 &
	TCPDUMP_PID=$!

	sleep 1
}

function stop_tcpdump() {
	[ "$TCPDUMP_PID" -ne "0" ] && {
		kill $TCPDUMP_PID || {
			kill -9 $TCPDUMP_PID 2> /dev/null || true
		}

		TCPDUMP_PID="0"
	}
}

function cleanup_tcpdump() {
	rm $TCPDUMP_TMP 2> /dev/null || true
}

function notify_slack() {
	MSG="{\"text\": \"$*\"}"
	curl -XPOST -d "$MSG" $SLACK_HOOK
}

function test_fail() {
	echo "----------------------------------------------------------------------------"
	echo "Test failed"
	echo ""
	echo "EndpointID: $ENDPOINT_ID"
	echo "EndpointIP: $ENDPOINT_IP"
	echo "----------------------------------------------------------------------------"

	echo "----------------------------------------------------------------------------"
	echo "Endpoint List"
	echo "----------------------------------------------------------------------------"
	cilium endpoint list

	echo "----------------------------------------------------------------------------"
	echo "Endpoint"
	echo "----------------------------------------------------------------------------"
	cilium endpoint get $ENDPOINT_ID -o json

	echo "----------------------------------------------------------------------------"
	echo "Policy repository"
	echo "----------------------------------------------------------------------------"
	cilium policy get

	echo "----------------------------------------------------------------------------"
	echo "Endpoint policy"
	echo "----------------------------------------------------------------------------"
	cilium bpf policy get $ENDPOINT_ID

	echo "----------------------------------------------------------------------------"
	echo "Service List"
	echo "----------------------------------------------------------------------------"
	cilium service list
	cilium bpf lb list

	[ -s "$MONITOR_TMP" ] && {
		echo "----------------------------------------------------------------------------"
		echo "Monitor Log"
		echo "----------------------------------------------------------------------------"
		cat $MONITOR_TMP
	}

	[ -s "$TCPDUMP_TMP" ] && {
		echo "----------------------------------------------------------------------------"
		echo "tcpdump"
		echo "----------------------------------------------------------------------------"
		cat $TCPDUMP_TMP
	}
}

function log_line() {
  local MSG=$(/bin/date --rfc-3339=seconds)
  MSG="${MSG}  $*"
  echo "${MSG}"
}

function cleanup() {
	stop_tcpdump
	cleanup_tcpdump
	stop_monitor
	cleanup_monitor
}

trap cleanup EXIT
