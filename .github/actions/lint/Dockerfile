FROM golang:1.18-alpine as build
RUN GO111MODULE=on go install github.com/hashicorp/hcl/v2/cmd/hclfmt@latest


FROM alpine:edge

ENV ANSIBLE_HOST_KEY_CHECKING=False

RUN apk add --no-cache ansible ansible-lint bash git grep make nomad yamllint
COPY --from=build /go/bin/hclfmt /usr/bin/hclfmt
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
