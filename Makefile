SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := default
.PHONY: default clean format-hcl lint-jobs lint-yaml run-jobs

HCLFMT := $(shell command -v hclfmt 2> /dev/null)
VAULT_NODES := $(shell grep "^\$$vault_nodes" Vagrantfile | awk '{print $$NF}')

NOMAD_JOBS := $(wildcard nomad_jobs/*.nomad)
VAULT_POLICIES := $(wildcard nomad_jobs/*.vault)

DOMAIN := $(shell grep -oP 'domain: \K\w+' group_vars/all.yml)

default:
	vagrant up
	vagrant provision --provision-with ansible


clean:
	vagrant destroy -f
	rm -f .vagrant/ssh_config
	rm -rf .vagrant/provisioners
	rm -rf certificates credentials


format-hcl: $(NOMAD_JOBS) $(VAULT_POLICIES)
ifndef HCLFMT
	GO111MODULE=on go get github.com/hashicorp/hcl/v2/cmd/hclfmt
endif
	hclfmt -check -w $^


lint-jobs: $(NOMAD_JOBS)
	@for job in $^; do \
		echo -e "\n$${job}:"; \
		nomad job validate $${job} | tr -d '\000-\011\013\014\016-\037' | tail -n +3; \
	done


lint-yaml:
	git ls-files '*.yml' '*.yaml' | while read -r file ; do yamllint "$$file"; done
	ansible-lint -v


lint: format-hcl lint-jobs lint-yaml


run-jobs:
	@vagrant ssh-config > .vagrant/ssh_config
	@scp -F .vagrant/ssh_config nomad_jobs/*.nomad controlplane1:/home/vagrant/nomad_jobs/
	@vagrant ssh controlplane1 -c 'export NOMAD_VAR_grafana_url="http://grafana.$(DOMAIN)"; \
		for job in nomad_jobs/*.nomad; do \
			nomad job plan "$$job"; \
			nomad job run "$$job"; \
			echo -e "\n"; \
		done'
