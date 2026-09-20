#!/usr/bin/env bash
VLLM_CONFIG="$(dirname -- "${BASH_SOURCE[0]}")/vllm_profile_fast.sh"
BENCHMARK=tb21smoke4
BENCHMARK_CONFIG=benchmarks/terminal_bench_2_1/terminus_2_smoke4.yaml
BENCHMARK_CONCURRENCY=512
BENCHMARK_EXTRA_ARGS=(
  "++policy_model.responses_api_models.vllm_model.sampling_overrides.max_tokens=49152"
  "++policy_model.responses_api_models.vllm_model.sampling_overrides.thinking_token_budget=32768"
)
