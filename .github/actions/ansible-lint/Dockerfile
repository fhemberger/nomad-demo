FROM alpine:3.15.0

ENV ANSIBLE_HOST_KEY_CHECKING=False

RUN apk add --no-cache ansible-lint bash python3 py3-pip
RUN pip install --upgrade pip 'resolvelib<0.6.0,>=0.5.3' yamllint
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
