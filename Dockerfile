FROM alpine:3.10

# Add Maintainer Info
LABEL maintainer="charmixer"

RUN apk add --update --no-cache openssl jq bash

WORKDIR /

RUN mkdir -p certs
RUN touch conf.json

COPY ./create_certificates.sh .
COPY ./ssl.conf .

RUN chmod +x ./create_certificates.sh

CMD ./create_certificates.sh
