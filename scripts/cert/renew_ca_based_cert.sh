#!/usr/bin/env bash

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

#  easyrsa needs to be in $PATH
#   Mac:
#     brew install easy-rsa
#   Linux:
#     https://easy-rsa.readthedocs.io/en/latest/#obtaining-and-using-easy-rsa

# https://github.com/OpenVPN/easy-rsa/blob/master/doc/EasyRSA-Renew-and-Revoke.md
# https://github.com/OpenVPN/easy-rsa/blob/master/doc/EasyRSA-Readme.md

set -Eeu -o pipefail -o posix

# shellcheck disable=SC2143
if [ "$(easyrsa --version | grep -E -c 'Version:\s+3.1')" -ne 1 ]; then
  echo 'only version 3.1 of easyRSA supported' >&2
  exit 1
fi

while getopts ':c:d:v:y' opt; do
  case "${opt}" in
    c)
      common_name="${OPTARG}"
      ;;
    d)
      base_dir="${OPTARG}"
      ;;
    v)
      days="${OPTARG}"
      ;;
    ?)
      echo "Usage: $0 [-c <common_name>] [-d <dir>] [-v <days; 1..24855>]" >&2
      exit 1
      ;;
  esac
done

readonly base_dir="${base_dir:-$PWD}"
readonly common_name="${common_name:-localhost}"

readonly cert_path="${base_dir}/cert.pem"
readonly key_path="${base_dir}/key.pem"

if [ ! -f "${key_path}" ]; then
  echo "key '${key_path}' does not exist" >&2
  exit 2
fi

if [ ! -f "${cert_path}" ]; then
  echo "cert '${cert_path}' does not exist" >&2
  exit 3
fi

if [ -n "${days+x}" ]; then # $days defined
  case ${days} in
    '' | *[!0-9]*) # $days is not a positive integer or 0
      echo "'${days}' is not a positive integer" >&2
      exit 2
      ;;
    *) # $days is a positive integer or 0
      if [ "${days}" -lt 1 ]; then
        echo "'${days}' is not a positive integer" >&2
        exit 3
      fi
      if [ "${days}" -gt 24855 ]; then
        echo "'${days}' is outside of the range 1..24855" >&2
        exit 4
      fi
      if [ "${days}" -gt 180 ]; then
        printf "ATTENTION: '%s' exceeds 180 days, the certificate will not be accepted by Apple platforms or Safari; see https://support.apple.com/en-us/103214 for more information.\n\n" "${days}"
      fi
      if [ "${days}" -gt 47 ]; then
        printf "ATTENTION: '%s' exceeds 47 days, the certificate will not be accepted by browsers after March 14, 2029; see https://www.digicert.com/blog/tls-certificate-lifetimes-will-officially-reduce-to-47-days for more information.\n\n" "${days}"
      fi
      ;;
  esac
else # $days undefined
  days=30
fi
readonly days

if [ "${common_name}" = 'ca' ]; then
  echo "'ca' is not allowed due to it being the name of the certificate authority" >&2
  exit 7
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
  exit 8
fi

readonly easyrsa_key_path="${pki_dir}/private/${common_name}.key"
readonly easyrsa_cert_path="${pki_dir}/issued/${common_name}.crt"

if [ ! -f "${easyrsa_key_path}" ]; then
  echo "key '${easyrsa_key_path}' does not exist" >&2
  exit 9
fi

if [ ! -f "${easyrsa_cert_path}" ]; then
  echo "cert '${easyrsa_cert_path}' does not exist" >&2
  exit 10
fi

readonly easyrsa_renew_cert_path="${pki_dir}/renewed/issued/${common_name}.crt"

if [ -f "${easyrsa_renew_cert_path}" ]; then
  rm -f "${easyrsa_renew_cert_path}"
fi

rm -f "${cert_path}"

easyrsa --sbatch --silent-ssl --days="${days}" renew "${common_name}"

if [ ! -e "${cert_path}" ] && [ -f "${easyrsa_cert_path}" ]; then
  cp "${easyrsa_cert_path}" "${cert_path}"
fi
