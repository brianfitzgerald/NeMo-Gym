#!/usr/bin/env bash
# Lightning 3.5 BF16, TP1, official NVIDIA DFlash draft.
# The draft is downloaded from Hugging Face by vLLM at startup.
MODEL_NAME=lightning35-bf16
# The checkpoint declares 256K; explicitly allow the 1M serving limit.
export VLLM_ALLOW_LONG_MAX_MODEL_LEN=1
VLLM_COMMON_ARGS=(
    --trust-remote-code
    --disable-uvicorn-access-log
    --gpu-memory-utilization 0.9
    --tensor-parallel-size 1
    --data-parallel-size 1
    --distributed-executor-backend mp
    --enable-auto-tool-choice
    --tool-call-parser qwen3_coder
    --reasoning-parser nemotron_v3
    --enable-chunked-prefill
    --enable-prefix-caching
    --max-model-len 1048576
    --max-num-batched-tokens 8192
    --max-num-seqs 128
    --kv-cache-dtype fp8
    --no-disable-hybrid-kv-cache-manager
    --no-async-scheduling
    --block-size 128
    --mamba-cache-mode align
    --mamba-ssm-cache-dtype float32
    --model-loader-extra-config '{"enable_multithread_load": true, "num_threads": 16}'
)

VLLM_COMMON_ARGS+=(
    --speculative-config '{"model":"nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4-DFlash","num_speculative_tokens":7,"method":"dflash"}'
)
