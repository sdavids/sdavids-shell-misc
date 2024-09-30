#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# javap needs to be in $PATH

set -eu

readonly jar="${1:?JAR_FILE is required}"

# shellcheck disable=SC2016,SC2046
printf "%s" "$(
  javap \
    -verbose \
    -classpath \
    "${jar}" \
    $(
      jar -tf "${jar}" \
        | grep '\.class$' \
        | grep -E --invert-match '(module|package)-info' \
        | sed 's/\.class$//'
    ) \
    | grep -o 'major version: [4-9][0-9]' \
    | sed 's/major version: //' \
    | sort -u \
    | xargs -I {} sh -c 'echo "$(( {} - 44 ))"' \
    | awk 'NR==1||$0>x{x=$0}END{print x}'
)"
