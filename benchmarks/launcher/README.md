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
per call), and `MTP_TOKENS` (MTP speculative decoding).

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
