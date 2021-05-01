.PHONY: fmt lint install
.DEFAULT_GOAL := default

HCLFMT := $(shell command -v hclfmt 2> /dev/null)
VAULT_NODES := $(shell grep "^\$$vault_nodes" Vagrantfile | awk '{print $$NF}')

default:
	vagrant up


# Delete cached Vagrant machine info
# Can contain former VM IPs which are handed over to the Ansible provisioner
clean:
	vagrant destroy -f
	find .vagrant -maxdepth 1 -type f -delete
	rm -rf .vagrant/provisioners
	rm -rf credentials


format-hcl:
ifndef HCLFMT
	GO111MODULE=on go get github.com/hashicorp/hcl/v2/cmd/hclfmt
endif
	find nomad_jobs -maxdepth 1 \( -name \*.nomad -o -name \*.vault \) | xargs -L 1 hclfmt -w


lint-nomad:
	find nomad_jobs/*.nomad -maxdepth 0 | xargs -L 1 nomad job validate


lint-yaml:
	git ls-files '*.yml' '*.yaml' | while read -r file ; do yamllint "$$file"; done
	ansible-lint -v


lint: format-hcl lint-nomad lint-yaml


nomad-install:
	find nomad_jobs/*.nomad -maxdepth 0 | xargs -L 1 nomad job run
