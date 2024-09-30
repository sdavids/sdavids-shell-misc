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

readonly root_cert_path="${out_dir}/ca.crt"

if [ -e "${root_cert_path}" ]; then
  printf "The certificate '%s' already exists.\n" "${root_cert_path}" >&2
  if command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "${root_cert_path}" | pbcopy
    printf 'The path has been copied to the clipboard.\n' >&2
  elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "${root_cert_path}" | xclip -selection clipboard
    printf 'The path has been copied to the clipboard.\n' >&2
  elif command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "${root_cert_path}" | wl-copy
    printf 'The path has been copied to the clipboard.\n' >&2
  fi
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
  printf "The PKI directory '%s' does not exist.\n" "${pki_dir}" >&2
  exit 3
fi

readonly easyrsa_ca_cert_path="${pki_dir}/ca.crt"

if [ ! -f "${easyrsa_ca_cert_path}" ]; then
  printf "The CA root certificate '%s' does not exist.\n" "${easyrsa_ca_cert_path}" >&2
  exit 4
fi

mkdir -p "${out_dir}"

cp "${easyrsa_ca_cert_path}" "${root_cert_path}"

chmod 600 "${root_cert_path}"

(
  cd "${out_dir}"

  if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != 'true' ]; then
    exit 0 # ${out_dir} not a git repository
  fi

  set +e
  git check-ignore --quiet ca.crt
  cert_ignored=$?
  set -e

  if [ $cert_ignored -ne 0 ]; then
    printf "\nWARNING: ca.crt is not ignored in '%s'\n\n" "$PWD/.gitignore"
    read -p 'Do you want me to modify your .gitignore file (Y/N)? ' -n 1 -r should_modify

    case "${should_modify}" in
      y | Y) printf '\n\n' ;;
      *)
        printf '\n'
        exit 0
        ;;
    esac

    printf 'ca.crt\n' >>.gitignore

    git status
  fi
)
