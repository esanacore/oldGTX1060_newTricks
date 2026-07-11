# Test Plan

This is a documentation/configuration repository (no application code), so
there is no automated test suite in the usual sense. Correctness is verified
against the live host + VM system this repo documents, per the checks below.

## Test Strategy

Not applicable in the unit/integration/e2e sense — there's no code to unit
test. The equivalent verification is:

- **Config accuracy**: files under `configs/` should match what's actually
  deployed on the host and in the `art` VM's domain definition. Check with
  `virsh dumpxml --inactive gtx1060-inference` and diff against
  `configs/vm/gtx1060-inference-domain.xml`.
- **End-to-end functional check**: the GPU passthrough + container stack
  actually works. See `docs/COMMAND_REFERENCE.md`, "Docker + GPU
  Verification."

## How to Run Tests

- Full suite: `echo "No automated test suite: documentation/config repository. See docs/COMMAND_REFERENCE.md for manual verification commands."`
- With coverage: N/A
- A single test or subset: N/A

## Coverage Targets

N/A — no code, no coverage metric applies.

## Continuous Coverage Evaluation

N/A.

## Coverage Gap Log

| Gap ID | Area / behavior | Risk | Related requirement | Status | TODO ref |
| --- | --- | --- | --- | --- | --- |
| GAP-001 | No automated regression check that the GPU passthrough stack still works after a host kernel/driver upgrade | med | n/a | Open | `TODO.md`, Testing |

## Requirement Coverage

N/A — this repository has no `docs/PRODUCT_REQUIREMENTS.md` /
`docs/REQUIREMENTS_TRACEABILITY.md`; it documents infrastructure, not a
product with functional requirements.
