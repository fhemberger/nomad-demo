FROM alpine:3.13

ENV ANSIBLE_HOST_KEY_CHECKING=False

RUN apk add --no-cache ansible-lint bash make python3 py3-pip
RUN pip install --upgrade pip yamllint
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
