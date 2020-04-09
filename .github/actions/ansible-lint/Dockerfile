FROM alpine

ENV ANSIBLE_HOST_KEY_CHECKING=False

RUN apk add ansible-lint bash
RUN pip3 install --upgrade yamllint
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
