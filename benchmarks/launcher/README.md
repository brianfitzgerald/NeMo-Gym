# Launching Laguna Evals

On your Slurm cluster with Pyxis/Enroot, add these exports to your `~/.bashrc`, replacing the placeholders:

```bash
export SBATCH_ACCOUNT="<your-slurm-account>"
export SBATCH_PARTITION="<your-gpu-partition>"
export SBATCH_QOS="<your-gpu-qos>"
export REPLICAS_PER_NODE=4
export GYM_CONTAINER="/path/to/gym.sqsh"
export ROUTER_CONTAINER="/path/to/vllm-router.sqsh"
export VLLM_CONTAINER="registry-1.docker.io#vllm/vllm-openai:v0.29.0-aarch64"
export OPENSANDBOX_DOMAIN="http://<your-opensandbox-endpoint>"
export OPENSANDBOX_API_KEY="<your-opensandbox-key>"
export WANDB_API_KEY="<your-wandb-key>"
export WANDB_PROJ="<your-project>"
export WANDB_ENTITY="<your-team-or-user>"
export WANDB_MODE=online
```

Run `source ~/.bashrc` after editing, or export the variables in your current
shell. These settings apply to both models; the launcher uses your exported
environment and does not load a `.env` file.

The commands below use paths relative to the Gym repository root.
To launch from anywhere, use absolute paths for the launcher and profile.

To use a development checkout, export `GYM_DEV_CHECKOUT=/path/to/dev-gym`
before launching. It is mounted at `/opt/nemo-gym` and installed at startup.
The checkout must be accessible on compute nodes. Startup may modify its Ray
dependency and lockfile; unset `GYM_DEV_CHECKOUT` to use the image's checkout.

`GYM_CONTAINER` and `ROUTER_CONTAINER` must be configured before launching;
they have no defaults. `VLLM_CONTAINER` defaults to the ARM64 image shown above
and can be overridden. Image files must be accessible on the compute nodes;
registry images require pull access from those nodes.

Container settings also accept Pyxis registry references (`registry#namespace/image:tag`).
The Gym image must provide `/opt/nemo-gym` and `/opt/nemo_gym_venv`;
the router image must provide `vllm-router`. The default vLLM image is ARM64.
The launcher requests four GPUs per node; adapt the Slurm options in `sbatch.sh`
to your cluster, including the CPU cleanup partition and QOS.

vLLM downloads the official DFlash draft from Hugging Face at startup, so the
workers need outbound access.

Launch TB 2.1 with Laguna S and DFlash:

```bash
bash benchmarks/launcher/eval.sh \
  --profile benchmarks/launcher/laguna/terminal_bench_2_1.sh \
  --checkpoint /path/to/checkpoints/Laguna-S-2.1-FP8
```

Replace `terminal_bench_2_1.sh` with `swe_verified.sh`, `swe_multilingual.sh`,
or `swe_pro.sh` for SWE evaluations. Add `--smoke` for one task and one rollout.
Logs and results go to `runs/<job-id>-<benchmark>/` beside the Gym checkout. Set `RUNS_DIR` to override that location.

# Launching Lighting Evals

Use the same setup above. Launch TB 2.1 with Lightning and DFlash:

```bash
bash benchmarks/launcher/eval.sh \
  --profile benchmarks/launcher/lighting/terminal_bench_2_1.sh \
  --checkpoint /path/to/checkpoints/Lightning-3.5-BF16
```

Replace `terminal_bench_2_1.sh` with `swe_verified.sh`, `swe_multilingual.sh`,
or `swe_pro.sh` for SWE evaluations. Add `--smoke` for one task and one rollout.
