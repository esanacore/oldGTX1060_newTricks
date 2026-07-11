# Scripts

Operator tooling for verifying this setup still matches what's documented.
None of these run in CI (see `docs/TEST_PLAN.md` for why) — they're meant to
be run by hand on the Murderbot host after any change to the host, the `art`
VM, or its guest driver/Docker stack.

- **`check-host-config.sh`** — diffs the host's live config files
  (`/etc/default/grub`, `/etc/modprobe.d/*`, `/etc/fstab`,
  `ollama.service`) against `configs/host/`. Read-only, no sudo required.
- **`check-vm-config.sh`** — diffs the `art` VM's live libvirt domain
  definition against `configs/vm/gtx1060-inference-domain.xml`. Requires
  `virsh` access.
- **`verify-gpu-stack.sh`** — end-to-end functional check: SSHes into the
  guest, confirms `nvidia-smi` sees the GTX 1060, then runs a test CUDA
  container via `docker run --gpus all`. This is the closest thing this
  repository has to an automated test.

## Usage

```bash
./scripts/check-host-config.sh
./scripts/check-vm-config.sh
./scripts/verify-gpu-stack.sh
```

Run all three after: a host kernel/NVIDIA driver upgrade, any `virsh
edit`/`virt-xml` change to the VM, or any change to the guest's driver/Docker
setup. See `docs/OPERATIONS.md` for when to run them as part of routine
maintenance, and `docs/COMMAND_REFERENCE.md` for the individual commands
these scripts wrap.
