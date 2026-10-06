#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
BENCHMARK=tb21_pool
BENCHMARK_CONFIG=benchmarks/terminal_bench_2_1/pool_fast.yaml
BENCHMARK_CONCURRENCY=256
export NUM_NODES=${NUM_NODES:-8}
BENCHMARK_EXTRA_ARGS+=("++terminal_bench_2_1_pool_sandboxed_agent.responses_api_agents.pool_sandboxed_agent.sandbox_timeout=$SANDBOX_TIMEOUT")
