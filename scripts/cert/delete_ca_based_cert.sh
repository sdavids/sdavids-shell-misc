#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

#  easyrsa needs to be in $PATH
#   Mac:
#     brew install easy-rsa
#   Linux:
#     https://easy-rsa.readthedocs.io/en/latest/#obtaining-and-using-easy-rsa

# openssl needs to be in $PATH
#   Linux:
#     sudo apt-get install openssl

set -eu

# shellcheck disable=SC2143
if [ "$(easyrsa --version | grep -E -c 'Version:\s+3.1')" -ne 1 ]; then
  echo 'only version 3.1 of easyRSA supported' >&2
  exit 1
fi

while getopts ':c:d:' opt; do
  case "${opt}" in
    c)
      common_name="${OPTARG}"
      ;;
    d)
      base_dir="${OPTARG}"
      ;;
    ?)
      echo "Usage: $0 [-c <common_name>] [-d <dir>]" >&2
      exit 1
      ;;
  esac
done

readonly base_dir="${base_dir:-$PWD}"
readonly common_name="${common_name:-localhost}"

if [ "${common_name}" = 'ca' ]; then
  echo "'ca' is not allowed due to it being the name of the certificate authority" >&2
  exit 2
fi

# https://easy-rsa.readthedocs.io/en/latest/advanced/#openssl-config
if [ -n "${EASYRSA_PKI+x}" ]; then
  readonly pki_dir="${EASYRSA_PKI}"
else
  config_dir="${HOME}/.easyrsa"
  if [ "$(uname)" = 'Darwin' ]; then
    config_dir="${HOME}/Library/Application\ Support/easyrsa"
  fi
  if [ -n "${XDG_DATA_HOME+x}" ]; then
    config_dir="${XDG_DATA_HOME}/easyrsa"
  fi
  readonly pki_dir="${config_dir}/pki"
  export EASYRSA_PKI="${pki_dir}"
  unset config_dir
fi

if [ ! -d "${pki_dir}" ]; then
  printf "The PKI directory '%s' does not exist; therefore the CA has not been created yet.\n\nExecute the create_ca.sh script to create the CA.\n" "${pki_dir}" >&2
  exit 3
fi

readonly key_path="${base_dir}/key.pem"
readonly cert_path="${base_dir}/cert.pem"

readonly easyrsa_key_path="${pki_dir}/private/${common_name}.key"
readonly easyrsa_cert_path="${pki_dir}/issued/${common_name}.crt"
readonly easyrsa_inline_path="${pki_dir}/inline/${common_name}.inline"
readonly easyrsa_req_path="${pki_dir}/reqs/${common_name}.req"
readonly easyrsa_renewed_path="${pki_dir}/renewed/issued/${common_name}.crt"
readonly easyrsa_index_path="${pki_dir}/index.txt"

if [ -f "${easyrsa_cert_path}" ]; then
  easyrsa_serial_path="${pki_dir}/certs_by_serial/$(openssl x509 -serial -noout -in "${easyrsa_cert_path}" | sed 's/serial=\(.*\)/\1/').pem"
else
  easyrsa_serial_path=""
fi
readonly easyrsa_serial_path

if [ -f "${key_path}" ]; then
  rm -f "${key_path}"
fi

if [ -f "${cert_path}" ]; then
  rm -f "${cert_path}"
fi

if [ -f "${easyrsa_key_path}" ]; then
  rm -f "${easyrsa_key_path}"
fi

if [ -f "${easyrsa_cert_path}" ]; then
  rm -f "${easyrsa_cert_path}"
fi

if [ -f "${easyrsa_req_path}" ]; then
  rm -f "${easyrsa_req_path}"
fi

if [ -f "${easyrsa_inline_path}" ]; then
  rm -f "${easyrsa_inline_path}"
fi

if [ -f "${easyrsa_renewed_path}" ]; then
  rm -f "${easyrsa_renewed_path}"
fi

if [ -f "${easyrsa_serial_path}" ]; then
  rm -f "${easyrsa_serial_path}"
fi

# delete empty certs dir if not $PWD
if [ -d "${base_dir}" ] \
  && [ "${base_dir}" != "$PWD" ] \
  && [ "${base_dir}" != '.' ] \
  && [ -z "$(ls -A "${base_dir}")" ]; then

  rmdir "${base_dir}"
fi

if [ "$(uname)" = 'Darwin' ]; then
  sed -i '' "/\/CN=${common_name}$/d" "${easyrsa_index_path}"
else
  sed -i "/\/CN=${common_name}$/d" "${easyrsa_index_path}"
fi

easyrsa --silent update-db 2>/dev/null
