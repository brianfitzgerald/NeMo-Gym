#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
BENCHMARK=swe_verified_pool
BENCHMARK_CONFIG=benchmarks/swebench/verified/pool_fast.yaml
BENCHMARK_CONCURRENCY=256
export NUM_NODES=${NUM_NODES:-4}
BENCHMARK_EXTRA_ARGS+=("++swebench_verified_pool_sandboxed_agent.responses_api_agents.pool_sandboxed_agent.sandbox_timeout=$SANDBOX_TIMEOUT")
# With SSE keepalive, pool streams and waits for long replies instead of retrying them at 5 min.
[[ -z "${SSE_KEEPALIVE_S:-}" ]] || BENCHMARK_EXTRA_ARGS+=("++swebench_verified_pool_sandboxed_agent.responses_api_agents.pool_sandboxed_agent.pool_agent_config.http_timeout=55m0s" "++swebench_verified_pool_sandboxed_agent.responses_api_agents.pool_sandboxed_agent.pool_agent_config.model.provider.openai.use_streaming=true")
