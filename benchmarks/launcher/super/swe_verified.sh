#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
BENCHMARK=swe_verified
BENCHMARK_CONFIG=benchmarks/swebench/verified/opencode_fast.yaml
BENCHMARK_CONCURRENCY=256
export NUM_NODES=${NUM_NODES:-4}
BENCHMARK_EXTRA_ARGS+=("++swebench_verified_opencode_sandboxed_agent.responses_api_agents.opencode_sandboxed_agent.sandbox_timeout=$SANDBOX_TIMEOUT")
# Request timeout so a call dropped on the sandbox-to-model path fails instead of hanging.
BENCHMARK_EXTRA_ARGS+=("++swebench_verified_opencode_sandboxed_agent.responses_api_agents.opencode_sandboxed_agent.opencode_request_timeout_ms=600000")
