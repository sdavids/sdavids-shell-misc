#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# script needs to be invoked from the project's root directory

set -eu

if [ -z "$*" ]; then
  echo "Usage: $0 FILE" >&2
  exit 1
fi

readonly file="$1"

if [ -f "${file}" ]; then
  rm -f "${file}"
fi

# https://reproducible-builds.org/docs/source-date-epoch/
SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-$(date +%s)}"
export SOURCE_DATE_EPOCH

if [ "$(uname)" = 'Darwin' ]; then
  build_at="$(date -r "${SOURCE_DATE_EPOCH}" -Iseconds -u | sed -e 's/+00:00$/Z/')"
else
  build_at="$(date -d "@${SOURCE_DATE_EPOCH}" -Iseconds -u | sed -e 's/+00:00$/Z/')"
fi
readonly build_at

branch="$(git rev-parse --verify --abbrev-ref HEAD)"
readonly branch

commit="$(git rev-parse --verify HEAD)"
readonly commit

commit_at="$(git log --max-count=1 --pretty=format:%ct)"
if [ "$(uname)" = 'Darwin' ]; then
  commit_at="$(date -r "${commit_at}" -Iseconds -u | sed -e 's/+00:00$/Z/')"
else
  commit_at="$(date -d "@${commit_at}" -Iseconds -u | sed -e 's/+00:00$/Z/')"
fi
readonly commit_at

if [ -n "${GITHUB_RUN_ID+x}" ]; then
  # https://docs.github.com/en/actions/learn-github-actions/variables#default-environment-variables
  build_id="${GITHUB_RUN_ID}"
elif [ -n "${CI_PIPELINE_ID+x}" ]; then
  # https://docs.gitlab.com/ee/ci/variables/predefined_variables.html
  build_id="${CI_PIPELINE_ID}"
elif [ -n "${BITBUCKET_BUILD_NUMBER+x}" ]; then
  # https://support.atlassian.com/bitbucket-cloud/docs/variables-and-secrets/#Default-variables
  build_id="${BITBUCKET_BUILD_NUMBER}"
elif [ -n "${TRAVIS_BUILD_ID+x}" ]; then
  # https://docs.travis-ci.com/user/environment-variables/#default-environment-variables
  build_id="${TRAVIS_BUILD_ID}"
elif [ -n "${CIRCLE_WORKFLOW_ID+x}" ]; then
  # https://circleci.com/docs/variables/#built-in-environment-variables
  build_id="${CIRCLE_WORKFLOW_ID}"
elif [ -n "${APPVEYOR_BUILD_ID+x}" ]; then
  # https://www.appveyor.com/docs/environment-variables/
  build_id="${APPVEYOR_BUILD_ID}"
elif [ -n "${BUILD_ID+x}" ]; then
  # https://www.jenkins.io/doc/book/pipeline/jenkinsfile/#using-environment-variables
  build_id="${BUILD_ID}"
elif [ -n "${BUILD_NUMBER+x}" ]; then
  # https://www.jetbrains.com/help/teamcity/predefined-build-parameters.html#1c215e8e
  build_id="${BUILD_NUMBER}"
else
  build_id="$(date +%s)"
fi
readonly build_id

printf '{"build":{"id":"%s","time":"%s"},"git":{"branch":"%s","commit":{"id":"%s","time":"%s"}}}' "${build_id}" \
  "${build_at}" \
  "${branch}" \
  "${commit}" \
  "${commit_at}" \
  >"${file}"
