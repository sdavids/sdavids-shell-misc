#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2025 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# ssh-keygen needs to be in $PATH
#   Linux:
#     apt-get install openssh-client

set -u

name="$(git config get user.name)"
# shellcheck disable=SC2181
if [ $? -ne 0 ]; then
  name=''
fi
email="$(git config get user.email)"
# shellcheck disable=SC2181
if [ $? -ne 0 ]; then
  email=''
fi
gpg_program="$(git config get gpg.program)"
# shellcheck disable=SC2181
if [ $? -ne 0 ]; then
  gpg_program='gpg'
fi

set -e

while getopts ':d:e:n:s:' opt; do
  case "${opt}" in
    d)
      base_dir="${OPTARG}"
      ;;
    e)
      email="${OPTARG}"
      ;;
    n)
      name="${OPTARG}"
      ;;
    s)
      ssh_key_path="${OPTARG}"
      ;;
    ?)
      echo "Usage: $0 [-d <base_dir>] [-e <email>] [-n <name>] [-s <ssh_key_path>]" >&2
      exit 1
      ;;
  esac
done

readonly base_dir="${base_dir:-$PWD}"
readonly email
readonly name
readonly ssh_key_path="${ssh_key_path:-}"

if [ ! -d "${base_dir}" ]; then
  printf "The directory '%s' does not exist.\n" "${base_dir}" >&2
  exit 2
fi

if [ -z "${email}" ]; then
  echo '-e <email> is required because user.email is not set in your global Git configuration' >&2
  exit 3
fi

if [ -z "${name}" ]; then
  echo '-n <name> is required because user.name is not set in your global Git configuration' >&2
  exit 4
fi

if [ -z "$(ls -A "${base_dir}")" ]; then
  # base_dir empty nothing to do
  exit 0
fi

is_ssh_key='false'

if [ -n "${ssh_key_path}" ]; then
  if [ -f "${ssh_key_path}" ]; then
    set +e
    ssh-keygen -l -f "${ssh_key_path}" >/dev/null 2>&1
    is_ssh_key=$?
    set -e

    if [ "${is_ssh_key}" = 0 ]; then
      is_ssh_key='true'
      key="${ssh_key_path}"
    else
      key=''
      printf "file '%s' is not valid SSH key--disabling SSH signing.\n\n" "${ssh_key_path}" >&2
    fi
  else
    key=''
    printf "file '%s' does not exists--disabling SSH signing.\n\n" "${ssh_key_path}" >&2
  fi
else
  if command -v "${gpg_program}" >/dev/null 2>&1; then
    cmd="${gpg_program} --list-secret-keys --with-colons \"${email}\" 2>&1 | sed -E -n -e 's/^fpr:::::::::([0-9A-F]+):$/\1/p' | head -n 1"
    key="$(eval "${cmd}")"
    if [ -z "${key}" ]; then
      printf "GPG key for '%s' does not exists--disabling GPG signing.\n\n" "${email}" >&2
    fi
  else
    if [ "${gpg_program}" = 'gpg' ] && command -v gpg2 >/dev/null 2>&1; then
      key="$(gpg2 --list-secret-keys --with-colons "${email}" 2>&1 | sed -E -n -e 's/^fpr:::::::::([0-9A-F]+):$/\1/p' | head -n 1)"
      if [ -z "${key}" ]; then
        printf "GPG key for '%s' does not exists--disabling GPG signing.\n\n" "${email}" >&2
      fi
    else
      key=''
      printf "gpg.program '%s' does not exists--disabling GPG signing.\n\n" "${gpg_program}" >&2
    fi
  fi
fi

unset gpg_program
readonly key
readonly is_ssh_key

cd "${base_dir}"

if [ -n "${key}" ]; then
  for dir in ./*/; do
    if [ "${dir}" = './*/' ]; then
      break
    fi
    cd "${dir}"
    if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = 'true' ]; then
      # https://git-scm.com/docs/git-config#_variables
      git config set user.name "${name}"
      git config set user.email "${email}"
      git config set user.signingkey "${key}"
      git config set --bool commit.gpgsign true
      git config set --bool tag.gpgsign true
      git config set --bool tag.forcesignannotated true
      if [ "${is_ssh_key}" = 'true' ]; then
        git config set gpg.format ssh
      else
        git config set gpg.format openpgp
      fi
      echo "$(git config get user.name) <$(git config get user.email)> $(git config get user.signingkey) - $PWD"
    fi
    cd ..
  done
else
  for dir in ./*/; do
    if [ "${dir}" = './*/' ]; then
      break
    fi
    cd "${dir}"
    if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = 'true' ]; then
      # https://git-scm.com/docs/git-config#_variables
      git config set user.name "${name}"
      git config set user.email "${email}"
      git config set user.signingkey ''
      git config set --bool commit.gpgsign false
      git config set --bool tag.gpgsign false
      git config set --bool tag.forcesignannotated false
      git config set gpg.format openpgp
      echo "$(git config get user.name) <$(git config get user.email)> - $PWD"
    fi
    cd ..
  done
fi
