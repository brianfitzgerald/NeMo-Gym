#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
# Shared Super 3.5 settings: one 4-GPU replica per node, Super sampling, and the fast-profile reply and reasoning caps.
# Effort is the chat template default (max); EFFORT=high or none select the SFT template's other modes.
VLLM_CONFIG="$(dirname -- "${BASH_SOURCE[0]}")/vllm_profile.sh"
export REPLICAS_PER_NODE=1 GPUS_PER_REPLICA=4
# Agent wall-clock limit per rollout.
SANDBOX_TIMEOUT=${SANDBOX_TIMEOUT:-3600}
# Reasoning cap and total output cap per reply.
THINKING_BUDGET=${THINKING_BUDGET:-16384}
MAX_TOKENS=${MAX_TOKENS:-49152}
BENCHMARK_EXTRA_ARGS=(
    --config benchmarks/nemotron_3.5_super/policy_model_override.yaml
    ++policy_model.responses_api_models.vllm_model.sampling_overrides.temperature=1.0
    ++policy_model.responses_api_models.vllm_model.sampling_overrides.top_p=0.95
    ++policy_model.responses_api_models.vllm_model.sampling_overrides.max_tokens=$MAX_TOKENS
    ++policy_model.responses_api_models.vllm_model.sampling_overrides.thinking_token_budget=$THINKING_BUDGET
    ++model_endpoint_readiness_timeout_seconds=1800
    # a failed agent /run (sandbox infra error -> HTTP 500) becomes a sidecar failure row instead of aborting the run
    ++route_failures_to_sidecar=true
)
# SSE_KEEPALIVE_S sends SSE keepalive comments while a buffered streaming reply is pending.
[[ -z "${SSE_KEEPALIVE_S:-}" ]] || BENCHMARK_EXTRA_ARGS+=("++policy_model.responses_api_models.vllm_model.sse_keepalive_interval_s=$SSE_KEEPALIVE_S")
case "${EFFORT:-max}" in
  max) ;;
  high) BENCHMARK_EXTRA_ARGS+=("++policy_model.responses_api_models.vllm_model.chat_template_kwargs.low_effort=true") ;;
  none) BENCHMARK_EXTRA_ARGS+=("++policy_model.responses_api_models.vllm_model.chat_template_kwargs.enable_thinking=false") ;;
  *) echo "EFFORT must be max, high, or none" >&2; exit 2 ;;
esac
