# GTX 1060 VFIO Passthrough Inference VM

<!-- CONSTITUTION_START -->
[![Eric's Engineering Constitution](https://img.shields.io/badge/Eric's%20Engineering%20Constitution-Adopted-blue)](https://github.com/esanacore/engineering-constitution)
<!-- CONSTITUTION_END -->

Documentation for turning a second, driver-incompatible GPU (GTX 1060) into a
usable local-inference box, without touching the host's primary GPU (RTX 4080)
or its driver branch.

**Host:** `Murderbot` — Ubuntu, RTX 4080 on the NVIDIA 595.x (current) driver branch.
**Guest VM:** `art` (libvirt domain name `gtx1060-inference`) — Ubuntu, GTX 1060
passed through via VFIO, running Docker + nvidia-container-toolkit for
containerized local LLM inference.

## Why a VM instead of driver downgrade or plain Docker-on-host

- The GTX 1060 (Pascal, GP106) is not supported by the 595.x driver branch —
  only the 580.xx Legacy branch. The RTX 4080 (Ada) works on either.
- Downgrading the host driver would have broken the 4080's current setup.
- Docker/`nvidia-container-toolkit` on the host shares the *host kernel driver*
  across all containers and GPUs — you can't run two driver branches
  side-by-side that way, since containers don't get their own driver stack.
- A VM does get its own kernel + driver stack, so the 1060 can run the 580.xx
  Legacy driver independently of whatever the host is running.

## Contents

- [`docs/01-diagnosis.md`](docs/01-diagnosis.md) — why the 1060 wasn't showing
  up in `nvidia-smi`, and why VFIO was chosen over alternatives.
- [`docs/02-host-vfio-setup.md`](docs/02-host-vfio-setup.md) — IOMMU/VT-d,
  GRUB, `vfio-pci` binding, blacklisting `nouveau` on the host.
- [`docs/03-vm-provisioning.md`](docs/03-vm-provisioning.md) — building the
  `art` VM with `virt-install`/libvirt, repurposing a spare physical disk,
  hiding the hypervisor from the NVIDIA driver, Secure Boot gotcha.
- [`docs/04-guest-driver-docker-gpu.md`](docs/04-guest-driver-docker-gpu.md) —
  installing the 580.xx driver, Docker CE (apt, not snap), and
  `nvidia-container-toolkit` inside the guest, plus verification.
- [`docs/05-incident-ollama-crashloop.md`](docs/05-incident-ollama-crashloop.md) —
  an unrelated pre-existing bug found and fixed on the host along the way.
- [`docs/06-incident-wayland-gpu-hang.md`](docs/06-incident-wayland-gpu-hang.md) —
  a host desktop hard-hang bug (GNOME/Wayland + NVIDIA cursor-plane) found and
  worked around during this project.
- [`configs/`](configs/) — the actual config files/snippets referenced by the
  docs above (host modprobe.d, GRUB cmdline, fstab entry, ollama.service, the
  full libvirt domain XML).
- [`docs/adr/0001-...`](docs/adr/0001-vfio-passthrough-vm-over-driver-downgrade.md) —
  the architecture decision record for choosing VFIO passthrough over a
  driver downgrade or host-level Docker.

This repository follows [Eric's Engineering Constitution](https://github.com/esanacore/engineering-constitution)
(see `constitution/`); `docs/SETUP.md`, `docs/OPERATIONS.md`,
`docs/TROUBLESHOOTING.md`, and `docs/COMMAND_REFERENCE.md` are its
governance-standard operational docs, layered on top of the narrative docs
above.

## Quick reference: current end state

| Component | Value |
|---|---|
| Host GPU / driver | RTX 4080 / NVIDIA 595.71.05 |
| Guest GPU / driver | GTX 1060 6GB / NVIDIA 580.159.03 (Legacy branch) |
| VM name (libvirt) | `gtx1060-inference` (hostname `art`) |
| VM disk | raw passthrough of `/dev/sdc` (repurposed physical SSD) |
| VM firmware | OVMF UEFI, Secure Boot **disabled** (see provisioning doc) |
| Guest container runtime | Docker CE 29.x (apt) + nvidia-container-toolkit 1.19.x |
| Verified via | `docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu24.04 nvidia-smi` inside the VM |
