#!/usr/bin/env bash
set -euo pipefail

docker build -t hello-world-java .
docker run --rm -t -v "$(pwd):/out" hello-world-java
