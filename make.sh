#!/usr/bin/env bash

CSR_FILE="csrfile.csr"
KEY_BITS=2048
CONF_DIR="conf"
CHAIN_CRT="ca_chain.crt"


function clean {
    find conf -not -name '*.cnf' -type f -delete
    rm -f $CSR_FILE $CHAIN_CRT
}

function prepare {
    clean
    echo 1000 > "$CONF_DIR/root_serial"
    cp /dev/null "$CONF_DIR/root_index.txt"
    echo 2000 > "$CONF_DIR/im_serial"
    cp /dev/null "$CONF_DIR/im_index.txt"
}

prepare


ROOT_URL="mycorp.com"
ROOT_ORG="MYCORP"
ROOT_CNF="$CONF_DIR/root_openssl.cnf"
ROOT_CRT="root.crt"
ROOT_KEY="root.key"
ROOT_EXP=5000
ROOT_SUB="/C=RU/ST=Moscow/L=Moscow/O=$ROOT_ORG/CN=$ROOT_URL"

# Generate root key
openssl genrsa -out $ROOT_KEY $KEY_BITS
# Generate root certificate
openssl req -config $ROOT_CNF -new -x509 -sha256 -extensions v3_ca \
    -key $ROOT_KEY -out $ROOT_CRT -days $ROOT_EXP -subj $ROOT_SUB
# Verify root certificate
openssl x509 -noout -text -in $ROOT_CRT


IM_CRT="intermediate.crt"
IM_KEY="intermediate.key"
IM_CNF="$CONF_DIR/im_openssl.cnf"
IM_EXP=4000
IM_SUB="/C=RU/ST=Moscow/L=Moscow/O=${ROOT_ORG}/CN=department.${ROOT_URL}"

# Generate intermediate key
openssl genrsa -out $IM_KEY $KEY_BITS
# Generate intermediate request
openssl req -config $IM_CNF -new -key $IM_KEY -out $CSR_FILE -subj $IM_SUB
# Generate intermediate certificate
openssl ca \
    -config $ROOT_CNF -batch \
    -extensions v3_intermediate_ca -notext -md sha256 \
    -days $IM_EXP -in $CSR_FILE -out $IM_CRT
# Verify intermediate certificate
openssl x509 -noout -text -in $IM_CRT
openssl verify -CAfile $ROOT_CRT $IM_CRT

SERVER_CRT="server.crt"
SERVER_KEY="server.key"
SERVER_EXP=365
SERVER_SUB="/C=RU/ST=Moscow/L=Moscow/O=MYSERVER/CN=myserver.com"

# Generate key
openssl genrsa -out $SERVER_KEY $KEY_BITS
# Generate request
openssl req -config $IM_CNF \
  -key $SERVER_KEY \
  -new -sha256 -out $CSR_FILE \
  -subj $SERVER_SUB
# Generate certificate
openssl ca \
    -config $IM_CNF -batch \
    -extensions server_cert -days $SERVER_EXP -notext -md sha256 \
    -in $CSR_FILE -out $SERVER_CRT
# Verify certificate
cat $IM_CRT $ROOT_CRT > $CHAIN_CRT
openssl verify -CAfile $CHAIN_CRT $SERVER_CRT

clean
