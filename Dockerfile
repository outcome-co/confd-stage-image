FROM golang:1.15.1 as confd

ARG APP_VERSION
ARG CONFD_VERSION=0.16.0

RUN apt-get update && apt-get install --no-install-recommends -y "bzip2=1.0.6-9.2~deb10u1" #!COMMIT

RUN wget -q https://github.com/kelseyhightower/confd/archive/v${CONFD_VERSION}.tar.gz -O /tmp/v${CONFD_VERSION}.tar.gz

WORKDIR /go/src/github.com/kelseyhightower/confd

RUN tar --strip-components=1 -zxf /tmp/v${CONFD_VERSION}.tar.gz && \
    go install github.com/kelseyhightower/confd && \
    rm -rf /tmp/v${CONFD_VERSION}.tar.gz #!COMMIT

FROM scratch
COPY --from=confd /go/bin/confd /go/bin/confd
