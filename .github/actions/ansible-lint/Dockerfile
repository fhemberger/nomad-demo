FROM alpine:3.12

ENV ANSIBLE_HOST_KEY_CHECKING=False

RUN apk add --no-cache ansible-lint bash python3 py3-pip
RUN pip install --upgrade pip yamllint
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
