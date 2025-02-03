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

if [ ! -d "${base_dir}" ]; then
  printf "The directory '%s' does not exist.\n" "${base_dir}" >&2
  exit 2
fi

(
  cd "${base_dir}"

  if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != 'true' ]; then
    echo "'${base_dir}' is not a git repository" >&2
    exit 3
  fi

  if [ "${force}" = 'true' ]; then
    rm -f .gitignore
  elif [ -f '.gitignore' ]; then
    printf "'%s' already exists.\n" "${base_dir}/.gitignore" >&2
    exit 4
  fi

  cat <<'EOF' >.gitignore
# https://git-scm.com/docs/gitignore
*~
*.orig
*.sw[a-p]
*.tmp
.DS_Store
[Dd]esktop.ini
Thumbs.db
EOF

  extensions="$(find -E . -type f -not -regex '\./\.git/.*' -not -name '.*' -regex '.+\.[^.\/]+$' | rev | cut -d. -f1 | rev | tr '[:upper:]' '[:lower:]' | sort | uniq | awk '{print "*." $0}')"
  if [ -n "${extensions}" ]; then
    printf "\n%s\n" "${extensions}" >>.gitignore
  fi

  # shellcheck disable=SC2010
  dir_contents="$(ls -A -p -1 | grep -v '^.gitignore$' | grep -v '^.git/$')"
  if [ -n "${dir_contents}" ]; then
    printf "\n%s\n" "${dir_contents}" >>.gitignore
  fi
)
