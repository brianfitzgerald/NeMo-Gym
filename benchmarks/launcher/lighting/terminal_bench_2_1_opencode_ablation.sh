#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
# TB 2.1 OpenCode on a fixed task subset with inference ablations chosen by environment variables:
#   TB21_SUBSET      prepared benchmark.jsonl filtered to the tasks (unset: the full 89-task benchmark)
#   HARNESS          opencode (default) | pool
#   VLLM_PROFILE     serving profile (default vllm_profile_fast.sh; vllm_profile_fast_bf16kv.sh for BF16 KV, no MTP)
#   MAX_TOKENS       output cap (default 49152)
#   THINKING_BUDGET  reasoning cap (default 32768; "off" sends no budget)
#   TEMPERATURE, TOP_P   sampling overrides (unset: the checkpoint's generation_config.json)
#   REP_PENALTY      repetition_penalty via extra_body (unset: none)
#   EFFORT           max (default) | high | none, as in fast_common.sh
HARNESS=${HARNESS:-opencode}
VLLM_CONFIG="$(dirname -- "${BASH_SOURCE[0]}")/${VLLM_PROFILE:-vllm_profile_fast.sh}"
BENCHMARK=tb21${HARNESS}abl
_gym_root="$(realpath "$(dirname -- "${BASH_SOURCE[0]}")/../../..")"
if [[ -n "${TB21_SUBSET:-}" ]]; then
  [[ "$HARNESS" == opencode ]] || { echo "TB21_SUBSET is only supported with HARNESS=opencode" >&2; exit 2; }
  # The subset path is written into a generated config: environment variables do not reach the OmegaConf resolver in the job.
  mkdir -p "$_gym_root/benchmarks/terminal_bench_2_1/subsets"
  BENCHMARK_CONFIG="benchmarks/terminal_bench_2_1/subsets/opencode_fast_$(basename "${TB21_SUBSET%.jsonl}").yaml"
  sed "s#\${oc.env:TB21_SUBSET}#$(realpath "$TB21_SUBSET")#" "$_gym_root/benchmarks/terminal_bench_2_1/opencode_fast_subset.yaml" > "$_gym_root/$BENCHMARK_CONFIG"
else
  BENCHMARK_CONFIG=benchmarks/terminal_bench_2_1/${HARNESS}_fast.yaml
fi
BENCHMARK_CONCURRENCY=${BENCHMARK_CONCURRENCY:-512}
P=policy_model.responses_api_models.vllm_model
BENCHMARK_EXTRA_ARGS=(
  "++${P}.sampling_overrides.max_tokens=${MAX_TOKENS:-49152}"
  "++route_failures_to_sidecar=true"
)
[[ "${THINKING_BUDGET:-32768}" == off ]] || BENCHMARK_EXTRA_ARGS+=("++${P}.sampling_overrides.thinking_token_budget=${THINKING_BUDGET:-32768}")
[[ -z "${TEMPERATURE:-}" ]] || BENCHMARK_EXTRA_ARGS+=("++${P}.sampling_overrides.temperature=${TEMPERATURE}")
[[ -z "${TOP_P:-}" ]] || BENCHMARK_EXTRA_ARGS+=("++${P}.sampling_overrides.top_p=${TOP_P}")
[[ -z "${REP_PENALTY:-}" ]] || BENCHMARK_EXTRA_ARGS+=("++${P}.extra_body.repetition_penalty=${REP_PENALTY}")
case "${EFFORT:-max}" in
  max) ;;
  high) BENCHMARK_EXTRA_ARGS+=("++${P}.chat_template_kwargs.low_effort=true") ;;
  none) BENCHMARK_EXTRA_ARGS+=("++${P}.chat_template_kwargs.enable_thinking=false") ;;
  *) echo "EFFORT must be max, high, or none" >&2; exit 2 ;;
esac
