#!/usr/bin/env bash
set -euo pipefail

yamllint -c "$GITHUB_WORKSPACE/.yamllint" "$GITHUB_WORKSPACE"
ansible-lint -v "$GITHUB_WORKSPACE/playbook.yml"
