#!/bin/bash
# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

## build-gcc-with-args.sh
#
# Builds:
# - GCC, using crosstool-ng and the .config files provided
#
# Then:
# - Adds a `buildinfo` file describing the configuration
# - Creates a tar file of the whole install directory

set -e
set -x
set -o pipefail

if ! [ "$#" -eq 3 ]; then
  echo "Usage: $0 <config_name> <target> <dest_dir>"
  exit 2
fi;

## Take configuration from arguments
# This is the name for the tar file, and also the basename of the .config file
toolchain_name="${1}"
# This is the expected gcc target triple (so we can invoke gcc)
toolchain_target="${2}"
# This is the directory where we want the toolchain to be installed.
toolchain_dest="${3}"

build_top_dir="${PWD}"

tag_name="$(git -C "${build_top_dir}" describe --always)"
set +x
echo "##vso[task.setvariable variable=ReleaseTag]${tag_name}"
set -x

toolchain_full_name="${toolchain_name}-${tag_name}"

# crosstools-NG needs the ability to create and chmod the
# $toolchain_dest directory.
sudo mkdir -p "$(dirname "${toolchain_dest}")"
sudo chmod 777 "$(dirname "${toolchain_dest}")"

mkdir -p "${toolchain_dest}"

mkdir -p "${build_top_dir}/build/gcc"
cd "${build_top_dir}/build/gcc"

# Create crosstool-ng config file with correct `CT_PREFIX_DIR`
{
  cat "${build_top_dir}/${toolchain_name}.config";
  echo "";
  echo "# ADDED BY ${0}";
  echo "CT_PREFIX_DIR=\"${toolchain_dest}\"";
  echo "# END ADDED BY ${0}";
} >> .config
ct-ng upgradeconfig
cat .config

# Invoke crosstool-ng
ct-ng build

ls -l "${toolchain_dest}"

# Write out build info
{
  echo    "lowRISC toolchain config:  ${toolchain_name}";
  echo    "lowRISC toolchain version: ${tag_name}";
  echo -n "GCC Version:               ";
  "${toolchain_dest}/bin/${toolchain_target}-gcc" --version \
    | head -n1;
  echo    "Built at $(date -u) on $(hostname)";
} >> "${toolchain_dest}/buildinfo"

# Package up toolchain directory
tar -cJ \
  --directory="$(dirname "${toolchain_dest}")" \
  -f "$ARTIFACT_STAGING_DIR/$toolchain_full_name.tar.xz" \
  --transform="s@$(basename "${toolchain_dest}")@$toolchain_full_name@" \
  --owner=0 --group=0 \
  "$(basename "${toolchain_dest}")"
