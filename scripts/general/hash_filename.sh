#!/usr/bin/env bash

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -Eeu -o pipefail -o posix

readonly file="${1:?FILE is required}"
readonly echo="${2:-}"

if [ ! -f "${file}" ]; then
  echo "'${file}' does not exist" >&2
  exit 1
fi

sha="$(sha1sum "${file}")"
readonly sha

hash="$(echo "${sha}" | cut -c 1-7)"
readonly hash

filename="$(rev <<<"${file}" | cut -d '.' -f2- | rev)"
readonly filename

readonly extension="${1##*.}"

if [ "${filename}" = "${extension}" ]; then
  filename_hashed="${filename}.${hash[0]}"
else
  filename_hashed="${filename}.${hash[0]}.${extension}"
fi
readonly filename_hashed

mv "${file}" "${filename_hashed}"

if [ "${echo}" = '-e' ]; then
  echo "${filename_hashed}"
fi
