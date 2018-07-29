all:
	kubectl create --dry-run configmap chaos-test-et-call-home-script --from-file=run.sh -o yaml > deployments/chaos-test-et-call-home-script.yaml

clean:
	$(RM) deployments/chaos-test-et-call-home-script.yaml
