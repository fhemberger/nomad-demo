.PHONY: fmt lint install

HCLFMT := $(shell command -v hclfmt 2> /dev/null)

fmt:
ifndef HCLFMT
	GO111MODULE=on go get github.com/hashicorp/hcl/v2/cmd/hclfmt
endif
	find nomad_jobs/*.nomad -maxdepth 0 | xargs -L 1 hclfmt -w


lint:
	git ls-files '*.yml' '*.yaml' | while read -r file ; do yamllint "$$file"; done
	ansible-lint -v


install:
	find nomad_jobs/*.nomad -maxdepth 0 | xargs -L 1 nomad job run
