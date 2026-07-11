# Incident: pre-existing `ollama.service` crash loop (host)

Found and fixed on the host while investigating an unrelated hard-hang, but
**this bug predates and is unrelated to the VFIO/VM work** — confirmed
present since a boot hours before any GPU passthrough changes began.

## Symptom

`ollama.service` was crash-looping every ~3 seconds indefinitely:

```
mkdir ...: file exists: ensure path elements are traversable
```

## Root cause

`~/.ollama/models` is a symlink pointing at
`/mnt/T9/AI_Workstation_Hub/06_Data_Vault/ollama_models`, on an exFAT drive
(`T9`). The `/etc/fstab` entry for that drive was **commented out**, so the
drive never mounted at boot, the symlink target never existed, and
`ollama.service` (which starts early via systemd, with no dependency on the
mount) kept failing to traverse the dangling symlink and restarting forever.

## Fix

1. **Enable the fstab entry properly**, with `nofail` (don't block boot if
   the drive isn't present) and `x-systemd.automount` (mount on first access
   rather than blocking startup on it):

   ```
   UUID=6A7F-B8D3 /mnt/T9 exfat defaults,nofail,x-systemd.automount,uid=1000,gid=1000,umask=000 0 0
   ```

   See [`configs/host/fstab-t9-entry`](../configs/host/fstab-t9-entry).

2. **Make the systemd unit actually wait on the mount** rather than racing
   it — added to `ollama.service`:

   ```ini
   [Unit]
   After=network-online.target mnt-T9.mount
   RequiresMountsFor=/mnt/T9
   ```

   Full unit: [`configs/host/ollama.service`](../configs/host/ollama.service).

## Verification

`systemctl status ollama` showed `Active: running` with no restart churn, and
`curl http://127.0.0.1:11434/api/tags` returned the expected model list.
