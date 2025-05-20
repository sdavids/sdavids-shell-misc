#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2025 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

while getopts ':d:efp:' opt; do
  case "${opt}" in
    d)
      base_dir="${OPTARG}"
      ;;
    e)
      exp='export '
      ;;
    f)
      force='true'
      ;;
    p)
      prefix="${OPTARG}"
      ;;
    ?)
      echo "Usage: $0 [-d <directory>] [-e] [-f] [-p <prefix>] <file>" >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))

readonly base_dir="${base_dir:-$PWD}"
readonly exp="${exp:-}"
readonly force="${force:-false}"
readonly prefix="${prefix:-}"

if [ ! -d "${base_dir}" ]; then
  printf "'%s' is not a directory.\n" "${base_dir}" >&2
  exit 2
fi

if [ -z "${1+x}" ]; then
  if [ -z "${exp}" ]; then
    # https://dotenvx.com
    file='.env'
  else
    # https://direnv.net
    file='.envrc'
  fi
else
  file="$1"
fi

case "${file}" in
  /*)
    # absolute path
    ;;
  *)
    file="${base_dir}/${file}"
    ;;
esac

if [ -d "${file}" ]; then
  printf "'%s' is a directory.\n" "${file}" >&2
  exit 3
elif [ -f "${file}" ]; then
  if [ "${force}" = 'true' ]; then
    rm -f "${file}"
  else
    printf "'%s' already exists.\n" "${file}" >&2
    exit 4
  fi
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

if [ -n "$(command -v git)" ] && [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = 'true' ]; then
  branch="$(git rev-parse --verify --abbrev-ref HEAD)"
  readonly branch

  if [ -z "$(git status --porcelain=v1 2>/dev/null)" ]; then
    ext=''
  else
    ext='-next'
  fi
  commit="$(git rev-parse --verify HEAD)${ext}"
  unset ext
  readonly commit

  commit_at="$(git log --max-count=1 --pretty=format:%ct)"
  if [ "$(uname)" = 'Darwin' ]; then
    commit_at="$(date -r "${commit_at}" -Iseconds -u | sed -e 's/+00:00$/Z/')"
  else
    commit_at="$(date -d "@${commit_at}" -Iseconds -u | sed -e 's/+00:00$/Z/')"
  fi
  readonly commit_at

  printf "# WARNING: will be overwritten by the \`%s\` script
%s%sBUILD_ID=\"%s\"
%s%sBUILD_TIME=\"%s\"
%s%sGIT_BRANCH=\"%s\"
%s%sGIT_COMMIT_ID=\"%s\"
%s%sGIT_COMMIT_TIME=\"%s\"\n" "$0" \
    "${exp}" "${prefix}" "${build_id}" \
    "${exp}" "${prefix}" "${build_at}" \
    "${exp}" "${prefix}" "${branch}" \
    "${exp}" "${prefix}" "${commit}" \
    "${exp}" "${prefix}" "${commit_at}" \
    >"${file}"
else
  printf "# WARNING: will be overwritten by the \`%s\` script
%s%sBUILD_ID=\"%s\"
%s%sBUILD_TIME=\"%s\"\n" "$0" \
    "${exp}" "${prefix}" "${build_id}" \
    "${exp}" "${prefix}" "${build_at}" \
    >"${file}"
fi
