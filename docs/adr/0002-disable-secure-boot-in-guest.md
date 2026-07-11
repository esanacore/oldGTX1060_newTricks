# ADR: Disable Secure Boot in the art VM instead of enrolling a MOK

Status: Accepted

Date: 2026-07-10

## Relationships

- Extends: [`0001-vfio-passthrough-vm-over-driver-downgrade.md`](0001-vfio-passthrough-vm-over-driver-downgrade.md)
- Supersedes: none
- Related: none

## Context

After installing `nvidia-driver-580` inside the `art` VM, DKMS built the
kernel module successfully, but the kernel refused to load it:

```
modprobe: ERROR: could not insert 'nvidia': Key was rejected by service
```

The VM's default UEFI firmware (`OVMF_CODE_4M.ms.fd`, `secure='yes'`) enrolls
Microsoft's Secure Boot keys. DKMS-built out-of-tree kernel modules aren't
signed with a key the kernel trusts under Secure Boot unless a Machine Owner
Key (MOK) is enrolled — normally an interactive step at boot (a blue "Enroll
MOK" screen, gated by a password set at build time). The driver here was
installed headlessly over SSH, so that interactive enrollment never
happened, and there was no console session available at the moment it would
have mattered.

This is a security-relevant infrastructure decision in its own right —
distinct from the VFIO-vs-driver-downgrade choice in ADR-0001 — because it
changes the guest's boot-integrity posture, so it gets its own record.

## Decision

Disable Secure Boot in the `art` VM by switching its firmware from the
Microsoft-signed OVMF variant to the plain, non-Secure-Boot variant:

```
loader:  /usr/share/OVMF/OVMF_CODE_4M.fd   (was: OVMF_CODE_4M.ms.fd, secure='no')
nvram:   /usr/share/OVMF/OVMF_VARS_4M.fd   (was: OVMF_VARS_4M.ms.fd)
```

The old NVRAM file was deleted so it regenerates cleanly from the new
non-Secure-Boot template (an NVRAM file generated under the Secure Boot
template retains enrolled-key state otherwise). Full procedure:
[`docs/03-vm-provisioning.md`](../03-vm-provisioning.md#secure-boot-had-to-be-disabled).

MOK enrollment (the alternative that keeps Secure Boot on) was not pursued.

## Consequences

**Positive:**

- Unblocked immediately, with a two-command fix (swap firmware, delete
  NVRAM) and no need for physical/console access to complete an interactive
  enrollment step.
- One less moving part: no MOK key/password to manage, no re-enrollment
  needed on future DKMS rebuilds (e.g. after a kernel upgrade).

**Negative:**

- The guest boots without kernel module signature verification. Any kernel
  module (malicious or accidentally loaded) can now load without a trust
  check.
- This is a real reduction in the guest's boot-integrity posture, accepted
  specifically because of this VM's threat model: a single-purpose internal
  GPU-compute box, not internet-facing, not handling untrusted input, with
  the same operator controlling both host and guest. This tradeoff should be
  revisited if that scope ever changes (see `TODO.md`).

## Alternatives Considered

1. **Enroll a MOK for the DKMS-built module, keep Secure Boot on.** The
   "correct" long-term answer, but requires an interactive console step
   (setting a MOK password at build time, then confirming enrollment at the
   next boot via the firmware's blue MOK Manager screen) that isn't
   practical to script over SSH, and would need to be repeated on every
   kernel upgrade that triggers a DKMS rebuild unless further automated.
   Left as a `TODO.md` item to revisit if this VM's purpose expands.
2. **Disable Secure Boot (chosen).** Immediate, scriptable, no recurring
   maintenance burden. Accepted given the VM's limited, internal-only threat
   model.
