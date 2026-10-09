#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
# 8-repeat setting validated on 2 nodes (README): two TP2 replicas per node, MTP 5, 8K reasoning / 16K reply caps, 6600 s agent limit.
SUPER_TP=${SUPER_TP:-2}
# MTP_TOKENS= (empty) turns MTP off for checkpoints without MTP weights.
export MTP_TOKENS=${MTP_TOKENS-5}
THINKING_BUDGET=${THINKING_BUDGET:-8192} MAX_TOKENS=${MAX_TOKENS:-16384}
SANDBOX_TIMEOUT=${SANDBOX_TIMEOUT:-6600} SSE_KEEPALIVE_S=${SSE_KEEPALIVE_S-30}
BENCHMARK_REPEATS=${BENCHMARK_REPEATS:-8}
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
BENCHMARK=tb21_opencode
BENCHMARK_CONFIG=benchmarks/terminal_bench_2_1/opencode_fast.yaml
BENCHMARK_CONCURRENCY=${CONCURRENCY:-256}
export NUM_NODES=${NUM_NODES:-2}
BENCHMARK_EXTRA_ARGS+=("++terminal_bench_2_1_opencode_sandboxed_agent.responses_api_agents.opencode_sandboxed_agent.sandbox_timeout=$SANDBOX_TIMEOUT")
# Request timeout so a call dropped on the sandbox-to-model path fails instead of hanging.
BENCHMARK_EXTRA_ARGS+=("++terminal_bench_2_1_opencode_sandboxed_agent.responses_api_agents.opencode_sandboxed_agent.opencode_request_timeout_ms=1800000")
