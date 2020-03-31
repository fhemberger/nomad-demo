#!/usr/bin/env bash
set -euo pipefail

yamllint .
find . -maxdepth 1 -name '*.yml' -exec ansible-lint -v {} \;
