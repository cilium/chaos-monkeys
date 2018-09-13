MONKEYS := $(foreach path,$(wildcard monkeys/*),$(path:monkeys/%=%))


all:
	$(foreach monkey,$(MONKEYS),\
	mkdir -p deployments/$(monkey); \
	mkdir -p monkeys/$(monkey)/kubernetes-resources; \
	$(foreach file,$(foreach kubeDep, $(wildcard monkeys/$(monkey)/kubernetes-resources-charts/templates/*yaml),$(notdir $(kubeDep)) ),\
		 helm template monkeys/$(monkey)/kubernetes-resources-charts -x templates/$(file) --set basename=$(monkey) -f monkeys/$(monkey)/kubernetes-resources-charts/values-$(monkey).yaml > monkeys/$(monkey)/kubernetes-resources/$(file) ; ) \
	kubectl create --dry-run configmap chaos-test-$(monkey)-script \
		--from-file=lib/helpers.bash \
		$(foreach script,$(wildcard monkeys/$(monkey)/*.sh),\
			"--from-file=$(script)"\
		) \
		$(foreach script,$(wildcard monkeys/$(monkey)/*.jq),\
			"--from-file=$(script)"\
		) \
		$(foreach script,$(wildcard monkeys/$(monkey)/kubernetes-resources/*yaml),\
			"--from-file=$(script)"\
		) \
		-o yaml > deployments/$(monkey)/chaos-test-$(monkey)-script.yaml; \
	$(foreach valueFile,$(foreach path,$(wildcard monkeys/$(monkey)/values-*.yaml),$(path:monkeys/$(monkey)/%=%)),\
	       helm template monkeys/$(monkey) --set basename=$(monkey) -f monkeys/$(monkey)/$(valueFile) > deployments/$(monkey)/$(valueFile);) \
	)
rbac:
	kubectl apply -f rbac.yaml

deploy: rbac
	$(foreach monkey,$(MONKEYS),kubectl -n chaos-testing apply -f deployments/$(monkey);)

clean:
	rm -rf deployments
