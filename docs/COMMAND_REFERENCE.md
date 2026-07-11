# Command Reference

Quick reference for operating the `art` VM (libvirt domain `gtx1060-inference`)
and verifying the GPU passthrough stack.

## VM Lifecycle

- `virsh start gtx1060-inference` — start the VM.
- `virsh shutdown gtx1060-inference` — graceful shutdown (equivalent to
  `ssh <guest> "sudo shutdown now"`, prefer this or the SSH form over
  `destroy` for anything holding the raw passthrough disk open).
- `virsh destroy gtx1060-inference` — hard power-off (last resort).
- `virsh domstate gtx1060-inference` — current state.
- `virsh domifaddr gtx1060-inference` — current DHCP lease / IP.
- `virsh dumpxml gtx1060-inference` — live (running) domain config.
- `virsh dumpxml --inactive gtx1060-inference` — persistent (defined) domain
  config, matches `configs/vm/gtx1060-inference-domain.xml`.

## Access

```bash
ssh esanacore@<vm-ip>
```

Passwordless sudo is configured inside the guest via
`/etc/sudoers.d/90-esanacore-nopasswd` for automation.

## GPU / Driver Verification (inside the guest)

```bash
nvidia-smi                 # confirm the GTX 1060 is detected
lspci -k | grep -A3 GP106  # confirm it's bound to the nvidia driver, not nouveau
dkms status                # confirm the driver module built for the running kernel
```

## Docker + GPU Verification (inside the guest)

```bash
sudo docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu24.04 nvidia-smi
```

Confirms the full stack end-to-end: driver → `nvidia-container-toolkit` →
Docker → container.

## Host-Side Diagnostics

```bash
# Confirm the GPU is bound to vfio-pci, not nouveau/nvidia, on the host
lspci -k -s 03:00.0
lspci -k -s 03:00.1

# List recent boots (useful after any host hard-hang)
journalctl --list-boots

# Look for suspend/resume activity in a given boot
journalctl -b <offset> | grep -iE "suspend|resume"

# Look for the known GNOME/Wayland/NVIDIA cursor-plane hang signature
journalctl | grep drmModeAtomicCommit
```

## Automated Verification Scripts

The commands above are also wrapped in `scripts/` for one-shot checks — see
`scripts/README.md`:

```bash
./scripts/check-host-config.sh   # host config files vs configs/host/
./scripts/check-vm-config.sh     # live VM domain XML vs configs/vm/
./scripts/verify-gpu-stack.sh    # end-to-end: nvidia-smi + docker --gpus all
```

## Rebuilding the VM Domain from Scratch

See `docs/03-vm-provisioning.md` for the full procedure, including the
Secure Boot firmware swap. The reference XML at
`configs/vm/gtx1060-inference-domain.xml` reflects the current, working
end state and can be used as a `virsh define` starting point.
