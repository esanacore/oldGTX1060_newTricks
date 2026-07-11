#!/usr/bin/env bash
set -uo pipefail

# End-to-end functional check of the passthrough stack: SSHes into the art
# VM and confirms the GTX 1060 is visible to the driver AND reachable from
# inside a Docker container via nvidia-container-toolkit. This is the
# closest thing this repository has to an automated test — see
# docs/TEST_PLAN.md for why it isn't wired into CI (it requires live LAN
# access to a specific physical host, which a hosted runner never has).
#
# Exit status:
#   0  driver detects the GPU and the container run succeeded
#   1  either check failed
#   2  couldn't reach the guest at all (not treated as a hard failure by
#      itself — see docs/TEST_PLAN.md's "Full suite" declaration)

usage() {
  cat <<'USAGE'
Usage:
  verify-gpu-stack.sh [guest-host] [ssh-user]

Description:
  SSH into the art VM and confirm nvidia-smi sees the GTX 1060, then run a
  test CUDA container via `docker run --gpus all`.

Arguments:
  guest-host   Hostname or IP of the art VM. Default: art (falls back to
               192.168.122.27 if that name doesn't resolve).
  ssh-user     SSH user. Default: esanacore.
USAGE
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac

guest=${1:-art}
user=${2:-esanacore}
image="nvidia/cuda:12.6.0-base-ubuntu24.04"

ssh_opts=(-o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=accept-new)

reach() { ssh "${ssh_opts[@]}" "$user@$1" "echo ok" >/dev/null 2>&1; }

if ! reach "$guest"; then
  echo "Could not reach $user@$guest over SSH; trying 192.168.122.27 fallback..."
  guest=192.168.122.27
  if ! reach "$guest"; then
    echo "Could not reach the art VM at all (tried the given host and 192.168.122.27)."
    echo "Is it running? Check: virsh domstate gtx1060-inference"
    exit 2
  fi
fi

echo "== nvidia-smi on $guest =="
if ! ssh "${ssh_opts[@]}" "$user@$guest" "nvidia-smi --query-gpu=name,driver_version --format=csv,noheader"; then
  echo "FAIL: nvidia-smi did not report a GPU."
  exit 1
fi

echo
echo "== docker run --gpus all (image: $image) on $guest =="
if ! ssh "${ssh_opts[@]}" "$user@$guest" \
    "sudo docker run --rm --gpus all $image nvidia-smi --query-gpu=name --format=csv,noheader"; then
  echo "FAIL: GPU container run did not succeed."
  exit 1
fi

echo
echo "PASS: driver detects the GPU and the container run succeeded."
exit 0
