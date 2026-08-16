# Home

Welcome to the **GTX 1060 VFIO Passthrough Inference VM** wiki. Wiki pages
are authored under `wiki/` in this repository and reviewed through normal
pull requests.

## What this project does

Documentation, reference configs, and verification tooling for turning a
second, driver-incompatible GPU (GTX 1060) into a usable local-inference box
— without touching the host's primary GPU (RTX 4080) or its driver branch.
The host is `Murderbot` (Ubuntu, RTX 4080 on the NVIDIA 595.x branch); the
guest is `art` (libvirt domain `gtx1060-inference`), running the GTX 1060 via
VFIO with Docker + nvidia-container-toolkit for containerized local LLM
inference.

## Who this is for

Primarily the authoritative operational record for this specific machine, so
future changes have a known-good baseline to diff against (see `scripts/`).
Secondarily, a worked example for anyone with two NVIDIA GPUs that require
mutually-incompatible driver branches on one host.

## Getting started

See the README's quick reference and `docs/SETUP.md`; `scripts/` holds the
verification tooling for diffing live state against the recorded baseline.

## Where things live

- `docs/` — VFIO configuration and governance docs
- `scripts/` — baseline verification tooling
- `constitution/` — Eric's Engineering Constitution submodule (read-only)

## See also

- `docs/HELP.md` — common questions and troubleshooting
- `TODO.md` — the living roadmap
