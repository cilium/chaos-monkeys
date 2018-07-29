ifndef VERSION
VERSION=latest
endif

all:
	docker build -t cilium/chaos-test-base:${VERSION} .
	@echo "\nTo push to the registry:\ndocker push cilium/chaos-test-base:${VERSION}"
