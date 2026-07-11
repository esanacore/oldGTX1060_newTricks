# Troubleshooting

Issues actually encountered while building and operating this setup, and how
they were resolved. See the linked docs for full detail on each.

## Issue: GTX 1060 missing from `nvidia-smi` on the host

- **Symptoms**: Second GPU physically installed, doesn't appear in
  `nvidia-smi` output at all.
- **Cause**: NVIDIA's current driver branch dropped support for Pascal
  (GP10x). The installed driver simply can't see the card.
- **Fix**: Don't try to fix on the host — this is the whole reason this repo
  exists. See `docs/01-diagnosis.md`.

## Issue: `modprobe: ERROR: could not insert 'nvidia': Key was rejected by service`

- **Symptoms**: Inside the guest VM, `nvidia-driver-580` installs and DKMS
  builds the module cleanly, but it won't load after reboot; `nvidia-smi`
  reports it can't communicate with the driver.
- **Cause**: Secure Boot was enabled in the VM's UEFI firmware. DKMS-built
  out-of-tree modules aren't signed with a kernel-trusted key unless MOK
  enrollment happens (an interactive boot-time step that never occurred
  during a headless/SSH driver install).
- **Fix**: Switch the VM to the non-Secure-Boot OVMF firmware variant. Full
  procedure in `docs/03-vm-provisioning.md` ("Secure Boot: had to be
  disabled").

## Issue: full host hard-hang after manually rebinding a GPU to vfio-pci

- **Symptoms**: Screen goes to "no signal," system completely unresponsive,
  requires a hard power-button reset. No panic/OOM/AER/Xid evidence in the
  journal — it just stops logging.
- **Cause (best assessment)**: Live sysfs-based unbind/bind of a GPU to
  `vfio-pci` while the desktop session and audio stack still held it open,
  combined with this being the very first time IOMMU/VT-d was ever active on
  the board.
- **Fix**: Never rebind live. Do the `vfio-pci` binding via `modprobe.d` +
  `initramfs` config so it happens at boot, before any userspace process can
  touch the device. See `docs/02-host-vfio-setup.md`.

## Issue: host hard-hangs on screen idle/blank (unrelated to the above)

- **Symptoms**: Same "no signal, hard reset required" symptom, but occurring
  repeatedly during normal desktop use, seemingly at random.
- **Cause**: GNOME (Wayland session) + the NVIDIA proprietary driver has a
  cursor-plane atomic-commit bug that can wedge the whole DRM/GPU stack
  during the idle screen-blank/lock cycle. Not caused by the VFIO/IOMMU
  work — a known bug class independent of the second GPU.
- **Fix**: Disable idle screen blank as an immediate stopgap; switch the
  session from Wayland to Xorg as the actual fix. Full detail, including how
  it was diagnosed, in `docs/06-incident-wayland-gpu-hang.md`.

## Issue: `ollama.service` crash-looping on the host

- **Symptoms**: Service restarts every ~3 seconds indefinitely with
  `mkdir ...: file exists: ensure path elements are traversable`.
- **Cause**: A dangling symlink to an external drive that wasn't actually
  mounted (commented-out `/etc/fstab` entry racing the service at boot).
  Unrelated to the GPU/VM work — a pre-existing bug found along the way.
- **Fix**: See `docs/05-incident-ollama-crashloop.md`.

## Issue: Open WebUI returns hallucinated tool-call JSON instead of answers

- **Symptoms**: Ordinary factual prompts (e.g. "Why does low tide smell",
  "Tell me a random fun fact about the Roman Empire") returned a raw,
  fabricated tool-call object instead of a natural-language answer — for
  example `{"name": "search_calendar_events", "arguments": {"query": "low
  tide smell"}}` or `{"name": "get_random_fact", "arguments": {}}`. No such
  tools exist or were ever registered.
- **Ruled out**: `format (Ollama)` Advanced Param at "Default" (not forced
  to `json`); the per-message "Code Interpreter" toggle (off); Workspace →
  Models (no profile existed for `qwen2.5-coder:7b` — it was connection-
  auto-detected, so there was no per-model Tools attachment); Workspace →
  Tools, the instance-wide custom-tools registry (empty). Sending the
  identical prompt directly to Ollama's `/api/chat` via `curl` (bypassing
  Open WebUI) returned a clean, correct answer every time — proving the
  model and Ollama were not at fault.
- **Cause**: Open WebUI's "Function Calling" Advanced Param defaults to
  Ollama-native tool-calling. In that mode Open WebUI includes a `tools`
  field in its request to Ollama even when zero tools are actually
  attached (an empty list, not an absent field). `qwen2.5-coder`'s chat
  template checks whether `tools` is *present* in the request, not whether
  it's non-empty — so the mere presence of that key was enough to switch
  the model into tool-call output mode, and with no real tool matching the
  prompt, it fabricated one.
- **Fix**: Admin Panel → Settings → set the default **Function Calling**
  to **Legacy** instead of the native/default mode. Legacy mode doesn't
  pass a native `tools` field through to Ollama, so the model no longer
  sees anything that triggers its tool-call template. Confirmed fixed
  instance-wide (Admin Panel setting, not a per-chat toggle) — verified
  with the same prompts that previously failed.

## Environment Reset (VM)

If the guest ends up in a broken state after driver/firmware experimentation:

1. `virsh destroy gtx1060-inference` (or graceful shutdown if it's still
   responsive).
2. Compare the running config against
   `configs/vm/gtx1060-inference-domain.xml` — redefine from that file if it
   has drifted (`virsh define configs/vm/gtx1060-inference-domain.xml`).
3. If the NVRAM/firmware state is suspect (e.g. Secure Boot re-enrolled
   itself somehow), delete and let it regenerate:
   `rm /var/lib/libvirt/qemu/nvram/gtx1060-inference_VARS.fd`, then
   `virsh start gtx1060-inference`.
