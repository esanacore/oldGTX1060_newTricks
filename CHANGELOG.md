# Changelog

All notable user-facing changes to this project should be documented in this file.

This project follows semantic versioning.

## Unreleased

### Added

### Changed

### Fixed

### Removed

### Security

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

[1.0.0]: https://github.com/esanacore/gtx1060-vfio-inference-vm/releases/tag/v1.0.0
