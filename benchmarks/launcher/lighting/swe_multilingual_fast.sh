#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/fast_common.sh"
BENCHMARK=swe_multilingual_fast
BENCHMARK_CONFIG=benchmarks/swebench/multilingual/opencode_fast.yaml
BENCHMARK_CONCURRENCY=256
