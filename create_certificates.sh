#!/bin/sh
OUTPUT_DIR="./certs"

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

  I=1
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
              -config ssl.conf \
              -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORGANIZATION_UNIT/CN=$COMMON_NAME"
  else
    openssl req -new -sha256 \
              -out $OUTPUT_DIR/$OUTPUT_NAME.csr \
              -key $OUTPUT_DIR/$OUTPUT_NAME.key \
              -config ssl.conf \
              -addext "subjectAltName = $DNS" \
              -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORGANIZATION_UNIT/CN=$COMMON_NAME"
  fi

  openssl x509 -req \
               -sha256 \
               -days 365 \
               -in $OUTPUT_DIR/$OUTPUT_NAME.csr \
               -signkey $OUTPUT_DIR/$OUTPUT_NAME.key \
               -out $OUTPUT_DIR/$OUTPUT_NAME.crt \
               -extfile ssl.conf

  openssl x509 -inform DER -in $OUTPUT_DIR/$OUTPUT_NAME.crt -out $OUTPUT_DIR/$OUTPUT_NAME.pem -text

  #cat $OUTPUT_DIR/$OUTPUT_NAME.crt > $OUTPUT_DIR/$OUTPUT_NAME.pem
done

exit 0
