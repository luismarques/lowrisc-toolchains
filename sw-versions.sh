#!/bin/bash

# This documents the versions of any software checked out from git

# LLVM 22.1.7 plus:
# - `.option arch` with optional 0p93 suffix
# - unratified bitmanip extensions
# - jump guards
# - revert D151768
# - fix single byte counters for elided branches
export LLVM_URL=https://github.com/luismarques/llvm-project.git
export LLVM_BRANCH=ot-llvm-22.1.7
export LLVM_COMMIT=fcd9a5cc9b85ce43ecb5f7fbe652217b82f297fe

# Our Binutils fork with unratified bitmanip extensions
export BINUTILS_URL=https://github.com/lowRISC/binutils.git
export BINUTILS_BRANCH=binutils-2_44-unratified-bitmanip

# GMP, which we need to build a static library of
export GMP_URL=https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz
export GMP_SHA256=a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898

# MPFR, which we need to build a static library of
export MPFR_URL=https://gitlab.inria.fr/mpfr/mpfr.git
export MPFR_BRANCH=3.1
