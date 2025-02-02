#!/usr/bin/env bash

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -Eeu -o pipefail -o posix

readonly base_dir="${1:-$PWD}"

branch_to_keep="${2:-}"

(
  cd "${base_dir}"

  if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != 'true' ]; then
    echo "'${base_dir}' is not a git repository" >&2
    exit 1
  fi

  set +e
  if [ -z "${branch_to_keep}" ]; then
    branch_to_keep="$(git config get init.defaultBranch)"
    # shellcheck disable=SC2181
    if [ $? -ne 0 ]; then
      branch_to_keep='main'
    fi
  fi
  readonly branch_to_keep

  git checkout --quiet "${branch_to_keep}" 2>/dev/null
  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    echo "branch '${branch_to_keep}' does not exist" >&2
    exit 2
  fi
  set -e

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
  set +e
  local_branches="$(git branch | grep -v "^* ${branch_to_keep}$" | awk '{$1=$1};1' | awk '{print "- " $0}')"
  remote_branches="$(git ls-remote --quiet --branches origin | awk '{print $2}' | cut -c 12- | grep -v "${branch_to_keep}" | awk '{print "- " $0}')"
  set -e

  if [ -z "${local_branches}" ] && [ -z "${remote_branches}" ]; then
    exit 0
  fi

  printf "\nWARNING: The following branches will be deleted from the repository located at '%s'.\n\n" "$(realpath "${base_dir}")"
  if [ -n "${local_branches}" ]; then
    printf 'Local branches:\n'
    echo "${local_branches}"
  fi
  if [ -n "${remote_branches}" ]; then
    if [ -n "${local_branches}" ]; then
      printf '\n'
    fi
    printf 'Remote branches:\n'
    echo "${remote_branches}"
  fi
  printf '\n'
  read -p 'Do you really want to irreversibly delete these branches (Y/N)? ' -n 1 -r should_delete

  case "${should_delete}" in
    y | Y) printf '\n' ;;
    *)
      printf '\n'
      exit 0
      ;;
  esac

  if [ -n "${local_branches}" ]; then
    git branch | grep -v "^* ${branch_to_keep}$" | xargs -I {} git branch --quiet -D {}
  fi
  if [ -n "${remote_branches}" ]; then
    git ls-remote --quiet --branches origin | awk '{print $2}' | cut -c 12- | grep -v "${branch_to_keep}" | xargs -I {} sh -c 'git push --quiet origin :{}'
  fi
  git fetch --all --prune
)
