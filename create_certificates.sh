#!/bin/bash
OUTPUT_DIR="./certs"

mkdir -p $OUTPUT_DIR

for row in $(cat conf.json | jq -c '.[]'); do
  _jq() {
    echo ${row} | jq -r ${1}
  }

  COUNTRY=$(_jq '.country')
  STATE=$(_jq '.state')
  LOCALITY=$(_jq '.locality')
  ORGANIZATION=$(_jq '.organization')
  ORGANIZATION_UNIT=$(_jq '.organization_unit')
  COMMON_NAME=$(_jq '.common_name')
  DOMAINS=$(_jq '.domains')
  OUTPUT_NAME=$(_jq '.output_name')
  EXPIRE_DAYS=$(_jq '.expire_days')
  SKIP_IF_FOUND=$(_jq '.skip_if_found')

  I=1

  if [ "$SKIP_IF_FOUND" = true ]; then
    if [ -f "$OUTPUT_DIR/$OUTPUT_NAME.key" ]; then
      # private key already exists, so skip
      echo "Skipped $COMMON_NAME, since $OUTPUT_DIR/$OUTPUT_NAME.key was found and skip_if_found was set."
      continue;
    fi
  fi

  DNS=""
  for domain in $(echo "${DOMAINS}" | jq -r '.[]'); do
    DOMAIN=${domain}
    if [ -z "$DNS" ]; then
      DNS="DNS.$I:"$DOMAIN
    else
      DNS=$DNS",DNS.$I:"$DOMAIN
    fi
    I=$(($I + 1))
  done

  # Generate private key
  openssl genrsa -out $OUTPUT_DIR/$OUTPUT_NAME.key 4096

  # ugly but working
  if [ -z "$DNS" ]; then
    openssl req -new -sha256 \
              -out $OUTPUT_DIR/$OUTPUT_NAME.csr \
              -key $OUTPUT_DIR/$OUTPUT_NAME.key \
              -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORGANIZATION_UNIT/CN=$COMMON_NAME"

    openssl x509 -req \
               -sha256 \
               -days $EXPIRE_DAYS \
               -in $OUTPUT_DIR/$OUTPUT_NAME.csr \
               -signkey $OUTPUT_DIR/$OUTPUT_NAME.key \
               -out $OUTPUT_DIR/$OUTPUT_NAME.crt
  else
    openssl req -new -sha256 \
              -out $OUTPUT_DIR/$OUTPUT_NAME.csr \
              -key $OUTPUT_DIR/$OUTPUT_NAME.key \
              -config <(cat ./ssl.conf <(printf "subjectAltName=$DNS")) \
              -extensions v3_req \
              -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORGANIZATION_UNIT/CN=$COMMON_NAME"

    openssl x509 -req \
               -sha256 \
               -days $EXPIRE_DAYS \
               -in $OUTPUT_DIR/$OUTPUT_NAME.csr \
               -signkey $OUTPUT_DIR/$OUTPUT_NAME.key \
               -out $OUTPUT_DIR/$OUTPUT_NAME.crt \
               -extfile <(cat ./ssl.conf <(printf "subjectAltName=$DNS")) \
               -extensions v3_req
  fi


  openssl rsa -in $OUTPUT_DIR/$OUTPUT_NAME.key -text > $OUTPUT_DIR/$OUTPUT_NAME-key.pem
  openssl x509 -inform PEM -in $OUTPUT_DIR/$OUTPUT_NAME.crt > $OUTPUT_DIR/$OUTPUT_NAME-cert.pem
done

exit 0
