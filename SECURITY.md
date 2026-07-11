# Project Security

This project follows [Eric's Engineering Constitution Security Standards](constitution/SECURITY.md).

## Local Security Concerns

- **LAN Exposure**: the `art` VM is reachable via SSH on libvirt's `default`
  NAT network (`192.168.122.0/24`) — LAN-local only, not exposed to the
  internet. Docker's daemon socket and the containers it runs are only
  reachable from inside the guest itself, not published to the host or LAN.
- **Credential Handling**: no secrets are committed to this repository.
  Guest SSH access uses key-based auth (the host's existing SSH key,
  already registered on GitHub) — no passwords or tokens anywhere in this
  repo. Passwordless sudo is configured in the guest
  (`/etc/sudoers.d/90-esanacore-nopasswd`) to support non-interactive SSH
  automation; see `docs/ARCHITECTURE.md`'s "Security-Sensitive Areas".
- **Sensitive Data**: none handled by this repository. It's infrastructure
  configuration and documentation, not an application processing user data.

## Known Accepted Risks

- **Secure Boot disabled in the guest** — deliberate tradeoff for a
  single-purpose, internal-only VM. See
  `docs/adr/0002-disable-secure-boot-in-guest.md`.
- **Raw block device passthrough** (`/dev/sdc`) — the host can technically
  still touch this device while the VM holds it exclusively; see the
  caution in `docs/03-vm-provisioning.md`. Data-integrity risk, not a
  confidentiality one.

## Security Checklist

- [x] Credentials are stored in environment variables, not code. (N/A — no
      credentials exist in this repo; access is key-based.)
- [ ] Dependencies are audited for vulnerabilities. (Guest driver/Docker/
      toolkit packages come from upstream apt repos, pinned to whatever
      version was current at install time — not tracked for CVEs here. See
      `TODO.md`.)
- [x] Inputs are validated at boundaries. (N/A — no user-facing input
      surface; this is infrastructure config, not an application.)
- [x] Logs do not contain secrets or PII.
- [x] A threat model was produced if the change hit any trigger in the
      constitution's [Threat Modeling Triggers](constitution/SECURITY.md).
      (Secure Boot removal and passwordless sudo were evaluated explicitly —
      see `docs/adr/0002-disable-secure-boot-in-guest.md` and
      `docs/ARCHITECTURE.md`'s "Security-Sensitive Areas" — neither hits the
      new-egress-path or new-auth-surface triggers since both are
      LAN-local, single-operator changes.)
