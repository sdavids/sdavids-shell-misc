#!/usr/bin/env bash

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -Eeu -o pipefail -o posix

while getopts ':d:fgos:' opt; do
  case "${opt}" in
    d)
      dst_dir="${OPTARG}"
      ;;
    f)
      force='true'
      ;;
    g)
      group='true'
      ;;
    o)
      other='true'
      ;;
    s)
      src_dir="${OPTARG}"
      ;;
    ?)
      echo "Usage: $0 -d <directory> [-s <directory>] [-f] [-u]" >&2
      exit 1
      ;;
  esac
done

readonly src_dir="${src_dir:-$PWD}"
readonly dst_dir="${dst_dir:?DESTINATION DIRECTORY is required}"
readonly group="${group:-false}"
readonly other="${other:-false}"
readonly force="${force:-false}"

duplicate_file_names="$(find "${src_dir}" -type f -name '*.sh' -exec basename {} \; | sort -r | uniq -d)"
if [ -n "${duplicate_file_names}" ]; then
  printf 'The following script names are not unique:\n\n'
  echo "${duplicate_file_names}" | while IFS= read -r f; do
    printf '%s\n' "$(basename "${f}")"
    find "${src_dir}" -type f -name "${f}" -exec printf '\t%s\n' {} \;
    printf '\n'
  done
  printf 'Make the file names unique and execute this script again.\n' >&2
  exit 1
fi
unset duplicate_file_names

if [ "${group}" = 'true' ] && [ "${other}" = 'true' ]; then
  perm=755
elif [ "${group}" = 'true' ]; then
  perm=750
elif [ "${other}" = 'true' ]; then
  perm=705
else
  perm=700
fi
readonly perm

mkdir -p "${dst_dir}"
chmod "${perm}" "${dst_dir}"

if [ "${force}" = 'false' ]; then
  src_files="$(find "${src_dir}" -type f -name '*.sh' -exec basename {} \; | sort | uniq)"
  dst_files="$(find "${dst_dir}" -type f -name '*.sh' -maxdepth 1 -exec basename {} \; | sort)"
  comm_files="$(comm -12 <(echo "${src_files}") <(echo "${dst_files}"))"

  if [ -n "${comm_files}" ]; then
    printf 'The following files will be overwritten:\n\n%s\n\n' "${comm_files}"
    read -p 'Do you really want to irreversibly overwrite them (Y/N)? ' -n 1 -r should_overwrite

    case "${should_overwrite}" in
      y | Y) printf '\n' ;;
      *)
        printf '\n'
        exit 0
        ;;
    esac
  fi
fi

find "${src_dir}" -type f -name '*.sh' -exec cp -f {} "${dst_dir}" \;

find "${dst_dir}" -type f -name '*.sh' -exec chmod "${perm}" {} +

if [ "$(uname)" = 'Darwin' ]; then
  find "${dst_dir}" -type f -name '*.sh' -exec xattr -c {} \;
fi
