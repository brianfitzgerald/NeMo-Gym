# Getting Started

On your Slurm cluster with Pyxis/Enroot, put these exports in `benchmarks/launcher/.env`, replacing the placeholders:

```bash
# Slurm
export SBATCH_ACCOUNT="<your-slurm-account>"
export SBATCH_PARTITION="<your-gpu-partition>"
export SBATCH_QOS="<your-gpu-qos>"

# Cluster
export REPLICAS_PER_NODE=4

# Images
export GYM_CONTAINER="/path/to/gym.sqsh"
export ROUTER_CONTAINER="/path/to/vllm-router.sqsh"
export VLLM_CONTAINER="registry-1.docker.io#vllm/vllm-openai:v0.29.0-aarch64"

# Sandbox
export OPENSANDBOX_DOMAIN="http://<your-opensandbox-endpoint>"
export OPENSANDBOX_API_KEY="<your-opensandbox-key>"

# Weight and Biases
export WANDB_API_KEY="<your-wandb-key>"
export WANDB_PROJ="<your-project>"
export WANDB_ENTITY="<your-team-or-user>"
export WANDB_MODE=online
```

`eval.sh` automatically loads the gitignored `.env`; no manual sourcing is needed.
Keep credentials private with `chmod 600 benchmarks/launcher/.env`.
Images can be shared `.sqsh` files or Pyxis registry references (`registry#namespace/image:tag`).

From the Gym repository root, launch TB 2.1 with Laguna S and DFlash:

```bash
bash benchmarks/launcher/eval.sh \
  --profile benchmarks/launcher/laguna_s/terminal_bench_2_1.sh \
  --checkpoint /path/to/checkpoints/Laguna-S-2.1-FP8
```

For Laguna XS 2.1 BF16, use the matching XS profile and checkpoint:

```bash
bash benchmarks/launcher/eval.sh \
  --profile benchmarks/launcher/laguna_xs/terminal_bench_2_1.sh \
  --checkpoint /path/to/checkpoints/Laguna-XS-2.1
```

