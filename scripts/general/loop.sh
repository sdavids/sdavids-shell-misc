#!/usr/bin/env bash

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -Eeu -o pipefail -o posix

readonly delay="${1:?delay is required}"
readonly initial_delay="${2:?initial delay is required}"
readonly script="${3:?shell script is required}"

case $1 in
  '' | *[!0-9]*)
    echo "delay '$1' is not a positive integer or 0" >&2
    exit 1
    ;;
esac

case $2 in
  '' | *[!0-9]*)
    echo "initial delay '$2' is not a positive integer or 0" >&2
    exit 2
    ;;
esac

if [ ! -f "$3" ]; then
  echo "'$3' does not exist" >&2
  exit 3
fi

sleep "${initial_delay}"

while true; do
  set +e

  "${script}" "${@:4}"

  exit_code="$?"

  set -e

  if [ "${exit_code}" -eq 0 ]; then
    exit 0
  fi

  if [ "${exit_code}" -ne 100 ]; then
    echo "${script} exit code ${exit_code}" >&2
    exit "${exit_code}"
  fi

  sleep "${delay}"
done
