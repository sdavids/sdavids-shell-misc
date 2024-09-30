#!/usr/bin/env bash

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

#  easyrsa needs to be in $PATH
#   Mac:
#     brew install easy-rsa
#   Linux:
#     https://easy-rsa.readthedocs.io/en/latest/#obtaining-and-using-easy-rsa

# https://github.com/OpenVPN/easy-rsa/blob/master/doc/EasyRSA-Readme.md
# https://github.com/OpenVPN/easy-rsa/blob/master/doc/EasyRSA-Advanced.md
# https://github.com/OpenVPN/easy-rsa/blob/master/README.quickstart.md

set -Eeu -o pipefail -o posix

# shellcheck disable=SC2143
if [ "$(easyrsa --version | grep -E -c 'Version:\s+3.1')" -ne 1 ]; then
  echo 'only version 3.1 of easyRSA supported' >&2
  exit 1
fi

# https://easy-rsa.readthedocs.io/en/latest/advanced/#openssl-config
if [ -n "${EASYRSA_PKI+x}" ]; then
  readonly pki_dir="${EASYRSA_PKI}"
else
  config_dir="${HOME}/.easyrsa"
  if [ "$(uname)" = 'Darwin' ]; then
    config_dir="${HOME}/Library/Application\ Support/easyrsa"
  fi
  if [ -n "${XDG_DATA_HOME+x}" ]; then
    config_dir="${XDG_DATA_HOME}/easyrsa"
  fi
  readonly pki_dir="${config_dir}/pki"
  export EASYRSA_PKI="${pki_dir}"
  unset config_dir
fi

if [ -d "${pki_dir}" ]; then
  printf "The PKI directory '%s' already exists.\n" "${pki_dir}" >&2
  exit 1
fi

mkdir -p "${pki_dir}"

if [ -z "${EASYRSA_REQ_CN+x}" ]; then
  # https://easy-rsa.readthedocs.io/en/latest/advanced/#environmental-variables-reference
  date_host="$(date -Idate), $(hostname -f)"
  export EASYRSA_REQ_CN="Easy-RSA CA (${date_host})"
  unset date_host
fi

# https://easy-rsa.readthedocs.io/en/latest/advanced/#environmental-variables-reference
if [ -n "${EASYRSA_CA_EXPIRE+x}" ]; then
  readonly expire_in_days=$((EASYRSA_CA_EXPIRE))
else
  # https://sslmate.com/blog/post/apples_new_ct_policy
  readonly expire_in_days=180
  export EASYRSA_CA_EXPIRE="${expire_in_days}"
fi

easyrsa --sbatch init-pki

easyrsa --sbatch --silent-ssl build-ca nopass

rm -f "${pki_dir}/vars.example"

readonly vars_file="${EASYRSA_PKI}/vars"

if [ ! -f "${vars_file}" ]; then
  if [ -f /opt/homebrew/etc/easy-rsa/vars.example ]; then
    cp /opt/homebrew/etc/easy-rsa/vars.example "${vars_file}"
  elif [ -f /usr/local/etc/easy-rsa/vars.example ]; then
    cp /usr/local/etc/easy-rsa/vars.example "${vars_file}"
  elif [ -f /usr/share/easy-rsa/vars.example ]; then
    cp /usr/share/easy-rsa/vars.example "${vars_file}"
  else
    touch "${vars_file}"
  fi
fi

chmod 700 "${pki_dir}"
find "${pki_dir}" -type d -exec chmod 700 {} +
find "${pki_dir}" -type f -exec chmod 600 {} +

if [ "$(uname)" = 'Darwin' ]; then
  expires_on="$(date -Idate -v +"${expire_in_days}"d)"
else
  expires_on="$(date -Idate -d "+${expire_in_days} days")"
fi
readonly expires_on

readonly ca_cert="${pki_dir}/ca.crt"

printf "Created certificate authority '%s'; expires on: %s; certificate:\n\n%s\n" "${EASYRSA_REQ_CN}" "${expires_on}" "${ca_cert}"

