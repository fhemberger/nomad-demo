#!/usr/bin/env bash
set -euo pipefail

cd "$GITHUB_WORKSPACE"
make lint
