#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

if [ -z "$*" ]; then
  echo "Usage: $0 FILE" >&2
  exit 1
fi

readonly file="$1"

printf '%s' "$(date -Iseconds -u | sed -e 's/+00:00$/Z/')" >"${file}"
