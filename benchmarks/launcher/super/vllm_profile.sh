#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
# Nemotron 3.5 Super BF16: one TP4 expert-parallel replica per node, no speculative decoding.
# Flags are the aggregated form of benchmarks/nemotron_3.5_super/vllm_configs/nemotron_3.5_super.sh
# (common and prefill arguments without the KV connector), the certified Super 3.5 eval configuration.
MODEL_NAME=super35
export VLLM_SSM_CONV_STATE_LAYOUT=DS
export VLLM_USE_V2_MODEL_RUNNER=0
VLLM_COMMON_ARGS=(
    --trust-remote-code
    --disable-uvicorn-access-log
    --gpu-memory-utilization 0.85
    --distributed-executor-backend mp
    --data-parallel-backend mp
    --enable-auto-tool-choice
    --tool-call-parser qwen3_coder
    --reasoning-parser nemotron_v3
    --enable-chunked-prefill
    --enable-prefix-caching
    --max-model-len 262144
    --kv-cache-dtype fp8
    --no-disable-hybrid-kv-cache-manager
    --block-size 128
    --mamba-cache-mode align
    --mamba-ssm-cache-dtype float32
    --model-loader-extra-config '{"enable_multithread_load": true, "num_threads": 96}'
    --enable-expert-parallel
    --skip-mm-profiling
    --data-parallel-size 1
    --api-server-count 1
    --max-num-batched-tokens 135680
    --max-num-seqs 1024
    --data-parallel-size-local 1
    --tensor-parallel-size 4
    --reasoning-config '{"reasoning_start_str": "<think>", "reasoning_end_str": "</think>"}'
)
# MTP_TOKENS turns on MTP speculative decoding (checkpoints with MTP weights only).
if [[ -n ${MTP_TOKENS:-} ]]; then
    VLLM_COMMON_ARGS+=(--speculative-config "{\"method\":\"mtp\",\"num_speculative_tokens\":${MTP_TOKENS}}")
fi
