#!/usr/bin/env bash

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -Eeu -o pipefail -o posix

while getopts ':d:nt:' opt; do
  case "${opt}" in
    d) dockerfile="${OPTARG}"
      ;;
    n) no_cache='--pull --no-cache'
      ;;
    t) tag="${OPTARG}"
      ;;
    ?)
      echo "Usage: $0 [-d Dockerfile] [-n] [-t tag]" >&2
      exit 1
      ;;
  esac
done

readonly dockerfile="${dockerfile:-$PWD/Dockerfile}"

readonly no_cache="${no_cache:-}"

readonly tag="${tag:-local}"

if [ ! -f "${dockerfile}" ]; then
  echo "Dockerfile '${dockerfile}' does not exist" >&2
  exit 2
fi

# https://docs.docker.com/reference/cli/docker/image/tag/#description
readonly namespace='de.sdavids'
readonly repository='sdavids-shell-misc'

readonly label_group='de.sdavids.docker.group'

readonly label="${label_group}=${repository}"

readonly image_name="${namespace}/${repository}"

# https://reproducible-builds.org/docs/source-date-epoch/
if [ -z "${SOURCE_DATE_EPOCH:-}" ]; then
  if [ -z "$(git status --porcelain=v1 2>/dev/null)" ]; then
    SOURCE_DATE_EPOCH="$(git log --max-count=1 --pretty=format:%ct)"
  else
    SOURCE_DATE_EPOCH="$(date +%s)"
  fi
  export SOURCE_DATE_EPOCH
fi

if [ "$(uname)" = 'Darwin' ]; then
  created_at="$(date -r "${SOURCE_DATE_EPOCH}" -Iseconds -u | sed -e 's/+00:00$/Z/')"
else
  created_at="$(date -d "@${SOURCE_DATE_EPOCH}" -Iseconds -u | sed -e 's/+00:00$/Z/')"
fi
readonly created_at

if [ -n "${GITHUB_SHA:-}" ]; then
  # https://docs.github.com/en/actions/learn-github-actions/variables#default-environment-variables
  commit="${GITHUB_SHA}"
elif [ -n "${CI_COMMIT_SHA:-}" ]; then
  # https://docs.gitlab.com/ee/ci/variables/predefined_variables.html
  commit="${CI_COMMIT_SHA}"
elif [ -n "${APPVEYOR_REPO_COMMIT:-}" ]; then
  # https://www.appveyor.com/docs/environment-variables/
  commit="${APPVEYOR_REPO_COMMIT}"
elif [ -n "${BITBUCKET_COMMIT:-}" ]; then
  # https://support.atlassian.com/bitbucket-cloud/docs/variables-and-secrets/#Default-variables
  commit="${BITBUCKET_COMMIT}"
elif [ -n "${CIRCLE_SHA1:-}" ]; then
  # https://circleci.com/docs/variables/#built-in-environment-variables
  commit="${CIRCLE_SHA1}"
elif [ -n "${TRAVIS_PULL_REQUEST_SHA:-}" ]; then
  # https://docs.travis-ci.com/user/environment-variables/#default-environment-variables
  commit="${TRAVIS_PULL_REQUEST_SHA}"
elif [ -n "${TRAVIS_COMMIT:-}" ]; then
  # https://docs.travis-ci.com/user/environment-variables/#default-environment-variables
  commit="${TRAVIS_COMMIT}"
elif [ -n "${GIT_COMMIT:-}" ]; then
  # https://plugins.jenkins.io/git/#plugin-content-environment-variables
  readonly commit="${GIT_COMMIT}"
elif [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != 'true' ]; then
  commit='N/A'
else
  if [ -z "$(git status --porcelain=v1 2>/dev/null)" ]; then
    ext=''
  else
    ext='-next'
  fi
  commit="$(git rev-parse --verify HEAD)${ext}"
  unset ext
fi
readonly commit

# to ensure ${label} is set, we use --label "${label}"
# which might overwrite the LABEL ${label_group} of the Dockerfile
# shellcheck disable=SC2086
docker image build \
  ${no_cache} \
  --file "${dockerfile}" \
  --compress \
  --tag "${image_name}:latest" \
  --tag "${image_name}:${tag}" \
  --build-arg "git_commit=${commit}" \
  --build-arg "created_at=${created_at}" \
  --label "${label}" \
  .

echo

docker image inspect -f '{{json .Config.Labels}}' "${image_name}:${tag}"
