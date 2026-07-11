# Changelog

All notable user-facing changes to this project should be documented in this file.

This project follows semantic versioning.

## Unreleased

### Added

### Changed

### Fixed

### Removed

### Security

## [1.1.0] - 2026-07-11

### Added

- A real inference workload: a persistent `ollama/ollama` container
  (`--gpus all`, `--restart unless-stopped`) running `qwen2.5-coder:7b` on
  the GTX 1060, 100% GPU-offloaded (~24 tokens/sec). Model storage lives at
  `/srv/ai/ollama-models` on the dedicated passthrough disk rather than
  Docker's default volume store. Documented in `docs/COMMAND_REFERENCE.md`.
- A chat UI: `open-webui` container, data at `/srv/ai/open-webui-data`,
  plus a pinned Murderbot dock launcher (custom icon, chromeless Chrome app
  window) for one-click access. Documented in `docs/COMMAND_REFERENCE.md`.

### Fixed

- Open WebUI was hallucinating fake tool calls (e.g. `{"name":
  "get_random_fact", "arguments": {}}`) instead of answering ordinary
  prompts. Caused by the default/native Function Calling mode sending an
  empty `tools` field that `qwen2.5-coder`'s chat template reacts to
  regardless of content. Fixed instance-wide by setting the default
  Function Calling mode to Legacy in Admin Panel → Settings. See
  `docs/TROUBLESHOOTING.md`.

## [1.0.0] - 2026-07-10

### Added

- Initial documentation of the GTX 1060 VFIO passthrough inference VM setup:
  diagnosis, host IOMMU/vfio-pci configuration, `art` VM provisioning
  (repurposed physical disk, hidden hypervisor, Secure Boot disabled),
  guest NVIDIA driver + Docker CE + nvidia-container-toolkit install and
  verification.
- Incident writeups for two unrelated issues found and fixed along the way:
  a pre-existing `ollama.service` crash loop (host), and a GNOME/Wayland +
  NVIDIA cursor-plane bug causing host hard-hangs.
- Adopted Eric's Engineering Constitution.
- `docs/adr/0002-disable-secure-boot-in-guest.md` — dedicated ADR for the
  Secure Boot decision, plus an ADR index at `docs/adr/README.md`.
- `scripts/check-host-config.sh`, `scripts/check-vm-config.sh`, and
  `scripts/verify-gpu-stack.sh` — drift-detection and end-to-end
  verification tooling, tested against the live host and `art` VM.
- README hero diagram (`assets/diagrams/how-it-works.{mmd,svg}`) and an
  annotated project-structure tree, per the constitution's Visual
  Architecture requirement.
- "Current Capabilities," "Who This Is For," and "Getting Started" sections
  in README.md.
- `docs/ARCHITECTURE.md` expanded with System Boundaries, External
  Dependencies, Deployment Model, and Security-Sensitive Areas sections.
- Real content in `SECURITY.md` and `HELP.md`, replacing template
  placeholders.

### Changed

- Reworked TODO.md to reflect newly discovered follow-up work (dependency
  tracking, backup strategy, verification-script scheduling) rather than
  the original constitution-bootstrap placeholders.

[1.1.0]: https://github.com/esanacore/oldGTX1060_newTricks/releases/tag/v1.1.0
[1.0.0]: https://github.com/esanacore/oldGTX1060_newTricks/releases/tag/v1.0.0
