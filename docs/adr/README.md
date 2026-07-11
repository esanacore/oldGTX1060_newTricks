# Architecture Decision Records

Index of ADRs for this repository, per `constitution/DOCUMENTATION.md`'s
"Architecture Decision Records" section. Newest-numbered last.

| ADR | Status | Decision |
| --- | --- | --- |
| [0001](0001-vfio-passthrough-vm-over-driver-downgrade.md) | Accepted | Pass the GTX 1060 through via VFIO to a dedicated VM, rather than downgrading the host's NVIDIA driver or running Docker directly on the host. |
| [0002](0002-disable-secure-boot-in-guest.md) | Accepted | Disable Secure Boot in the `art` VM's firmware rather than enrolling a MOK for the DKMS-built NVIDIA module. |

## Status Lifecycle

`Proposed → Accepted → Superseded` (or `Deprecated`). See
`constitution/DOCUMENTATION.md` for the full definitions and the
`Relationships`/`Promotion Criteria` fields each ADR carries.
