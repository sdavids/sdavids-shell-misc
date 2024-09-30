#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# jq needs to be in $PATH
#   Mac:
#     brew install jq
#   Linux:
#     sudo apt-get install jq

set -eu

readonly access_token="${1?access token required}"

echo "${access_token}" | jq -R 'split(".") | .[0],.[1] | @base64d | fromjson'
