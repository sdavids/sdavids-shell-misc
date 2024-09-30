#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

readonly keycloak_user="${1?user required}"

access_token="$(scripts/keycloak/access-token.sh "${keycloak_user}")"
readonly access_token

echo "${access_token}"

scripts/keycloak/decode-access-token.sh "${access_token}"
