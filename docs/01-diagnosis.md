# Diagnosis: GTX 1060 not showing up in `nvidia-smi`

## Symptom

A GTX 1060 was physically added alongside an existing RTX 4080. `nvidia-smi`
on the host only listed the 4080 — the 1060 didn't appear at all.

## Root cause

NVIDIA's **current** driver branch (595.x at the time) dropped support for
Pascal-generation GPUs (GP10x, which includes the GTX 1060). Pascal is only
supported on the **580.xx Legacy** driver branch. Ada Lovelace (the RTX 4080)
is supported on both branches.

So: one physical machine, one running kernel driver, two GPUs that each only
work with different driver branches. `nvidia-smi` wasn't malfunctioning — the
1060 was simply invisible to a driver build that no longer supports its chip
generation.

## Options considered

1. **Downgrade the host driver to 580.xx Legacy.** Would fix the 1060, but
   drags the 4080 (and everything depending on the current driver's features)
   back to the Legacy branch too. Rejected — didn't want to touch the 4080's
   working setup.
2. **Docker + `nvidia-container-toolkit` directly on the host.** Rejected —
   containers share the *host kernel driver*, they don't get an independent
   driver stack. Can't run 580.xx-for-the-1060 and 595.x-for-the-4080
   simultaneously this way.
3. **VFIO PCI passthrough to a dedicated VM.** Chosen. A VM gets its own
   kernel and its own driver stack, so the 1060 can run 580.xx Legacy inside
   the guest while the host keeps the 4080 on 595.x, completely independent.

## Hardware check before committing to VFIO

IOMMU groups were checked to confirm the 1060 could be isolated cleanly for
passthrough. It landed in its own IOMMU group (group 14) along with just its
HDMI audio function — a clean split off its own PCIe root port
(`00:1b.4`), with no other devices sharing the group that would have to be
passed through too. This favorable topology is what made VFIO passthrough
straightforward on this board.

See [`02-host-vfio-setup.md`](02-host-vfio-setup.md) for the implementation.
