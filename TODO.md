# TODO

This file is the living roadmap for the project.

Keep entries specific, actionable, and current.

## Features

- [ ] Containerize a real inference workload on the `art` VM (e.g. Ollama or
      vLLM via `docker run --gpus all`) and document the compose/run command
      here as the reference example.

## Technical Debt

- [ ] MOK enrollment was skipped in favor of disabling Secure Boot in the
      `art` VM (see `docs/03-vm-provisioning.md`, "Secure Boot: had to be
      disabled"). Acceptable for this dedicated internal VM, but revisit if
      the VM's threat model ever changes.

## Refactoring

- [ ] N/A — this repository is documentation/config, not application code.

## Testing

- [ ] No automated test suite (see `docs/TEST_PLAN.md`). Re-verify
      `docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu24.04
      nvidia-smi` inside `art` after any host kernel or NVIDIA driver
      upgrade, since that's the one thing most likely to silently break this
      setup.

## Documentation

- [ ] Confirm and record whether switching the host session to Xorg (see
      `docs/06-incident-wayland-gpu-hang.md`) fully eliminated the
      `drmModeAtomicCommit` hangs, or whether further tuning was needed.

## Nice-to-Have

- [ ] Consider MOK-based module signing for the guest NVIDIA driver instead
      of disabling Secure Boot outright, if this VM's purpose expands beyond
      internal inference.
