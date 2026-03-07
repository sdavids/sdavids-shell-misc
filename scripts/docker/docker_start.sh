#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

readonly http_port="${1:-3000}"

readonly tag='local'

# https://docs.docker.com/reference/cli/docker/image/tag/#description
readonly namespace='de.sdavids'
readonly repository='sdavids-shell-misc'

readonly label_group='de.sdavids.docker.group'

readonly label="${label_group}=${repository}"

readonly image_name="${namespace}/${repository}"

readonly container_name='sdavids-shell-misc-docker-example'

readonly host_name='localhost'

readonly network_name='sdavids_shell_misc'

# https://docs.docker.com/reference/cli/docker/container/run/#:~:text=The%20%2D%2Dadd%2Dhost%20flag%20supports%20a%20special%20host%2Dgateway%20value%20that%20resolves%20to%20the%20internal%20IP%20address%20of%20the%20host.%20This%20is%20useful%20when%20you%20want%20containers%20to%20connect%20to%20services%20running%20on%20the%20host%20machine.
if [ "$(uname -s)" = 'Linux' ]; then
  add_host=--add-host=host.docker.internal:host-gateway
else
  # host.docker.internal is set automatically on macOS and Windows
  add_host=
fi
readonly add_host

docker network inspect "${network_name}" >/dev/null 2>&1 \
  || docker network create \
    --driver bridge "${network_name}" \
    --label "${label_group}=${namespace}" >/dev/null

# to ensure ${label} is set, we use --label "${label}"
# which might overwrite the label ${label_group} of the image
# shellcheck disable=SC2086
docker container run \
  ${add_host} \
  --init \
  --rm \
  --detach \
  --user www-data \
  --read-only \
  --security-opt='no-new-privileges=true' \
  --cap-drop=all \
  --network="${network_name}" \
  --publish "${http_port}:3000" \
  --name "${container_name}" \
  --label "${label}" \
  "${image_name}:${tag}" >/dev/null

readonly url="http://${host_name}:${http_port}"

printf '\nListen local: %s\n' "${url}"

if command -v pbcopy >/dev/null 2>&1; then
  printf '%s' "${url}" | pbcopy
  printf '\nThe URL has been copied to the clipboard.\n'
elif command -v xclip >/dev/null 2>&1; then
  printf '%s' "${url}" | xclip -selection clipboard
  printf '\nThe URL has been copied to the clipboard.\n'
elif command -v wl-copy >/dev/null 2>&1; then
  printf '%s' "${url}" | wl-copy
  printf '\nThe URL has been copied to the clipboard.\n'
fi
