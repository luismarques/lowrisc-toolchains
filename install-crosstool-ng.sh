#!/bin/bash
# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# master 2019-10-02
CROSSTOOL_NG_VERSION=3f461da11f1f8e9dcfdffef24e1982b5ffd10305

mkdir -p build && cd build || exit 1
git clone https://github.com/crosstool-ng/crosstool-ng || exit 1
cd crosstool-ng || exit 1
git checkout --force $CROSSTOOL_NG_VERSION || exit 1
./bootstrap || exit 1
./configure --prefix=/usr/local && make && sudo make install