Both profiles use TP1, a 262144-token context limit, and seven DFlash draft tokens.
The XS profile uses `poolside/Laguna-XS-2.1-DFlash`; the S profile retains its
existing `poolside/Laguna-S-2.1-DFlash-FP8` draft.
See the [Laguna XS model card](https://huggingface.co/poolside/Laguna-XS-2.1)
for serving requirements.

Replace `terminal_bench_2_1.sh` with `swe_verified.sh`, `swe_multilingual.sh`,
or `swe_pro.sh` for SWE evaluations. Add `--smoke` for one task and one rollout.
Logs and results go to `runs/<job-id>-<benchmark>/` beside the Gym checkout. Set `RUNS_DIR` to override that location.

# Mounting a Development Gym Checkout

Add this to `benchmarks/launcher/.env`:

```bash
export GYM_DEV_CHECKOUT="/path/to/dev-gym"
```

The checkout must be accessible on compute nodes. It is mounted read-only at
`/mnt/gym-dev` and copied into the container at `/opt/nemo-gym`, excluding runtime
logs, caches, environments and credentials. Installation and evaluation modify only
this private copy. Source edits after startup apply to future jobs; logs and results
still go to the shared run directory.

Set `GYM_INFERENCE_METRICS_ENABLED=true` to scrape vLLM replicas and the router
and publish their counters and gauges through the configured exporters (including W&B).
Router metrics appear under `router/main/`; vLLM metrics remain under `vllm/`.

# Nemotron 3.5 Super

Profiles in `super/` serve one TP4 expert-parallel replica per node (`GPUS_PER_REPLICA=4`,
`REPLICAS_PER_NODE=1`) with the aggregated form of the certified Super 3.5 vLLM configuration
(`benchmarks/nemotron_3.5_super/vllm_configs/nemotron_3.5_super.sh`) with `--reasoning-config`,
temperature 1.0 and top_p 0.95. They use the fast-profile settings: `max_tokens=49152`,
`thinking_token_budget=16384`, failures routed to the sidecar, and the `*_fast.yaml` benchmark configs
(1 repeat; Terminus 2 with 250 turns and a 49,152-token output limit), with a 1 h agent timeout
(`SANDBOX_TIMEOUT`, default 3600), concurrency 256 and a 30 min OpenCode request timeout. Effort
defaults to the chat template's max; `EFFORT=high` or `none` select the other modes of the SFT
template. Each benchmark has an OpenCode/Terminus 2 profile and a pool profile (`*_pool.sh`); TB2.1 also has `terminal_bench_2_1_opencode.sh`.
`POOL_BINARY_PATH` uploads a local pool binary for images without curl, `GIT_MIRROR_DIR` serves
GitHub dependencies from local mirrors, `NUM_NODES` overrides the profile's node count, and
`SBATCH_EXCLUDE` skips faulty nodes.

```bash
bash ./benchmarks/launcher/eval.sh --profile benchmarks/launcher/super/swe_verified.sh --checkpoint /path/to/hf
```

Environment toggles for eval-setting tests: `THINKING_BUDGET` (default 16384), `MAX_TOKENS` (default 49152),
`SANDBOX_TIMEOUT` (default 3600), `SSE_KEEPALIVE_S` (SSE keepalive comments from the model server while a
buffered streaming reply is pending; off by default), `POOL_STREAMING` (pool streams and waits up to 55 min
per call), `MTP_TOKENS` (MTP speculative decoding), and `SUPER_TP` (GPUs per replica: 4 or 2).

TB2.1 tests on an SFT checkpoint with long replies (89 tasks, 2 nodes, 1 h agent limit, 30 min OpenCode
request timeout), 2026-10-06:

| Setting | OpenCode resolved | Timed out / killed | Pool resolved | Pool killed |
|---|---|---|---|---|
| 16K budget | 40.4% | 12 / 5 | cancelled | |
| 16K + `SSE_KEEPALIVE_S=30` | 46.1% | 0 / 10 | streaming fails (exit 1) | |
| 8K budget | 52.8% | 4 / 9 | 43.8% | 24 |
| 4K budget | 51.7% | 4 / 8 | 47.2% | 21 |
| 16K + `MTP_TOKENS=3` | 47.2% | 22 / 7 | 47.2% | 27 |

Gym's model server buffers each reply, so a sandbox call is silent until the reply is ready. On the
remote-sandbox path, silent calls over about 350 s are sometimes dropped, and OpenCode then waits until its
request timeout. The keepalive prevents the drops. The remaining timeouts at short budgets come from
tool-call outputs that run to `max_tokens`.

`terminal_bench_2_1_opencode.sh` defaults to the 8-repeat setting validated on 2 nodes: `SUPER_TP=2` (two TP2
replicas per node), `MTP_TOKENS=5`, concurrency 256 (`CONCURRENCY`), 8K reasoning / 16K reply caps,
`SSE_KEEPALIVE_S=30` and a 6600 s agent limit. Set `MTP_TOKENS=` for checkpoints without MTP weights. Pass
`--name NAME --restarts 2` so a failed start or the 4 h job limit resumes the run.

Throughput tests on an SFT checkpoint, TB2.1 OpenCode, 2 nodes, 10-60 min after start, 2026-10-08:

| Setting | Requests per replica | Gen tok/s per replica | Total gen tok/s | Tok/s per request |
|---|---|---|---|---|
| TP4, no MTP, concurrency 64 / 128 / 256 | 26 / 47 / 114 | 1,720 / 1,960 / 1,880 | 3,400-3,900 | 66 / 42 / 17 |
| TP4, MTP 3, concurrency 128 | 50 | 3,280 | 6,550 | 66 |
| TP4, MTP 5, concurrency 128 / 256 / 384 | 47 / 110 / 175 | 3,550 / 3,940 / 2,930 | 7,100 / 7,900 / 5,850 | 76 / 36 / 17 |
| TP4, MTP 5, concurrency 128, `--max-num-batched-tokens 32768` | 52 | 3,540 | 7,100 | 68 |
| TP2 x 2, MTP 5, concurrency 192 / 256 / 384 | 38 / 46 / 77 | 2,570 / 2,810 / 3,140 | 10,300 / 11,200 / 12,500 | 68 / 61 / 41 |

KV cache use stays under 65%, so compute per decode step limits throughput, not memory. MTP 5 accepts about
3.45 tokens per step at all loads. Two TP2 replicas per node give about 1.45x the throughput of one TP4 replica
at the same speed per request. On the tasks finished in both, MTP and TP2 runs pass at the same or a higher rate
than TP4 runs without MTP.

8-repeat runs (712 rollouts), TP2 x 2, MTP 5, concurrency 256:

| Agent limit | Wall time | Killed rollouts | Mean reward | SE across repeats |
|---|---|---|---|---|
| 3600 s | 2.0 h | 138 (19%) | 52.7% | 1.5 |
| 6600 s | 2.7 h | 69 (9.7%) | 53.5% | 0.7 |

At 6600 s, 20 of the 69 kills are in install-windows-3.11, mailman and qemu-alpine-ssh, where earlier runs showed
tool calls that do not return after the agent starts a background service. A Gym server sometimes fails to start
with "Address already in use" (2 of 7 TP2 x 2 starts); `--restarts` resumes the run.
