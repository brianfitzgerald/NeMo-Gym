#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
# Ablation: TB2.1 OpenCode with the reference Super 3.5 serving (sbatch_external_vllm.sh, prefill/decode split, reference vLLM flags).
# Reference agent and model defaults: no reasoning budget, no reply cap, 3 h agent limit.
# SSE keepalive on (30 s) and 30 min OpenCode request timeout, as in T3.
# Usage: tb21_opencode_refpd.sh CHECKPOINT NAME (env: REPEATS, CONCURRENCY, LIMIT, NUM_PREFILL_NODES, NUM_DECODE_NODES, SBATCH_TIME)
set -euo pipefail
checkpoint=$(realpath "${1:?checkpoint}"); name=${2:?run name}
repo=$(cd "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
# Slurm, OpenSandbox, W&B and run-directory settings (gitignored).
set -a; source "${ENV_FILE:-$repo/benchmarks/launcher/.env}"; set +a

# The batch partition rejects jobs without a GPU request.
export SBATCH_GRES=${SBATCH_GRES:-gpu:4}
export VLLM_MODE=pd NUM_PREFILL_NODES=${NUM_PREFILL_NODES:-1} NUM_DECODE_NODES=${NUM_DECODE_NODES:-1}
export MODEL=$checkpoint MODEL_NAME=super35 EXPERIMENT_NAME=$name
export CONTAINER=${REFPD_CONTAINER:-/lustre/fsw/portfolios/nemotron/projects/nemotron_mfn_e2e/images/shared/super-vl-pd-v0280-f15f68ee-gym-606c1eda-router-84b4425d-tb21-36d417f5-rt-arm64.sqsh}
export VLLM_CONFIG=$repo/benchmarks/nemotron_3.5_super/vllm_configs/nemotron_3.5_super.sh
run_dir=$RUNS_DIR/$name
mkdir -p "$run_dir" "$repo/slurm-logs"
# This checkout replaces the image's Gym, which has no OpenCode version pin or local binary upload.
export MOUNTS="$RUNS_DIR:$RUNS_DIR,$checkpoint:$checkpoint:ro,$repo:$repo:ro,$repo:/opt/Gym,$(dirname "$OPENCODE_BINARY_PATH"):$(dirname "$OPENCODE_BINARY_PATH"):ro"
# The image's baked OpenCode agent venv has a different Ray than its main venv; build a fresh one (Gym pins Ray to the head's).
agent_venv=$RUNS_DIR/.refpd-venvs/opencode_sandboxed_agent
mkdir -p "$agent_venv"
MOUNTS+=",$agent_venv:/opt/uv_venvs/responses_api_agents/opencode_sandboxed_agent"
# Fetch GitHub dependencies from local mirrors when a server venv must be built.
if [[ -n ${GIT_MIRROR_DIR:-} ]]; then
    MOUNTS+=",$GIT_MIRROR_DIR:$GIT_MIRROR_DIR:ro"
    export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0="url.file://$GIT_MIRROR_DIR/.insteadOf" GIT_CONFIG_VALUE_0=https://github.com/
fi
export OPENSANDBOX_PROTOCOL=${OPENSANDBOX_PROTOCOL:-https} ROLLOUTS_FPATH=$run_dir/rollouts.jsonl

agent=terminal_bench_2_1_opencode_sandboxed_agent.responses_api_agents.opencode_sandboxed_agent
# The reference script finds its cleanup helper relative to the submit directory; Slurm logs go to $repo/slurm-logs.
cd "$repo"
bash "$repo/benchmarks/nemotron_3.5_super/sbatch_external_vllm.sh" \
    --config responses_api_models/vllm_model/configs/vllm_model.yaml \
    --config benchmarks/terminal_bench_2_1/opencode_fast.yaml \
    ++num_repeats="${REPEATS:-1}" ++num_samples_in_parallel="${CONCURRENCY:-128}" ++limit="${LIMIT:-null}" \
    "++$agent.local_opencode_binary_path=$OPENCODE_BINARY_PATH" \
    "++$agent.sandbox_timeout=10800" \
    "++$agent.opencode_request_timeout_ms=1800000" \
    ++policy_model.responses_api_models.vllm_model.sse_keepalive_interval_s=30 \
    "++model_call_capture_dir=$run_dir/captures" \
    ++route_failures_to_sidecar=true
