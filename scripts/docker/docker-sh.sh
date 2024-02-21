#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

readonly container_name='sdavids-shell-misc-docker-example'

docker exec \
  --interactive \
  --tty \
  "${container_name}" \
  sh
