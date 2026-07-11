#!/usr/bin/env bash
set -uo pipefail

# Compares the art VM's live (persistent) libvirt domain definition against
# the checked-in reference copy at configs/vm/gtx1060-inference-domain.xml.
# Catches drift from ad-hoc `virsh edit`/`virt-xml` changes that were never
# reflected back into the repo. Read-only — does not modify the domain.
#
# Requires: virsh, with permission to read the domain (run as the user in
# the libvirt group, or with sudo).
#
# Exit status:
#   0  live definition matches the reference copy
#   1  they differ, or the domain/virsh is unavailable

usage() {
  cat <<'USAGE'
Usage:
  check-vm-config.sh [repo-root] [domain-name]

Description:
  Diff `virsh dumpxml --inactive <domain>` against
  configs/vm/gtx1060-inference-domain.xml.

Arguments:
  repo-root     Path to this repository's root. Default: auto-detected.
  domain-name   libvirt domain name. Default: gtx1060-inference.
USAGE
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=${1:-"$(CDPATH= cd -- "$script_dir/.." && pwd)"}
domain=${2:-gtx1060-inference}
reference="$repo_root/configs/vm/gtx1060-inference-domain.xml"

if ! command -v virsh >/dev/null 2>&1; then
  echo "virsh not found on this machine — this check only runs on the libvirt host."
  exit 1
fi

if [ ! -f "$reference" ]; then
  echo "No reference XML at $reference"
  exit 1
fi

live=$(mktemp)
trap 'rm -f "$live"' EXIT

if ! virsh dumpxml --inactive "$domain" > "$live" 2>/dev/null; then
  echo "Could not dump domain '$domain' — is it defined? Do you have libvirt access?"
  exit 1
fi

echo "VM config drift check: live '$domain' definition vs $reference"
echo

if diff -u "$reference" "$live"; then
  echo "OK — live domain definition matches the reference copy."
  exit 0
fi

echo
echo "DRIFT — live domain definition differs from the reference copy above."
echo "If the live config is now the correct one, update:"
echo "  $reference"
exit 1
