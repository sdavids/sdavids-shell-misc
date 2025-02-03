#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# curl needs to be in $PATH
#   Linux:
#     sudo apt-get install curl

# jq needs to be in $PATH
#   Mac:
#     brew install jq
#   Linux:
#     sudo apt-get install jq

set -eu

readonly keycloak_user="${1?user required}"

readonly keycloak_protocol='http'
readonly keycloak_host='localhost'
readonly keycloak_port=8080
readonly keycloak_proxy_path_prefix=''

readonly realm='my-realm'
readonly realm_scope='my-realm-scope'
readonly realm_client_id='my-realm-client'

{
  printf '\nPassword: '
  stty -echo
  IFS= read -r keycloak_password
  stty echo
  printf '\n\n'
} 1>&2

# https://www.keycloak.org/docs/latest/authorization_services/#_service_obtaining_permissions
# https://www.keycloak.org/docs/latest/authorization_services/#_service_authorization_api
# https://man.archlinux.org/man/curl.1
access_token="$(curl \
  -s \
  -f \
  -X 'POST' \
  "${keycloak_protocol}://${keycloak_host}:${keycloak_port}${keycloak_proxy_path_prefix}/realms/${realm}/protocol/openid-connect/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=password' \
  -d "username=${keycloak_user}" \
  -d "password=${keycloak_password}" \
  -d "scope=${realm_scope}" \
  -d "client_id=${realm_client_id}" | jq -r '.access_token')"
readonly access_token

if [ -z "${access_token}" ]; then
  echo "token for user '${keycloak_user}' realm '${realm}' could not be retrieved from '${keycloak_host}:${keycloak_port}'" >&2
  exit 1
fi

if [ "${access_token}" = 'null' ]; then
  echo "token for user '${keycloak_user}' realm '${realm}' could not be retrieved from '${keycloak_host}:${keycloak_port}'" >&2
  exit 2
fi

echo "${access_token}"
