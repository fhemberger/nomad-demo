#!/usr/bin/env bash
set -euo pipefail

docker build -t fhemberger/nomad-demo-hello-world-vault .
docker push fhemberger/nomad-demo-hello-world-vault
