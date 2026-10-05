#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
BENCHMARK=swe_pro_pool
BENCHMARK_CONFIG=benchmarks/swebench/pro/pool.yaml
BENCHMARK_CONCURRENCY=512
export NUM_NODES=${NUM_NODES:-8}
