# TODO

This file is the living roadmap for the project.

Keep entries specific, actionable, and current.

## Features

- [ ] Containerize a real inference workload on the `art` VM (e.g. Ollama or
      vLLM via `docker run --gpus all`) and document the compose/run command
      as the reference example — verification so far only used a generic
      CUDA test image.

## Technical Debt

- [ ] MOK enrollment was skipped in favor of disabling Secure Boot in the
      `art` VM (see `docs/adr/0002-disable-secure-boot-in-guest.md`).
      Acceptable for this dedicated internal VM, but revisit if the VM's
      threat model ever changes.
- [ ] No CVE/vulnerability tracking for the guest's NVIDIA driver, Docker
      CE, or `nvidia-container-toolkit` packages — they're pinned to
      whatever version was current at install time and never revisited. See
      `docs/ARCHITECTURE.md`'s "External Dependencies".
- [ ] No backup strategy for the VM's disk (raw passthrough of a physical
      SSD, not snapshot-friendly). Currently treated as disposable/
      rebuildable rather than backed-up data — fine today, but worth an
      explicit decision if real work product ever lives on it. See
      `docs/OPERATIONS.md`, "Safe Operations".

## Refactoring

- [ ] N/A — this repository is documentation/config, not application code.

## Testing

- [x] ~~No automated test suite~~ — superseded by
      `scripts/verify-gpu-stack.sh`, `scripts/check-host-config.sh`, and
      `scripts/check-vm-config.sh` (see `scripts/README.md`), which
      together give real drift-detection and end-to-end verification. None
      run in CI (see `docs/TEST_PLAN.md` for why) — remember to run them by
      hand after any host kernel/driver upgrade or `virsh edit` change.
- [ ] The verification container image
      (`nvidia/cuda:12.6.0-base-ubuntu24.04`, used in
      `scripts/verify-gpu-stack.sh` and documented in
      `docs/COMMAND_REFERENCE.md`) is referenced by floating tag, not a
      digest. Low risk for a manual/local-only check, but note it as a gap
      rather than an oversight.
- [ ] Consider a systemd timer on the host that runs
      `scripts/check-host-config.sh` + `scripts/check-vm-config.sh`
      periodically and surfaces drift (e.g. via a desktop notification or
      log entry), rather than relying on remembering to run them by hand.

## Documentation

- [ ] Confirm and record whether switching the host session to Xorg (see
      `docs/06-incident-wayland-gpu-hang.md`) fully eliminated the
      `drmModeAtomicCommit` hangs, or whether further tuning was needed.

## Nice-to-Have

- [ ] If this pattern (dual-GPU, driver-branch-conflict, VFIO passthrough)
      ever gets reused for a third GPU or a different host, consider
      generalizing `docs/SETUP.md` and the ADRs into a template rather than
      a single-machine narrative.
