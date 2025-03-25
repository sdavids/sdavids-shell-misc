#!/usr/bin/env bash

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -Eeu -o pipefail -o posix

# https://hub.docker.com/r/asciidoctor/docker-asciidoctor
readonly asciidoctor_version=1.84.0
readonly asciidoctor_image="asciidoctor/docker-asciidoctor:${asciidoctor_version}"

# https://stackoverflow.com/a/3915420
# https://stackoverflow.com/questions/3915040/how-to-obtain-the-absolute-path-of-a-file-via-shell-bash-zsh-sh#comment100267041_3915420
command -v realpath >/dev/null 2>&1 || realpath() {
  if [ -h "$1" ]; then
    # shellcheck disable=SC2012
    ls -ld "$1" | awk '{ print $11 }'
  else
    echo "$(
      cd "$(dirname -- "$1")" >/dev/null
      pwd -P
    )/$(basename -- "$1")"
  fi
}

while getopts ':fno:s:' opt; do
  case "${opt}" in
    f)
      force='true'
      ;;
    n)
      no_cache='true'
      ;;
    o)
      host_build_dir="${OPTARG}"
      ;;
    s)
      host_src_dir="${OPTARG}"
      ;;
    ?)
      echo "Usage: $0 -d <directory> [-n]" >&2
      exit 1
      ;;
  esac
done

readonly theme='basic'

readonly force="${force:-false}"
readonly no_cache="${no_cache:-false}"

host_src_dir="${host_src_dir:-$PWD/src}"

if [ ! -d "${host_src_dir}" ]; then
  printf "The source directory '%s' does not exist\n" "${host_src_dir}" >&2
  exit 1
fi

host_src_dir="$(realpath "${host_src_dir}")"
readonly host_src_dir

host_build_dir="${host_build_dir:-$PWD/build}"

if [ "${force}" = 'true' ] \
  && [ -d "${host_build_dir}" ] \
  && [ "${host_build_dir}" != "$PWD" ] \
  && [ "${host_build_dir}" != '.' ]; then

  rm -rf "${host_build_dir}"
fi

mkdir -p "${host_build_dir}"

host_build_dir="$(realpath "${host_build_dir}")"
readonly host_build_dir

readonly src_dir='/documents'
readonly out_dir='/mnt/out'

readonly build_dir="/tmp/build"

cmd="asciidoctor-pdf -R ${src_dir} -D ${build_dir}"
cmd+=' -r asciidoctor-diagram'
cmd+=' -a toc'
# https://docs.asciidoctor.org/pdf-converter/latest/optimize-pdf/#enable-stream-compression
cmd+=' -a compress'
# https://docs.asciidoctor.org/pdf-converter/latest/icons/#icons-attribute
cmd+=' -a icons=font -a icon-set=fas'
if [ -d "${host_src_dir}/fonts" ]; then
  # https://docs.asciidoctor.org/pdf-converter/latest/theme/apply-theme/#theme-and-font-directories
  cmd+=" -a pdf-fontsdir=${src_dir}/fonts"
fi
if [ -d "${host_src_dir}/themes" ]; then
  # https://docs.asciidoctor.org/pdf-converter/latest/theme/apply-theme/#theme-and-font-directories
  cmd+=" -a pdf-themesdir=${src_dir}/themes"
  if [ -f "${host_src_dir}/themes/${theme}-theme.yml" ]; then
    # https://docs.asciidoctor.org/pdf-converter/latest/theme/apply-theme/#theme-and-font-directories
    cmd+=" -a pdf-theme=${theme}-theme.yml"
  fi
  if [ -f "${host_src_dir}/themes/basic-plantuml.cfg" ]; then
    # https://docs.asciidoctor.org/pdf-converter/latest/image-paths-and-formats/#svg
    cmd+=" -a plantumlconfig=/documents/themes/basic-plantuml.cfg"
  fi
fi
if [ "${no_cache}" != 'false' ]; then
  # https://docs.asciidoctor.org/diagram-extension/latest/generate/#diagram_caching
  cmd+=' -a diagram-nocache-option'
fi
cmd+=" '**/*.adoc'"
if [ "${no_cache}" = 'false' ]; then
  cmd+=" && find ${build_dir} -depth -name '_includes' -type d -exec rm -rf {} \; && cp -r -f ${build_dir}/* ${out_dir}"
else
  cmd+=" && cd ${build_dir} && find . -name '_includes' -prune -o \( -type f -name \*.pdf \) -exec cp --parents {} ${out_dir} \;"
fi
readonly cmd

docker run \
  --user "$(id -u):$(id -g)" \
  --rm \
  --security-opt='no-new-privileges=true' \
  --cap-drop=all \
  --mount "type=bind,src=${host_src_dir},dst=${src_dir},readonly" \
  --mount "type=bind,src=${host_build_dir},dst=${out_dir}" \
  --env XDG_CACHE_HOME='/tmp' \
  "${asciidoctor_image}" \
  sh -c "${cmd}"
