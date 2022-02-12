FROM alpine:edge

ENV ANSIBLE_HOST_KEY_CHECKING=False

RUN apk add --no-cache ansible ansible-lint bash git yamllint
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
