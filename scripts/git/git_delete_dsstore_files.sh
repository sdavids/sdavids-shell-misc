#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

readonly base_dir="${1:-$PWD}"

(
  cd "${base_dir}"

  if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != 'true' ]; then
    echo "'${base_dir}' is not a git repository" >&2
    exit 1
  fi

  if [ -z "$(git check-ignore '.DS_Store')" ]; then
    # https://stackoverflow.com/a/3915420
    # https://stackoverflow.com/questions/3915040/how-to-obtain-the-absolute-path-of-a-file-via-shell-bash-zsh-sh#comment100267041_3915420
    command -v realpath >/dev/null 2>&1 || realpath() {
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

    printf "\nThe repository at '%s' does not ignore '.DS_Store' files.\n\n" "$(realpath "${base_dir}")"
    printf "You should add '.DS_Store' to your global exclusion file:\n\n  git config get --global core.excludesfile\n\n"
    printf "And to your project's exclusion file:\n\n  %s\n\n" "$(realpath "${base_dir}/.gitignore")"
    printf -- "---\n\n"
  fi

  find "${base_dir}" -name .DS_Store -print0 | xargs -0 git rm --quiet --force --ignore-unmatch
  find "${base_dir}" -name .DS_Store -delete

  git status --short --porcelain
)
