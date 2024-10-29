#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

while getopts ':f' opt; do
  case "${opt}" in
    f)
      force='true'
      ;;
    ?)
      echo "Usage: $0 [-f] <dir>" >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))

readonly force="${force:-false}"

readonly base_dir="${1:-$PWD}"

(
  cd "${base_dir}"

  if [ "${force}" = 'true' ]; then
    rm -f .dockerignore
  elif [ -f '.dockerignore' ]; then
    printf "'%s' already exists.\n" "${base_dir}/.dockerignore" >&2
    exit 3
  fi

  cat <<'EOF' >.dockerignore
# https://docs.docker.com/build/building/context/#dockerignore-files
*~
*.orig
*.sw[a-p]
*.tmp
.DS_Store
[Dd]esktop.ini
Thumbs.db
EOF

  # shellcheck disable=SC2010
  dir_contents="$(ls -A -p -1)"
  if [ -n "${dir_contents}" ]; then
    printf "\n%s\n" "${dir_contents}" >>.dockerignore
  fi
)
