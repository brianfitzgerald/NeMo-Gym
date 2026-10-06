#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
BENCHMARK=tb21_pool
BENCHMARK_CONFIG=benchmarks/terminal_bench_2_1/pool.yaml
BENCHMARK_CONCURRENCY=512
export NUM_NODES=${NUM_NODES:-8}
# POOL_BINARY uploads a local pool binary into each sandbox, for task images without curl.
[[ -z "${POOL_BINARY:-}" ]] || BENCHMARK_EXTRA_ARGS+=("++terminal_bench_2_1_pool_sandboxed_agent.responses_api_agents.pool_sandboxed_agent.local_pool_binary_path=$POOL_BINARY")
