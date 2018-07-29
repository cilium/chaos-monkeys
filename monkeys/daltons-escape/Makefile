all:
	kubectl create --dry-run configmap chaos-test-dalton-script --from-file=run.sh -o yaml > deployments/chaos-test-dalton-script.yaml

clean:
	$(RM) deployments/chaos-test-dalton-script.yaml
