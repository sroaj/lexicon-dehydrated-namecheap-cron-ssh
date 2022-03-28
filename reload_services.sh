#!/bin/bash

KEY_PATH="${2}"
CERT_FILE_NAME="cert.pem"
CERT_PATH="${3}"
CHAIN_FILE_NAME="fullchain.pem"
CHAIN_PATH="${4}"

HOSTLIST_PATH="${BASEDIR}/hostlist.txt"

REMOTE_BINARY_NAME="./letsencrypt.sh"

echo "+ Checking for certificate file: ${CERT_PATH}"
if [ ! -f "${CERT_PATH}" ]; then
    echo "File not found!"
    exit 1
fi

echo "+ Checking for certificate chain file: ${CHAIN_PATH}"
if [ ! -f "${CHAIN_PATH}" ]; then
    echo "File not found!"
    exit 1
fi

echo "+ Checking for key file: ${KEY_PATH}"
if [ ! -f "${KEY_PATH}" ]; then
    echo "File not found!"
    exit 1
fi

echo "+ Checking for host list file: ${HOSTLIST_PATH}"
if [ ! -f "${HOSTLIST_PATH}" ]; then
    echo "File not found!"
    exit 1
fi

echo "+ Will be sending certificate to the following hosts:"
while read -r host path; do
    echo " - $host ${path:-$REMOTE_BINARY_NAME}"
done < "${HOSTLIST_PATH}"

echo "+ Begining certificate transfer"
while read -r host path; do
    echo " - Sending ${CERT_PATH} as ${CERT_FILE_NAME} to $host"
    scp -q "${CERT_PATH}" "${host}:${CERT_FILE_NAME}" || { echo "Failed. Going to next host"; continue; }

    echo " - Sending ${CHAIN_PATH} as ${CHAIN_FILE_NAME} to $host"
    scp -q "${CHAIN_PATH}" "${host}:${CHAIN_FILE_NAME}" || { echo "Failed. Going to next host"; continue; }

    echo " - Executing ${path:-$REMOTE_BINARY_NAME} on $host with args: ${CERT_FILE_NAME} ${CHAIN_FILE_NAME} and ${KEY_PATH} in stdin"
    ssh "${host}" "${path:-$REMOTE_BINARY_NAME} ${CERT_FILE_NAME} ${CHAIN_FILE_NAME}" < "${KEY_PATH}"
done < "${HOSTLIST_PATH}"
