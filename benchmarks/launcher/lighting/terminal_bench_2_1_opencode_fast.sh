#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/fast_common.sh"
BENCHMARK=tb21opencodefast
BENCHMARK_CONFIG=benchmarks/terminal_bench_2_1/opencode_fast.yaml
BENCHMARK_CONCURRENCY=512
