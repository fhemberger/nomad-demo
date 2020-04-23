FROM alpine

ENV ANSIBLE_HOST_KEY_CHECKING=False

RUN apk add --no-cache ansible-lint bash
RUN pip3 install --upgrade pip yamllint
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
