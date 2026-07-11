# Host setup: IOMMU + VFIO binding for the GTX 1060

Goal: make the host bind the GTX 1060 (and its HDMI audio function) to the
generic `vfio-pci` driver at boot, instead of `nouveau` or `nvidia`, so it's
free for a VM to claim exclusively — while leaving the RTX 4080 completely
untouched on the host's normal NVIDIA driver.

## 1. Enable VT-d in BIOS

Done manually in firmware setup (not scriptable) — required for IOMMU to be
available to the kernel at all.

## 2. Enable IOMMU at the kernel level

`/etc/default/grub` — see [`configs/host/grub-cmdline`](../configs/host/grub-cmdline):

```
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash intel_iommu=on iommu=pt"
```

Then `sudo update-grub`.

`iommu=pt` ("passthrough") keeps host devices running in passthrough mode by
default and only applies IOMMU translation to devices explicitly assigned to
a VM — avoids unnecessary translation overhead for everything else on the
system.

## 3. Bind the 1060 to vfio-pci by PCI ID

Found the 1060's vendor:device IDs (`lspci -nn`) — `10de:1c03` (GPU) and
`10de:10f1` (its HDMI audio function) — and created
[`configs/host/modprobe.d/vfio-gtx1060.conf`](../configs/host/modprobe.d/vfio-gtx1060.conf):

```
options vfio-pci ids=10de:1c03,10de:10f1
```

## 4. Blacklist nouveau

[`configs/host/modprobe.d/blacklist-nouveau-1060.conf`](../configs/host/modprobe.d/blacklist-nouveau-1060.conf):

```
blacklist nouveau
blacklist nvidiafb
```

Prevents `nouveau` from racing `vfio-pci` for the card at boot. The `nvidia`
proprietary driver was never a contender for the 1060 in the first place,
since it's on the 595.x branch which doesn't support Pascal — but blacklisting
`nouveau` still matters so it doesn't grab the device before `vfio-pci` does.

## 5. Make sure vfio-pci is available early (initramfs)

Appended `vfio-pci` to `/etc/initramfs-tools/modules`, then:

```
sudo update-initramfs -u -k all
```

This ensures the binding happens **at boot**, before the desktop session or
any other process (X11/Wayland, PipeWire, etc.) can touch the card.

## Why boot-time binding, not live rebinding

Initially this was attempted live — unbinding the 1060 from its running
driver and rebinding to `vfio-pci` via sysfs (`driver_override` +
`/sys/bus/pci/drivers/vfio-pci/bind`) while the desktop session was up.

**This caused a full system hard-hang** requiring a power-button reset. No
software-level fault was found anywhere in the journal (no panic, no OOM, no
AER, no Xid) — the log simply stopped, consistent with a firmware/hardware
level lockup below the OS's ability to log it.

Best-guess root cause: this was the **first time VT-d/IOMMU was ever active**
on this board, combined with live-rebinding a GPU that the desktop compositor
and audio stack (PipeWire/PulseAudio) still held open handles to. Doing the
same rebind automatically at boot (via the modprobe.d + initramfs config
above, before any userspace holds the device) worked cleanly every time
afterward — confirmed via clean `vfio-pci 0000:03:00.0: reset done` messages
in `dmesg` and a fully responsive host.

**Takeaway: always do the first vfio-pci bind at boot, never live, especially
the first time IOMMU is enabled on a board.**

## Result

After reboot, `lspci -k` on the host shows the 1060 (and its audio function)
bound to `vfio-pci`, and it no longer appears in the host's `nvidia-smi` at
all — it's now available to be handed to a VM. See
[`03-vm-provisioning.md`](03-vm-provisioning.md).
