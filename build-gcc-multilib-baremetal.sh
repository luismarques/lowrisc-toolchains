#!/bin/bash

set -e
set -x
set -o pipefail

TOP=$PWD

TAG_NAME="$(git -C $TOP describe --always)"
echo "##vso[task.setvariable variable=ReleaseTag]$TAG_NAME"

TOOLCHAIN_NAME=lowrisc-toolchain-gcc-multilib-baremetal-$TAG_NAME

export CT_PREFIX_DIR=/opt/riscv-baremetal-toolchain

mkdir -p build/gcc
cd build/gcc
cp ../../lowrisc-toolchain-gcc-multilib-baremetal.config .config
ct-ng upgradeconfig
cat .config
ct-ng build

ls -l "${CT_PREFIX_DIR}"

echo "lowRISC toolchain version: ${TAG_NAME}" >> "${CT_PREFIX_DIR}/buildinfo"

echo -n 'GCC version: ' >> "${CT_PREFIX_DIR}/buildinfo"
${CT_PREFIX_DIR}/bin/riscv64-unknown-elf-gcc --version | head -n1 >> "${CT_PREFIX_DIR}/buildinfo"

echo "Built at $(date -u) on $(hostname)" >> ${CT_PREFIX_DIR}/buildinfo

tar -cJ \
  --directory="$(dirname "${CT_PREFIX_DIR}")" \
  -f "$ARTIFACT_STAGING_DIR/$TOOLCHAIN_NAME.tar.xz" \
  --transform="s@$(basename "${CT_PREFIX_DIR}")@$TOOLCHAIN_NAME@" \
  --owner=0 --group=0 \
  "$(basename "${CT_PREFIX_DIR}")"
