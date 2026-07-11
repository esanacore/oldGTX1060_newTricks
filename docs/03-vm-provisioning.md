# Provisioning the `art` VM

## Stack

`qemu-system-x86` + `libvirt-daemon-system` + `virtinst` + `ovmf` (UEFI
firmware) + `virt-manager` (GUI console, used for a couple of manual steps —
see below).

## Naming

Host machine is `Murderbot`. The VM was named `art`, after ART/Perihelion —
the AI research-transport ship from Martha Wells' *Murderbot Diaries* — to
stay in theme. (libvirt domain name is `gtx1060-inference`; `art` is the
guest OS hostname.)

## Storage: repurposed physical disk, not a qcow2 file

Originally provisioned with a qcow2 file on the boot NVMe
(`/var/lib/libvirt/images/gtx1060-inference.qcow2`, 150GB sparse). Later
switched to a spare physical SSD that had a "Nobara" Linux install on it,
repurposed (wiped) for this VM instead — a deliberate choice to give the
inference VM dedicated physical storage rather than sharing the host's boot
drive.

```
virsh detach-disk gtx1060-inference vda --config
virsh attach-disk gtx1060-inference /dev/sdc vda \
  --targetbus virtio --subdriver raw --config --persistent
```

This passes the whole block device through raw (`type='block'`,
`subdriver='raw'`) rather than a file-backed image — see
[`configs/vm/gtx1060-inference-domain.xml`](../configs/vm/gtx1060-inference-domain.xml)
for the resulting `<disk>` stanza.

⚠️ **Caution with raw block passthrough:** the host kernel still sees and can
probe `/dev/sdc`'s partition table even while it's the VM's exclusive backing
store. Don't let anything on the host (udisks2/GNOME automount, manual
`mount`, etc.) touch that device while the VM is running — concurrent access
from both sides can corrupt the guest filesystem. (This surfaced once as a
`FAT-fs (sdc1): Volume was not properly unmounted` kernel message on the host
after a hard crash — benign in that instance since nothing was actually
double-mounting it at the time, but worth being deliberate about.)

## Base install

`virt-install` generated the initial domain XML (`--print-xml`, patched
manually, then `virsh define`) rather than being run directly, so the
Secure-Boot-avoidance tweak below could be applied before first boot.
Installed via Ubuntu Server ISO (`ubuntu-26.04-live-server-amd64.iso`) over
the subiquity installer, SSH access enabled via GitHub key import
(`https://github.com/<user>.keys` — same mechanism `ssh-import-id` uses).

Specs: 8192MB RAM, 4 vcpus, `cpu mode='host-passthrough'`, machine `q35`,
UEFI boot, network `default` (virtio, NAT/DHCP via libvirt).

## GPU passthrough

Both PCI functions of the 1060 (GPU + HDMI audio) attached as `<hostdev>`
entries — see the full XML in
[`configs/vm/gtx1060-inference-domain.xml`](../configs/vm/gtx1060-inference-domain.xml).

## Hiding the hypervisor from the NVIDIA driver

Consumer NVIDIA drivers historically refuse to initialize (Windows: "Code
43"; same underlying check on Linux) if they detect they're running inside a
VM. Standard mitigation, added under `<features>`:

```xml
<kvm>
  <hidden state='on'/>
</kvm>
```

This alone was sufficient. (A CPU `vendor_id` spoof was also tried as
belt-and-suspenders — `<feature name="vendor_id" value="..."/>` under `<cpu>`
— but this libvirt version rejected it as an unsupported configuration, so it
was dropped. Not needed in practice.)

## `on_reboot` policy

`virt-install` defaults new domains to `<on_reboot>destroy</on_reboot>` — a
safety net so an install-time VM doesn't reboot-loop back into the installer
ISO. After the OS install finished, this needs to be flipped or the guest
will just power off (not restart) every time it reboots itself:

```
virt-xml gtx1060-inference --edit --events on_reboot=restart --define
```

## Secure Boot: had to be disabled

The default OVMF firmware libvirt selected was the Microsoft-signed,
Secure-Boot-enabled variant (`OVMF_CODE_4M.ms.fd`, `secure='yes'`). This
became a problem once the NVIDIA driver was installed in the guest (see next
doc) — DKMS built the kernel module fine, but the kernel refused to load it:

```
modprobe: ERROR: could not insert 'nvidia': Key was rejected by service
```

DKMS-built out-of-tree modules aren't signed with a key the kernel trusts
under Secure Boot unless you enroll a MOK (Machine Owner Key) — which
normally happens via an interactive blue "Enroll MOK" screen at boot,
requiring a password set at build time. Since the driver was installed
headlessly over SSH, that interactive enrollment never happened.

Fix: switched the VM to the non-Secure-Boot OVMF variant. This is a dedicated
internal GPU-compute VM with no need for Secure Boot's integrity guarantees,
so disabling it outright was the pragmatic call rather than wiring up MOK
enrollment.

```
virsh destroy gtx1060-inference          # or clean shutdown first
sudo rm -f /var/lib/libvirt/qemu/nvram/gtx1060-inference_VARS.fd
# edit domain XML: loader -> /usr/share/OVMF/OVMF_CODE_4M.fd, secure='no'
#                  nvram template -> /usr/share/OVMF/OVMF_VARS_4M.fd
virsh define <edited-xml>
virsh start gtx1060-inference
```

The old NVRAM file has to be deleted (or it'll retain Secure-Boot-enrolled
key state) so it regenerates cleanly from the new non-secure template.

Full resulting XML: [`configs/vm/gtx1060-inference-domain.xml`](../configs/vm/gtx1060-inference-domain.xml).
