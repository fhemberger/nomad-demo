FROM alpine:edge

ENV ANSIBLE_HOST_KEY_CHECKING=False

RUN apk add --no-cache ansible ansible-lint bash black py3-jmespath py3-jsonschema git yamllint
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
