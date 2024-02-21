# syntax=docker/dockerfile:1

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

### Builder ###

# https://hub.docker.com/_/alpine
FROM alpine:3.20.0 as builder

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
