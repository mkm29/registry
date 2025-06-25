FROM alpine:latest
RUN apk --no-cache add ca-certificates curl
WORKDIR /root/
ENV myDomain="registry.smigula.io"
