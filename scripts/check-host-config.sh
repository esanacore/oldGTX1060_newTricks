#!/usr/bin/env bash
set -uo pipefail

# Compares the host's live VFIO/GPU-passthrough configuration files against
# the checked-in reference copies under configs/host/, so config drift is
# something you can *check* rather than something you assume hasn't
# happened. Read-only — no sudo required, no host state is modified.
#
# Intended to be run on the Murderbot host itself (the files it reads are
# host-local paths), not in CI.
#
# Exit status:
#   0  every checked file matches its reference copy
#   1  at least one file drifted or is missing on the host

usage() {
  cat <<'USAGE'
Usage:
  check-host-config.sh [repo-root]

Description:
  Diff the host's live config files against configs/host/ in this
  repository. Reports OK/DRIFT/MISSING per file.

Arguments:
  repo-root   Path to this repository's root. Default: directory containing
              this script's parent (i.e. auto-detected from $0).
USAGE
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=${1:-"$(CDPATH= cd -- "$script_dir/.." && pwd)"}

drift=0
checked=0

check_file() {
  local live=$1 reference=$2 label=$3

  if [ ! -f "$reference" ]; then
    echo "  SKIP     $label (no reference copy at $reference)"
    return
  fi
  checked=$((checked + 1))

  if [ ! -f "$live" ]; then
    echo "  MISSING  $label ($live not found on this host)"
    drift=$((drift + 1))
    return
  fi

  if diff -q "$reference" "$live" >/dev/null 2>&1; then
    echo "  OK       $label"
  else
    echo "  DRIFT    $label ($live differs from $reference)"
    drift=$((drift + 1))
  fi
}

check_line_present() {
  local live=$1 pattern=$2 label=$3

  checked=$((checked + 1))
  if [ ! -f "$live" ]; then
    echo "  MISSING  $label ($live not found on this host)"
    drift=$((drift + 1))
    return
  fi

  if grep -qF "$pattern" "$live" 2>/dev/null; then
    echo "  OK       $label"
  else
    echo "  DRIFT    $label ($pattern not found in $live)"
    drift=$((drift + 1))
  fi
}

echo "Host config drift check against: $repo_root/configs/host/"
echo

check_line_present /etc/default/grub \
  "intel_iommu=on iommu=pt" \
  "GRUB: IOMMU cmdline params present"

check_file /etc/modprobe.d/vfio-gtx1060.conf \
  "$repo_root/configs/host/modprobe.d/vfio-gtx1060.conf" \
  "modprobe.d: vfio-gtx1060.conf"

check_file /etc/modprobe.d/blacklist-nouveau-1060.conf \
  "$repo_root/configs/host/modprobe.d/blacklist-nouveau-1060.conf" \
  "modprobe.d: blacklist-nouveau-1060.conf"

check_line_present /etc/initramfs-tools/modules \
  "vfio-pci" \
  "initramfs-tools/modules: vfio-pci present"

check_line_present /etc/fstab \
  "UUID=6A7F-B8D3 /mnt/T9" \
  "fstab: T9 entry present"

check_file /etc/systemd/system/ollama.service \
  "$repo_root/configs/host/ollama.service" \
  "systemd: ollama.service"

echo
echo "Checked: $checked; drifted/missing: $drift."

if [ "$drift" -gt 0 ]; then
  exit 1
fi
exit 0
