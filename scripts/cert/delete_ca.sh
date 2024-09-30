#!/usr/bin/env bash

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

# https://github.com/OpenVPN/easy-rsa/blob/master/doc/EasyRSA-Readme.md

set -Eeu -o pipefail -o posix

# shellcheck disable=SC2143
if [ "$(easyrsa --version | grep -E -c 'Version:\s+3.1')" -ne 1 ]; then
  echo 'only version 3.1 of easyRSA supported' >&2
  exit 1
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
  printf "The PKI directory '%s' does not exist.\n" "${pki_dir}" >&2
  exit 2
fi

readonly ca_cert="${pki_dir}/ca.crt"

if [ ! -f "${ca_cert}" ]; then
  printf "The CA root certificate '%s' does not exist.\n" "${ca_cert}" >&2
  exit 3
fi

subject="$(openssl x509 -subject -noout -in "${ca_cert}" | sed 's/subject=CN=\(.*\)/\1/')"
readonly subject

printf "\nWARNING: You are about to delete the CA '%s':\n\n" "${subject}"

if command -v tree >/dev/null 2>&1; then
  tree --noreport -F "${pki_dir}"
else
  printf '%s/\n' "${pki_dir}"
  ls -F -A -1 "${pki_dir}"
fi

printf '\nAll existing certificates based on this CA will become invalid.\n\n'
read -p 'Do you really want to irreversibly delete the CA (Y/N)? ' -n 1 -r should_delete

case "${should_delete}" in
  y | Y) printf '\n\n' ;;
  *)
    printf '\n'
    exit 0
    ;;
esac

rm -rf "${pki_dir}"

if [ "$(uname)" = 'Darwin' ]; then
  set +e
  # https://ss64.com/mac/security-find-cert.html
  security find-certificate -c "${subject}" 1>/dev/null 2>/dev/null
  found=$?
  set -e

  if [ "${found}" = 0 ]; then
    printf "Please delete the '%s' certificate from your System keychain.\n\n" "${subject}"
    printf "Also, please consult your browser's documentation on how to remove the CA certificate.\n"
    open -a 'Keychain Access'
  fi
else
  printf "Please consult your distribution's and browser's documentation on how to remove the CA certificate '%s'.\n" "${subject}"
fi
