# based on https://stackoverflow.com/a/18137056/563158
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
DIRNAME := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))

all:
	kubectl create --dry-run configmap chaos-test-$(DIRNAME)-script --from-file=run.sh -o yaml > deployments/chaos-test-$(DIRNAME)-script.yaml

clean:
	$(RM) deployments/chaos-test-$(DIRNAME)-script.yaml