if command -v sudo >/dev/null 2>&1; then
  set +e
  sudo -l -U "${USER}" >/dev/null 2>/dev/null
  sudoer=$?
  set -e
else
  sudoer=1
fi
readonly sudoer

# shellcheck disable=SC2143
if [ "$(uname)" = 'Darwin' ]; then
  if [ "${sudoer}" = 0 ]; then # sudoer
    {
      printf '\nThe CA root certificate will now be imported into Keychain Access--you will be asked for a login password.\n\nPress any key to start the import...\n\n'
      read -r -s -n 1
    } 1>&2

    # prevent privilege escalation by ensuring fresh password
    sudo --reset-timestamp

    # https://ss64.com/mac/security-cert.html
    sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "${ca_cert}"

    printf "Also, please consult your browser's documentation on how to import and trust the CA certificate '%s'.\n" "${ca_cert}"
  else # not a sudoer
    # using /tmp due to it being globally accessible and being cleaned up on reboot on macOS
    cp "${ca_cert}" /tmp/easyrsa.crt
    chmod 644 /tmp/easyrsa.crt

    printf '\nNow import the certificate into Keychain Access:\n\n'
    printf "1. Import /tmp/easyrsa.crt to the 'System' keychain and double click on '%s' afterward.\n" "${EASYRSA_REQ_CN}"
    printf "2. Under 'When using this certificate' select 'Always trust'.\n"
    printf "3. Verify that it was added to the 'System' and not the 'Login' keychain.\n\n"

    open /tmp
    open -a 'Keychain Access'

    printf "You can delete /tmp/easyrsa.crt once you have imported the certificate into Keychain Access.\n\nAlso, please consult your browser's documentation on how to import and trust the CA certificate '%s'.\n" "${ca_cert}"
  fi
elif [ "$(grep -E -i 'debian|buntu|mint' /etc/*release)" ]; then
  if [ "${sudoer}" = 0 ]; then # sudoer
    {
      printf '\nThe CA root certificate will now be imported into your system.\n\nPress any key to start the import...\n\n'
      read -r -s -n 1
    } 1>&2

    ca_dir='/usr/local/share/ca-certificates/easy-rsa'

    if [ -d "${ca_dir}" ]; then
      printf "The directory '%s' already exists; therefore the root CA certificate has already been added to the system previously. Consult your system documentation on how to update an existing certificate.\n" "${ca_dir}" >&2
      exit 2
    fi

    # prevent privilege escalation by ensuring fresh password
    sudo --reset-timestamp

    sudo mkdir -p "${ca_dir}"
    sudo cp "${ca_cert}" "${ca_dir}"
    sudo chmod 755 "${ca_dir}"
    sudo chmod 644 "${ca_dir}/ca.crt"
    sudo chown -R root:root "${ca_dir}"

    sudo update-ca-certificates

    printf "\nAlso, please consult your browser's documentation on how to import and trust the CA certificate '%s'.\n" "${ca_cert}"
  else # not a sudoer
    printf "Please consult your distribution's and browser's documentation on how to import and trust the CA certificate '%s'.\n" "${ca_cert}"
  fi
elif [ "$(grep -E -i 'centos|fedora|redhat' /etc/*release)" ]; then
  if [ "${sudoer}" = 0 ]; then # sudoer
    {
      printf '\nThe CA root certificate will now be imported into your system.\n\nPress any key to start the import...\n\n'
      read -r -s -n 1
    } 1>&2

    # prevent privilege escalation by ensuring fresh password
    sudo --reset-timestamp

    copied_cert='/etc/pki/ca-trust/source/anchors/easyrsa.crt'
    sudo cp "${ca_cert}" "${copied_cert}"
    sudo chmod 644 "${copied_cert}"
    sudo chown root:root "${copied_cert}"

    sudo update-ca-trust

    printf "Also, please consult your browser's documentation on how to import and trust the CA certificate '%s'.\n" "${ca_cert}"
  else # not a sudoer
    printf "Please consult your distribution's and browser's documentation on how to import and trust the CA certificate '%s'.\n" "${ca_cert}"
  fi
fi
