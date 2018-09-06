# Chaos Test Infrastructure

## Introduction

Base infrastructure plus collection of tests to assist in the Cilium chaos
testing efforts.

## Requirements

* helm
* kubectl
* GNU make

## How to deploy the test monkeys

Generate all ConfigMaps for the test scripts

	make

Create a namespace to run the chaos tests:

	kubectl create namespace chaos-testing

Edit & deploy the base ConfigMap to configure the Slack hook to report test
failures:

	vim monkey-config.yaml
	kubectl -n chaos-testing apply -f monkey-config.yaml

Deploy the test monkeys:

	make deploy

## How to create a new monkey

A new monkey can be initialized from templates using the following command:

	./create-monkey

If run without arguments, it will print usage instructions for initializing
the configuration files for your new monkey. When a monkey name is specified,
it will set up "monkey/{{MONKEY_NAME}}" based on templated files.
