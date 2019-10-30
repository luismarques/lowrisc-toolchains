#!/bin/bash
# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

## build-gcc-with-args.sh
#
# Builds:
# - GCC, using crosstool-ng and the .config files provided
# - Qemu (userspace)
#
# Then:
# - Adds a `buildinfo` file describing the configuration
# - Adds cross-compilation configuration files for certain build systems
# - Creates a tar file of the whole install directory

QEMU_VERSION=23967e5b2a6c6d04b8db766a8a149f3631a7b899 # v4.0.1

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

case "${toolchain_target}" in
  riscv*-*-linux-gnu)
    # Build Qemu when building a RISC-V linux toolchain

    qemu_dir="${build_top_dir}/build/qemu"

    git clone https://git.qemu.org/git/qemu.git "${qemu_dir}"
    cd "${qemu_dir}"

    git checkout --force --recurse-submodules "${QEMU_VERSION}"

    mkdir -p "${qemu_dir}/build"
    cd "${qemu_dir}/build"

    "${qemu_dir}/configure" \
      "--prefix=${toolchain_dest}" \
      "--interp-prefix=${toolchain_dest}/${toolchain_target}/sysroot" \
      "--target-list=riscv64-linux-user,riscv32-linux-user,riscv64-softmmu,riscv32-softmmu"

    make -j$(( $(nproc) + 2 ))
    make -j$(( $(nproc) + 2 )) install

    # Copy Qemu licenses into toolchain
    mkdir -p "${toolchain_dest}/share/licenses/qemu"
    cp "${qemu_dir}/LICENSE" "${toolchain_dest}/share/licenses/qemu"
    cp "${qemu_dir}/COPYING" "${toolchain_dest}/share/licenses/qemu"
    cp "${qemu_dir}/COPYING.LIB" "${toolchain_dest}/share/licenses/qemu"

    cd "${build_top_dir}/build/gcc"
  ;;
esac

## Create Toolchain Files!
# These don't yet add cflags ldflags
"${build_top_dir}/generate-cmake-toolchain.sh" \
  "${toolchain_target}" "${toolchain_dest}"
"${build_top_dir}/generate-meson-cross-file.sh" \
  "${toolchain_target}" "${toolchain_dest}"

ls -l "${toolchain_dest}"

# Write out build info
{
  echo "lowRISC toolchain config:  ${toolchain_name}";
  echo "lowRISC toolchain version: ${tag_name}";
  echo "GCC Version:";
  "${toolchain_dest}/bin/${toolchain_target}-gcc" --version \
    | head -n1;

  if [ -x "${toolchain_dest}/bin/qemu-riscv64" ]; then
    echo "Qemu Version:";
    "${toolchain_dest}/bin/qemu-riscv64" --version \
      | head -n1;
  fi

  echo "Built at $(date -u) on $(hostname)";
} >> "${toolchain_dest}/buildinfo"

# Package up toolchain directory
tar -cJ \
  --directory="$(dirname "${toolchain_dest}")" \
  -f "$ARTIFACT_STAGING_DIR/$toolchain_full_name.tar.xz" \
  --transform="s@$(basename "${toolchain_dest}")@$toolchain_full_name@" \
  --owner=0 --group=0 \
  "$(basename "${toolchain_dest}")"
