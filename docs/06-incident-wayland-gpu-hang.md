# Incident: host hard-hangs on screen idle/blank (GNOME + NVIDIA + Wayland)

## Symptom

The host became fully unresponsive on multiple occasions — screen goes dark
("no signal" on the monitor), no response to input, requiring a hard
power-button reset to recover. Initially suspected to be sleep/resume
related, or caused by the VFIO/IOMMU changes.

## Investigation

`journalctl --list-boots` showed each affected boot simply stopping mid-log
with no clean shutdown record. Checked for:

- `PM: suspend entry` / resume markers — **absent every time**. The system
  never actually entered S3 suspend; this ruled out the sleep/resume theory.
- Kernel panic / OOM / AER / Xid signatures — none found.
- The VM's raw passthrough disk (`/dev/sdc`) being double-mounted on the host
  at the same time — checked and ruled out (not mounted on host, VM was shut
  off at the time of one check).

The actual smoking gun, found in the kernel/journal log right before one
crash went silent:

```
gnome-shell[...]: Cursor update failed: drmModeAtomicCommit: Invalid argument
```

...immediately followed by repeated **failed password entries** at the lock
screen (the user trying to unlock, input not registering correctly), then
the log going silent entirely. This exact `drmModeAtomicCommit` error was
found recurring across multiple earlier boots too, each followed by a crash —
confirming a systemic, reproducible bug rather than a one-off.

## Root cause

- Session type confirmed `wayland` (`loginctl show-session ... -p Type`).
- GNOME's idle timer (`org.gnome.desktop.session idle-delay`, default 300s)
  blanks/locks the screen after 5 minutes idle.
- The NVIDIA proprietary driver's **hardware-cursor-plane path under
  Wayland** occasionally fails an atomic KMS commit during that blank/lock
  transition. On this driver/kernel combination, the failure is severe
  enough to wedge the entire DRM/GPU stack rather than just glitching the
  cursor — hanging the whole host.
- Not directly caused by the VFIO/IOMMU work — this is a known bug class with
  NVIDIA's proprietary driver + GNOME/Mutter's Wayland cursor-plane handling,
  independent of the second GPU or passthrough setup.

## Fix

Two layers, both applied:

1. **Immediate stopgap** — disable idle-triggered screen blank/lock so the
   trigger condition can't fire:

   ```
   gsettings set org.gnome.desktop.session idle-delay 0
   gsettings set org.gnome.desktop.screensaver lock-enabled false
   ```

   This only removes the *idle* trigger — manually locking the screen
   (Super+L) or other paths to a DPMS blank could still hit the same bug.

2. **Actual fix** — switch the GDM session from Wayland to Xorg, where the
   NVIDIA driver's (much more mature) cursor handling doesn't hit this bug:

   At the GDM login screen, click the gear icon next to the password field →
   **"Ubuntu on Xorg"** → log in.

   Verify afterward: `loginctl show-session $(loginctl | grep <user> | awk '{print $1}') -p Type`
   should report `Type=x11`.

## Verification

After switching to Xorg, watch for recurrence:

```
journalctl | grep drmModeAtomicCommit
```

Should no longer appear in new boots, and no further hard hangs should occur.
