#!/bin/bash
# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

## generate-gcc-meson-cross-file.sh
#
# This generates a cross file to configure meson for cross-compiling with clang.
#
# Docs: https://mesonbuild.com/Cross-compilation.html

set -e
set -x
set -o pipefail

if ! [ "$#" -ge 2 ]; then
  echo "Usage: $0 <target> <prefix_dir> <cflags...>"
  exit 2
fi;

## Take configuration from arguments
# This is the gcc target triple
toolchain_target="${1}"
# This is the directory where the toolchain has been installed.
toolchain_dest="${2}"
# Remaining cflags for build configurations
toolchain_cflags=("${@:3}")

# Clang requires a `--gcc-toolchain=<path>` argument to find some things
meson_cflags="'--gcc-toolchain=${toolchain_dest}'"
for flag in "${toolchain_cflags[@]}"; do
  if [ -z "${meson_cflags}" ]; then
    meson_cflags+="'${flag}'";
  else
    meson_cflags+=", '${flag}'"
  fi
done

config_dest="${toolchain_dest}/meson-${toolchain_target}-clang.txt"
sysroot_config="";
system_name=""

case "${toolchain_target}" in
  riscv*-*-linux-gnu)
    sysroot_config="sys_root = '${toolchain_dest}/${toolchain_target}/sysroot'";
    system_name="linux";
  ;;
  riscv*-*-elf)
    system_name="bare metal";
  ;;
esac;

tee "${config_dest}" <<CONFIG
# Autogenerated by ${0} on $(date -u)
# Problems? Bug reporting instructions in ${toolchain_dest}/buildinfo
#
# If you have relocated this toolchain, change all occurences of '${toolchain_dest}'
# to point to the new location of the toolchain.

[binaries]
c = '${toolchain_dest}/bin/${toolchain_target}-clang'
cpp = '${toolchain_dest}/bin/${toolchain_target}-clang++'
ar = '${toolchain_dest}/bin/${toolchain_target}-ar'
ld = '${toolchain_dest}/bin/${toolchain_target}-ld'
objdump = '${toolchain_dest}/bin/${toolchain_target}-objdump'
objcopy = '${toolchain_dest}/bin/${toolchain_target}-objcopy'
strip = '${toolchain_dest}/bin/${toolchain_target}-strip'

[properties]
needs_exe_wrapper = true
has_function_printf = false
c_args = [${meson_cflags}]
cpp_args = [${meson_cflags}]
${sysroot_config}

[host_machine]
system = '${system_name}'
cpu_family = '${toolchain_target%%-*}'
endian = 'little'

CONFIG