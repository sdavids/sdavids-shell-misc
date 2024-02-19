#!/usr/bin/env bash

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

set -Eeu -o pipefail -o posix

readonly base_dir="${1:-$PWD}"

readonly host_name="${2:-localhost}"

readonly cert_path="${base_dir}/cert.pem"
readonly key_path="${base_dir}/key.pem"

if [ "$(stat -f '%A' "${cert_path}")" != '600' ]; then
  printf '\nWARNING: cert.pem does not have the correct permissions. You can change then via:\n\n\tchmod 600 %s\n' "${cert_path}"
  exit 1
fi

if [ "$(stat -f '%A' "${key_path}")" != '600' ]; then
  printf '\nWARNING: key.pem does not have the correct permissions. You can change then via:\n\n\tchmod 600 %s\n' "${key_path}"
  exit 2
fi

if [ "$(uname)" = 'Darwin' ]; then
  # https://ss64.com/mac/security-cert-verify.html
  security verify-cert -q -n -L -r "${cert_path}"

  # https://ss64.com/mac/security-find-cert.html
  security find-certificate -c "${host_name}"
fi

printf '\n%s\n' "${cert_path}"

openssl x509 -text -noout -in "${cert_path}"

if [ "${host_name}" = 'localhost' ]; then
  # https://man.archlinux.org/man/grep.1
  if [ "$(grep -E -i -c "127\.0\.0\.1\s+localhost" /etc/hosts)" -eq 0 ]; then
    echo "WARNING: /etc/hosts does not have an entry for '127.0.0.1 localhost'" >&2
  fi
else
  # https://man.archlinux.org/man/grep.1
  if [ "$(grep -E -i -c "127\.0\.0\.1\s+localhost.+${host_name//\./\.}" /etc/hosts)" -eq 0 ]; then
    echo "WARNING: /etc/hosts does not have an entry for '127.0.0.1 localhost ${host_name}'" >&2
  fi
fi
