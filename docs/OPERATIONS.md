# Operations

Operational procedures for the `art` VM (libvirt domain `gtx1060-inference`).

## Deployment

- **Environments**: Single environment — the `art` VM running on the
  `Murderbot` host. No staging/production split; this is a personal local
  inference box.
- **Deployment Procedure**: There's no application deploy pipeline here.
  "Deployment" means provisioning or re-provisioning the VM itself — see
  `docs/03-vm-provisioning.md` and `docs/SETUP.md`.
- **Approvals / Gates**: None — single-operator system.
- **Rollback**: The reference domain XML
  (`configs/vm/gtx1060-inference-domain.xml`) is the known-good end state.
  Redefine from it with `virsh define` if live config drifts or breaks.

## Monitoring & Observability

- **Logs**: `journalctl` on the host for host-side issues (GPU
  binding, hangs); `ssh <guest> "journalctl ..."` / `dmesg` inside the guest
  for driver/Docker issues.
- **Metrics**: `nvidia-smi` (host, for the RTX 4080; guest, for the GTX
  1060) is the primary health signal — GPU visible, temps/power sane, no
  stuck processes.
- **Alerts**: None automated. This is a manually-operated personal system.

## Safe Operations

- **Backup/Restore**: The VM's disk is a raw passthrough of a physical SSD
  (`/dev/sdc`), not a snapshot-friendly qcow2 file. There is currently no
  backup of its contents — treat it as disposable/rebuildable rather than
  data you'd restore. Do not `mount` or otherwise touch `/dev/sdc` from the
  host while the VM is running (see the passthrough caution in
  `docs/03-vm-provisioning.md`) — concurrent access can corrupt the guest
  filesystem.
- **Maintenance Mode**: N/A — take the VM down directly
  (`virsh shutdown gtx1060-inference`) when maintenance is needed.
- **Stateful Changes**: Any change to `<hostdev>`, `<disk>`, or firmware
  (`<loader>`/`<nvram>`) sections of the domain XML should be done via
  `virsh define` on a **shut-off** VM, never live-edited on a running one.
  Firmware/NVRAM changes (like the Secure Boot toggle) require deleting and
  regenerating the NVRAM file — see `docs/03-vm-provisioning.md`.

## Incident Response

1. Identify whether the issue is host-side (e.g. full system hang,
   `nvidia-smi` missing the 1060 on the host boot) or guest-side (e.g.
   `nvidia-smi`/Docker GPU access failing inside `art`).
2. Check `journalctl` (host or guest as appropriate) for the known failure
   signatures documented in `docs/TROUBLESHOOTING.md` first — most issues
   hit so far have matched one of those.
3. For host hangs specifically: never attempt a live PCI rebind as a fix.
   Reboot and let the boot-time `modprobe.d`/`initramfs` config re-bind
   `vfio-pci` cleanly.
4. If root cause isn't one of the known issues, capture `journalctl
   --list-boots` and the relevant boot's full log before rebooting/resetting
   — the evidence disappears once the journal rotates or the hang requires a
   hard reset.
