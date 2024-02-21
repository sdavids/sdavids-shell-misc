#!/usr/bin/env sh

#
# Copyright (c) 2024, Sebastian Davids
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -eu

readonly tag="${1:-local}"

readonly dockerfile="${2:-$PWD/Dockerfile}"

if [ ! -f "${dockerfile}" ]; then
  echo "Dockerfile '${dockerfile}' does not exist" >&2
  exit 1
fi

# https://docs.docker.com/reference/cli/docker/image/tag/#description
readonly namespace='sdavids-shell-misc'
readonly repository='sdavids-shell-misc-docker'

readonly label_group='de.sdavids.docker.group'

readonly label="${label_group}=${namespace}"

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
docker image build \
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
