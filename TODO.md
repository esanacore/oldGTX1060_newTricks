# TODO

This file is the living roadmap for the project.

Keep entries specific, actionable, and current.

## Features

- [x] ~~Containerize a real inference workload~~ — done: an `ollama/ollama`
      container runs on the `art` VM with `--gpus all`, model storage
      bind-mounted to `/srv/ai/ollama-models` on the dedicated passthrough
      disk. `qwen2.5-coder:7b` verified running 100% on GPU at ~24
      tokens/sec. See `docs/COMMAND_REFERENCE.md`, "Inference Workload
      (Ollama)".
- [ ] Add a persistent LAN port-forward so other devices on the network can
      reach the GTX 1060's Ollama endpoint directly, not just Murderbot
      itself. Plan: forward Murderbot's real LAN IP, port 11435 →
      `192.168.122.27:11434`, mirroring the one-port-per-GPU convention
      already used in GPU4HIRE_AI (11434/11435 for its two A4000 workers).
      Touches host firewall/NAT config — a small, reversible, LAN-only
      change, deferred until actually needed.
- [ ] Revisit whether an on-demand SSH tunnel
      (`ssh -L 11435:192.168.122.27:11434 esanacore@<murderbot-lan-ip>`,
      already documented in `docs/COMMAND_REFERENCE.md`) is sufficient
      long-term, or whether the persistent port-forward above is worth
      doing — depends on how often non-Murderbot devices actually need
      this.

- [ ] Root-cause the Open WebUI tool-call hallucination bug — chat prompts
      sometimes return raw fake tool-call JSON instead of answers. Direct
      Ollama `curl` calls are clean, so Open WebUI itself is injecting the
      trigger; every Workspace-level tool-attachment surface has been ruled
      out. Next steps: try the "Function Calling" Advanced Param's
      Native/Legacy states (currently Default), check Admin Panel → Settings
      for an instance-wide default, and inspect the actual
      `POST /api/chat/completions` body via browser DevTools → Network. See
      `docs/TROUBLESHOOTING.md`, "Open WebUI returns hallucinated tool-call
      JSON instead of answers".

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
