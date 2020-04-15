#!/usr/bin/env bash
set -euo pipefail

git clone --depth=1 https://github.com/bjrbhre/hello-http-java
cd hello-http-java
javac HelloWorld.java
jar cmvf META-INF/MANIFEST.MF HelloWorld.jar *.class
cp /hello-http-java/HelloWorld.jar /out/
