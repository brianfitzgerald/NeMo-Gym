#!/usr/bin/env bash
# Shared settings for the fast profiles: capped generation on the fast vLLM profile.
VLLM_CONFIG="$(dirname -- "${BASH_SOURCE[0]}")/vllm_profile_fast.sh"
BENCHMARK_EXTRA_ARGS=(
  "++policy_model.responses_api_models.vllm_model.sampling_overrides.max_tokens=49152"
  "++policy_model.responses_api_models.vllm_model.sampling_overrides.thinking_token_budget=32768"
)
