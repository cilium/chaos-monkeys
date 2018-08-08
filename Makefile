MONKEYS := $(foreach path,$(wildcard monkeys/*),$(path:monkeys/%=%))

all:
	$(foreach monkey,$(MONKEYS),\
	mkdir -p deployments/$(monkey); \
	cp -r monkeys/$(monkey)/deployments/* deployments/$(monkey)/; \
	kubectl create --dry-run configmap chaos-test-$(monkey)-script \
		--from-file=monkeys/$(monkey)/run.sh \
		-o yaml > deployments/$(monkey)/chaos-test-$(monkey)-script.yaml; \
	$(foreach valueFile,$(foreach path,$(wildcard monkeys/$(monkey)/values-*.yaml),$(path:monkeys/$(monkey)/%=%)),\
	       helm template monkeys/$(monkey) --set basename=$(monkey) -f monkeys/$(monkey)/$(valueFile) > deployments/$(monkey)-$(valueFile);))

deploy:
	$(foreach monkey,$(MONKEYS),kubectl -n chaos-testing apply -f deployments/$(monkey);)

clean:
	rm -rf deployments
