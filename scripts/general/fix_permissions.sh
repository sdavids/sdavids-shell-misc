#!/usr/bin/env bash

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -Eeu -o pipefail -o posix

while getopts ':d:guy' opt; do
  case "${opt}" in
    d)
      base_dir="${OPTARG}"
      ;;
    g)
      group='true'
      ;;
    u)
      mask='true'
      ;;
    y)
      yes='true'
      ;;
    ?)
      echo "Usage: $0 -d <directory> [-g] [-u] [-y]" >&2
      exit 1
      ;;
  esac
done

readonly base_dir="${base_dir:?DIRECTORY is required}"
readonly group="${group:-false}"
readonly mask="${mask:-false}"
readonly yes="${yes:-false}"

if [ ! -d "${base_dir}" ]; then
  printf "The directory '%s' does not exist.\n" "${base_dir}" >&2
  exit 2
fi

if [ "${group}" = 'true' ] && [ "${mask}" = 'true' ]; then
  echo "options '-g' and '-u' are exclusive" >&2
  exit 3
elif [ "${group}" = 'true' ]; then
  dir_perm=770
  file_perm=660
  sh_perm=770
elif [ "${mask}" = 'true' ]; then
  dir_perm="$(umask -S)"
  file_perm="$(umask -S | awk '{gsub(/x/, "");print}')"
  sh_perm="$(umask -S)"
else
  dir_perm=700
  file_perm=600
  sh_perm=700
fi

readonly dir_perm
readonly file_perm
readonly sh_perm

(
  cd "${base_dir}"

  # https://stackoverflow.com/a/3915420
  # https://stackoverflow.com/questions/3915040/how-to-obtain-the-absolute-path-of-a-file-via-shell-bash-zsh-sh#comment100267041_3915420
  if [ -z "$(command -v realpath)" ]; then
    realpath() {
      if [ -h "$1" ]; then
        # shellcheck disable=SC2012
        ls -ld "$1" | awk '{print $11}'
      else
        echo "$(
          cd "$(dirname -- "$1")" >/dev/null
          pwd -P
        )/$(basename -- "$1")"
      fi
    }
    export -f realpath
  fi

  hooks_exclusion=''
  if command -v git >/dev/null 2>&1; then
    if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = 'true' ]; then
      set +e
      hooks_path="$(git config get core.hooksPath)"
      set -e
      if [ -n "${hooks_path}" ]; then
        if [ "$(echo "${hooks_path}" | grep -c '\.husky/_')" -eq 1 ]; then
          # remove trailing /_
          hooks_path="$(echo "${hooks_path}" | rev | cut -c 3- | rev)"
        fi
        if [ -d "${base_dir}/${hooks_path}" ]; then
          hooks_exclusion="-not -path ${base_dir}/${hooks_path}/*"
        else
          hooks_path=''
        fi
        readonly hooks_path
      fi
    fi
  fi
  readonly hooks_exclusion

  node_exclusions=''
  if [ "$(find "${base_dir}" -type d -name 'node_modules' -exec printf %c {} + | wc -c)" -ne 0 ]; then
    node_exclusions=' -not -path */node_modules/*'
  fi
  readonly node_exclusions

  pnpm_exclusions=''
  if [ "$(find "${base_dir}" -type d -name '.pnpm-store' -exec printf %c {} + | wc -c)" -ne 0 ]; then
    pnpm_exclusions=' -not -path */.pnpm-store/*'
  fi
  readonly pnpm_exclusions

  printf "\nWARNING: The permissions in the directory '%s' will be fixed.\n" "$(realpath "${base_dir}")"

  if [ -n "${node_exclusions}" ] || [ -n "${pnpm_exclusions}" ]; then
    printf '\nThe following directories will be ignored:\n\n'
    if [ -n "${hooks_exclusion}" ]; then
      realpath "${base_dir}/${hooks_path:-}"
    fi
    find "${base_dir}" -type d \( -name 'node_modules' -o -name '.pnpm-store' \) -exec sh -c 'realpath "$0";' {} \;
  elif [ -n "${hooks_exclusion}" ]; then
    printf "\nThe directory '%s' will be excluded.\n" "$(realpath "${base_dir}/${hooks_path:-}")"
  fi

  if [ "${yes}" = 'false' ]; then
    printf '\n'
    read -p 'Do you really want to irreversibly fix the permissions (Y/N)? ' -n 1 -r should_fix

    case "${should_fix}" in
      y | Y) printf '\n' ;;
      *)
        printf '\n'
        exit 0
        ;;
    esac
  fi

  find "${base_dir}" -type d -exec chmod "${dir_perm}" {} +
  set -f
  # shellcheck disable=SC2086
  find "${base_dir}" -type f ${hooks_exclusion}${node_exclusions}${pnpm_exclusions} -exec chmod "${file_perm}" {} +
  set +f
  find "${base_dir}" -type f -name '*.sh' -exec chmod "${sh_perm}" {} +
)
