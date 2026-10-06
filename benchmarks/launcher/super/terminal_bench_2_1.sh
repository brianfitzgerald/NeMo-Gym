#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
BENCHMARK=tb21
BENCHMARK_CONFIG=benchmarks/terminal_bench_2_1/terminus_2_fast_r1.yaml
BENCHMARK_CONCURRENCY=512
export NUM_NODES=${NUM_NODES:-8}
