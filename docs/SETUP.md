# Workstation Setup

This repository documents an already-built system rather than shipping
installable software. This guide indexes the setup steps and where each one
is recorded in detail — it doesn't need to be "run" so much as followed on
the actual host/VM.

## Prerequisites

- A host with an IOMMU-capable CPU/motherboard (VT-d for Intel), with it
  enabled in BIOS/UEFI firmware setup.
- `qemu-system-x86`, `libvirt-daemon-system`, `virtinst`, `ovmf`,
  `virt-manager` on the host.
- A second GPU that can be isolated into its own IOMMU group (check with
  `find /sys/kernel/iommu_groups/ -maxdepth 1 -type d` and `lspci` before
  committing to this approach — see `docs/01-diagnosis.md`).

## Order of Operations

1. **Diagnose** — confirm the driver-branch mismatch is actually the
   problem. `docs/01-diagnosis.md`.
2. **Host VFIO setup** — enable IOMMU, bind the target GPU to `vfio-pci` at
   boot. `docs/02-host-vfio-setup.md`. Config files: `configs/host/`.
3. **Provision the VM** — build the guest, attach the GPU as a hostdev,
   handle storage and firmware. `docs/03-vm-provisioning.md`. Reference
   domain XML: `configs/vm/gtx1060-inference-domain.xml`.
4. **Guest driver + container runtime** — install the matching NVIDIA driver
   branch, Docker CE, and `nvidia-container-toolkit` inside the guest.
   `docs/04-guest-driver-docker-gpu.md`.

## Verify Prerequisites

Before starting, confirm IOMMU is actually available:

```bash
dmesg | grep -e DMAR -e IOMMU
```

And that the target GPU lands in a clean IOMMU group (ideally alone, or only
with its own audio function):

```bash
for g in /sys/kernel/iommu_groups/*/devices/*; do
  n=$(basename $(dirname $(dirname "$g")))
  echo "Group $n: $(lspci -nns "${g##*/}")"
done
```

## First Run

Once the host and VM are provisioned per the docs above, confirm the guest
sees the GPU:

```bash
ssh <guest-host> "nvidia-smi"
ssh <guest-host> "docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu24.04 nvidia-smi"
```

See `docs/COMMAND_REFERENCE.md` for the fuller command set.
