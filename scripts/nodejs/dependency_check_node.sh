#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

readonly base_dir="${1:-$PWD}"
readonly ignore_scripts="${2:-true}"

if [ "${base_dir}" != "$PWD" ] && [ "${base_dir}" != '.' ]; then
  cd "${base_dir}"
  if command -v fnm >/dev/null 2>&1; then
    fnm use
  elif command -v nvm >/dev/null 2>&1; then
    nvm use
  fi
fi

if [ ! -d 'node_modules' ]; then
  npm ci --ignore-scripts="${ignore_scripts}" --fund=false
fi

npm outdated --long
