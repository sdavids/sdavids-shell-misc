#!/usr/bin/env bash

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

#  easyrsa needs to be in $PATH
#   Mac:
#     brew install easy-rsa
#   Linux:
#     https://easy-rsa.readthedocs.io/en/latest/#obtaining-and-using-easy-rsa

# https://github.com/OpenVPN/easy-rsa/blob/master/doc/EasyRSA-Readme.md

set -Eeu -o pipefail -o posix

# shellcheck disable=SC2143
if [ "$(easyrsa --version | grep -E -c 'Version:\s+3.1')" -ne 1 ]; then
  echo 'only version 3.1 of easyRSA supported' >&2
  exit 1
fi

readonly out_dir="${1:-$PWD}"

readonly key_path="${out_dir}/key.pem"
readonly cert_path="${out_dir}/cert.pem"

if [ -e "${key_path}" ]; then
  printf "The key '%s' already exists.\n" "${key_path}" >&2
  if command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "${key_path}" | pbcopy
    printf 'The path has been copied to the clipboard.\n' >&2
  elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "${key_path}" | xclip -selection clipboard
    printf 'The path has been copied to the clipboard.\n' >&2
  elif command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "${key_path}" | wl-copy
    printf 'The path has been copied to the clipboard.\n' >&2
  fi
  exit 2
fi

if [ -e "${cert_path}" ]; then
  printf "The certificate '%s' already exists.\n" "${cert_path}" >&2
  if command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "${cert_path}" | pbcopy
    printf 'The path has been copied to the clipboard.\n' >&2
  elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "${cert_path}" | xclip -selection clipboard
    printf 'The path has been copied to the clipboard.\n' >&2
  elif command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "${cert_path}" | wl-copy
    printf 'The path has been copied to the clipboard.\n' >&2
  fi
  exit 3
fi

readonly host_name="${2:-localhost}"

if [ "${host_name}" = 'ca' ]; then
  echo "'ca' is not allowed due to it being the name of the certificate authority" >&2
  exit 4
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
  exit 5
fi

readonly easyrsa_key_path="${pki_dir}/private/${host_name}.key"
readonly easyrsa_cert_path="${pki_dir}/issued/${host_name}.crt"

if [ -f "${easyrsa_key_path}" ] && [ -f "${easyrsa_cert_path}" ]; then
  mkdir -p "${out_dir}"

  cp "${easyrsa_key_path}" "${key_path}"
  cp "${easyrsa_cert_path}" "${cert_path}"

  chmod 600 "${key_path}" "${cert_path}"
else
  printf "The CA has no private key and certificate for '%s'.\n\nExecute the create_ca_based_cert.sh script to create the private key and certificate.\n" "${host_name}" >&2
  exit 6
fi

(
  cd "${out_dir}"

  if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != 'true' ]; then
    exit 0 # ${out_dir} not a git repository
  fi

  set +e
  git check-ignore --quiet key.pem
  key_ignored=$?

  git check-ignore --quiet cert.pem
  cert_ignored=$?
  set -e

  if [ $key_ignored -ne 0 ] || [ $cert_ignored -ne 0 ]; then
    printf "\nWARNING: key.pem and/or cert.pem is not ignored in '%s'\n\n" "$PWD/.gitignore"
    read -p 'Do you want me to modify your .gitignore file (Y/N)? ' -n 1 -r should_modify

    case "${should_modify}" in
      y | Y) printf '\n\n' ;;
      *)
        printf '\n'
        exit 0
        ;;
    esac
  fi

  if [ $key_ignored -eq 0 ]; then
    if [ $cert_ignored -eq 0 ]; then
      exit 0 # both already ignored
    fi
    printf 'cert.pem\n' >>.gitignore
  else
    if [ $cert_ignored -eq 0 ]; then
      printf 'key.pem\n' >>.gitignore
    else
      printf 'cert.pem\nkey.pem\n' >>.gitignore
    fi
  fi

  git status
)
