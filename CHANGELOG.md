# Changelog

All notable user-facing changes to this project should be documented in this file.

This project follows semantic versioning.

## Unreleased

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

### Changed

### Fixed

### Removed

### Security
