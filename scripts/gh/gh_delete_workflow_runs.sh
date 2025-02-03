#!/usr/bin/env bash

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# jq needs to be in $PATH
#   Mac:
#     brew install jq
#   Linux:
#     sudo apt-get install jq

set -Eeu -o pipefail -o posix

while getopts ':k:r:' opt; do
  case "${opt}" in
    k)
      keep="${OPTARG}"
      ;;
    r)
      repo="${OPTARG}"
      ;;
    ?)
      echo "Usage: $0 -r <repository> -k <numberOfWorkflowsToKeep>" >&2
      exit 1
      ;;
  esac
done

if [ -z "${repo+x}" ]; then
  echo '-r <repository> is required' >&2
  exit 2
fi

if [ -n "${keep+x}" ]; then # $keep defined
  case ${keep} in
    '' | *[!0-9]*) # $keep is not a positive integer or 0
      echo "'-k <numberOfWorkflowsToKeep>' needs to be a positive integer; found: '${keep}'" >&2
      exit 3
      ;;
    *) # $keep is a positive integer or 0
      ;;
  esac
else # $keep undefined
  echo '-k <numberOfWorkflowsToKeep> is required' >&2
  exit 4
fi
readonly keep

# https://github.com/settings/tokens
# https://docs.github.com/en/rest/authentication/authenticating-to-the-rest-api?apiVersion=2022-11-28#authenticating-with-a-personal-access-token
# https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens?apiVersion=2022-11-28#repository-permissions-for-actions
#
# needs 'actions:rw' permission
readonly auth_token_file="${GH_DELETE_WORKFLOW_RUNS_TOKEN_FILE:-}"

if [ -z "${auth_token_file}" ]; then
  echo 'environment variable GH_DELETE_WORKFLOW_RUNS_TOKEN_FILE not set' >&2
  exit 5
fi

if [ ! -f "${auth_token_file}" ]; then
  echo "'${auth_token_file}' does not exist" >&2
  exit 6
fi

if [ "$(stat -f '%A' "${auth_token_file}")" != '600' ]; then
  printf "\nWARNING: '%s' does not have the correct permissions. You can change them via:\n\n\tchmod 600 %s\n" "${auth_token_file}" "${auth_token_file}"
  exit 7
fi

auth_token="$(cat "${auth_token_file}")"
readonly auth_token

if [ -z "${auth_token}" ]; then
  echo "'${auth_token_file}' is empty" >&2
  exit 8
fi

readonly owner='sdavids'

# https://docs.github.com/en/rest/about-the-rest-api/api-versions?apiVersion=2022-11-28
readonly gh_api_version='2022-11-28'

# https://man.archlinux.org/man/curl.1
response="$(
  curl -s \
    -L \
    -H 'Accept: application/vnd.github+json' \
    -H "Authorization: Bearer ${auth_token}" \
    -H "X-GitHub-Api-Version: ${gh_api_version}" \
    -w '%{http_code}' \
    "https://api.github.com/repos/${owner}/${repo}/actions/runs"
)"

content="$(sed '$ d' <<<"${response}")"
readonly content

http_code="$(tail -n1 <<<"${response}")"
if [ "${http_code}" -ne 200 ]; then
  printf 'GH API returned %s with the content:\n\n%s\n' "${http_code}" "${content}" >&2
  exit 9
fi
unset http_code

unset response

candidates="$(
  jq --arg KEEP "${keep}" \
    'if has("workflow_runs") then .workflow_runs | select( . != null ) | sort_by(.run_number) | reverse | .[($KEEP | tonumber):] else [] end' \
    <<<"${content}"
)"

count="$(jq '. | length' <<<"${candidates}")"
readonly count

if [ "${count}" -lt 1 ]; then
  exit 0
fi

printf '\nWARNING: The following %s workflow run(s) will be deleted:\n\n' "${count}"

jq '. | map({display_title,created_at,run_started_at,html_url})' <<<"${candidates}"

printf '\nDo you really want to irreversibly delete the %s workflow run(s)' "${count}"
read -p ' (Y/N)? ' -n 1 -r should_fix

case "${should_fix}" in
  y | Y) printf '\n' ;;
  *)
    printf '\n'
    exit 0
    ;;
esac

jq -r '. | map({url}) | .[].url' <<<"${candidates}" \
  | xargs -L1 -I {} \
    curl -s \
    -L \
    -X DELETE \
    -H 'Accept: application/vnd.github+json' \
    -H "Authorization: Bearer ${auth_token}" \
    -H "X-GitHub-Api-Version: ${gh_api_version}" \
    {}
