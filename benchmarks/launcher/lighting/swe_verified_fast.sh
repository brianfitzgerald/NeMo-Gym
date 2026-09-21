#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/fast_common.sh"
BENCHMARK=swe_verified_fast
BENCHMARK_CONFIG=benchmarks/swebench/verified/opencode_fast.yaml
BENCHMARK_CONCURRENCY=512
