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

## Inference Workload (Ollama)

A persistent `ollama/ollama` container runs on the guest with model storage
bind-mounted to `/srv/ai/ollama-models` — on the dedicated passthrough disk,
not Docker's opaque volume store, so it's easy to find, inspect, or back up
independently of the container's lifecycle.

```bash
# Start (already running with --restart unless-stopped; only needed after
# removing the container or rebuilding the VM):
sudo docker run -d --gpus all \
  -v /srv/ai/ollama-models:/root/.ollama \
  -p 11434:11434 --name ollama --restart unless-stopped ollama/ollama

# Pull a model
sudo docker exec ollama ollama pull qwen2.5-coder:7b

# Confirm it's actually on the GPU (not split with CPU)
sudo docker exec ollama ollama ps

# Run a prompt (CLI)
sudo docker exec ollama ollama run qwen2.5-coder:7b "your prompt here"

# Or via the HTTP API (cleaner output, includes timing/perf stats)
curl -s http://localhost:11434/api/generate -d '{
  "model": "qwen2.5-coder:7b",
  "prompt": "your prompt here",
  "stream": false
}'
```

### Accessing It

- **From Murderbot itself**: point any Ollama-compatible client (CLI, IDE
  plugin, Open WebUI, etc.) at `http://192.168.122.27:11434` directly — the
  host can reach the VM's libvirt NAT IP natively, no extra setup.
- **From another device on the LAN**: not reachable yet — libvirt's
  `default` network is NAT'd behind the host. For occasional use, tunnel
  through the host via SSH:

  ```bash
  ssh -L 11435:192.168.122.27:11434 esanacore@<murderbot-lan-ip>
  # then on the client machine:
  curl http://localhost:11435/api/tags
  ```

  A persistent port-forward (so other LAN devices can reach it without a
  tunnel) is tracked in `TODO.md` rather than done by default, since it's a
  host firewall/NAT change.

## Chat UI (Open WebUI)

A persistent `ghcr.io/open-webui/open-webui` container runs on the guest,
pointed at the local Ollama instance. Its own data (chat history, accounts)
is bind-mounted to `/srv/ai/open-webui-data` — same rationale as the Ollama
model storage: on the dedicated disk, not Docker's opaque volume store.

```bash
# Start (already running with --restart unless-stopped; only needed after
# removing the container or rebuilding the VM):
sudo docker run -d -p 3000:8080 \
  --add-host=host.docker.internal:host-gateway \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  -v /srv/ai/open-webui-data:/app/backend/data \
  --name open-webui --restart unless-stopped \
  ghcr.io/open-webui/open-webui:main
```

Reachable from Murderbot at `http://192.168.122.27:3000`. First visit
requires creating a local admin account (first signup becomes admin — no
email/external verification, fully self-contained on the VM).

### Dock Launcher

A pinned dock icon on Murderbot opens Open WebUI in a chromeless Chrome app
window:

- Launcher: `~/.local/share/applications/art-inference.desktop`
- Icon: `~/.local/share/icons/art-inference.svg` (custom, matches this
  project's diagram palette)
- Pinned via `gsettings set org.gnome.shell favorite-apps [...]`

These live on the host desktop, not in this repository (they're
machine-specific dotfiles, not VM/infra config) — recorded here so the setup
is reproducible if the desktop environment is ever rebuilt.

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
