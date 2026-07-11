# ADR: VFIO passthrough VM for the GTX 1060, instead of a host driver downgrade

Status: Accepted

Date: 2026-07-10

## Relationships

- Extends: none
- Supersedes: none
- Related: none

## Context

A GTX 1060 (Pascal, GP106) was added to a host already running an RTX 4080
(Ada Lovelace) on NVIDIA's current driver branch (595.x). The 1060 did not
appear in `nvidia-smi`. Root cause: NVIDIA's current driver branch dropped
support for Pascal-generation GPUs — Pascal is only supported on the 580.xx
Legacy branch, which the 4080 also supports, but the current branch does not
support Pascal at all. See `docs/01-diagnosis.md` for the full diagnosis.

This left one physical machine needing to run two GPUs that each only work
with a different NVIDIA driver branch, with a goal of using the 1060 for
containerized local LLM inference (Docker + `nvidia-container-toolkit`).

## Decision

Pass the GTX 1060 through via VFIO to a dedicated VM (`art`), which runs its
own kernel and its own NVIDIA driver (580.xx Legacy) independently of the
host. Docker CE and `nvidia-container-toolkit` run inside that VM, giving
containerized workloads GPU access to the 1060 without touching the host's
4080 or its 595.x driver at all.

## Consequences

**Positive:**

- The RTX 4080 and its host driver setup are completely untouched — zero
  regression risk to existing host workloads.
- The 1060 gets a driver branch that actually supports it.
- The VM boundary is a clean, well-understood isolation mechanism; the guest
  has no awareness it's virtualized (see the hypervisor-hiding config in
  `docs/03-vm-provisioning.md`).

**Negative:**

- Extra operational surface: a VM to provision, patch, and keep running,
  versus a container running directly on the host.
- Extra resource overhead (VM RAM/CPU allocation) versus native containers.
- One real incident so far attributable to this added complexity: Secure
  Boot in the VM's default UEFI firmware blocked the DKMS-built driver
  module from loading, requiring a firmware-variant swap (see
  `docs/03-vm-provisioning.md`).
- A live PCI rebind attempt (before boot-time binding was set up) caused a
  full host hard-hang — a real risk during initial IOMMU/VFIO bring-up (see
  `docs/02-host-vfio-setup.md`).

## Alternatives Considered

1. **Downgrade the host's NVIDIA driver to 580.xx Legacy.** Would fix the
   1060, but drags the 4080 back to the Legacy branch too, including
   anything depending on newer-branch features. Rejected to avoid touching a
   working setup.
2. **Docker + `nvidia-container-toolkit` directly on the host.** Rejected —
   containers share the *host kernel driver*; there is no way to run two
   driver branches for two GPUs simultaneously this way.
3. **VFIO passthrough to a dedicated VM (chosen).** Each GPU gets its
   appropriate driver branch, fully isolated.
