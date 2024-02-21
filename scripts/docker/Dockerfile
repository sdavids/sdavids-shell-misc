# syntax=docker/dockerfile:1

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

### Builder ###

# https://hub.docker.com/_/alpine
FROM alpine:3.19.1 as builder

RUN mkdir -p /tmp/dist && \
    printf '<!doctype html><title>Test</title><h1>Test' > /tmp/dist/index.html

LABEL de.sdavids.docker.group="sdavids-shell-misc" \
      de.sdavids.image.type="builder"

### Final ###

# https://hub.docker.com/_/busybox
FROM busybox:1.36.1-musl

ARG git_commit
ARG created_at

WORKDIR /home/www-data

COPY --from=builder --chown=www-data:www-data /tmp/dist .

# https://boxmatrix.info/wiki/Property:httpd
CMD ["httpd", "-v", "-f", "-p", "3000", "-h", "/home/www-data"]

# https://boxmatrix.info/wiki/Property:wget
HEALTHCHECK --interval=5s --timeout=5s --start-period=5s \
    CMD wget -q -T 3 --spider 'http://localhost:3000/' || exit 1

# https://github.com/opencontainers/image-spec/blob/master/annotations.md
LABEL org.opencontainers.image.revision="${git_commit}" \
      org.opencontainers.image.created="${created_at}" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.vendor="Sebastian Davids" \
      org.opencontainers.image.title="Example HTTP Server" \
      de.sdavids.docker.group="sdavids-shell-misc" \
      de.sdavids.docker.type="production"
