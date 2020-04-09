FROM alpine:latest AS build
RUN apk add --no-cache git openjdk11-jdk

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk
ENV PATH="$JAVA_HOME/bin:${PATH}"

RUN git clone --depth=1 https://github.com/bjrbhre/hello-http-java \
  && cd hello-http-java \
  && javac HelloWorld.java \
  && jar cmvf META-INF/MANIFEST.MF HelloWorld.jar *.class

RUN sh -c 'echo "jar_server 1" > /metrics'

FROM halverneus/static-file-server:latest
COPY --from=build /hello-http-java/HelloWorld.jar /web/
COPY --from=build /metrics /web/
