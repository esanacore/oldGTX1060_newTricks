# Guest setup: NVIDIA driver, Docker, nvidia-container-toolkit

All done over SSH into the `art` VM (`192.168.122.27`, DHCP via libvirt's
`default` network). Passwordless sudo was configured once
(`/etc/sudoers.d/90-esanacore-nopasswd`, via virt-manager's console since
SSH-over-non-TTY can't prompt for a sudo password) to allow non-interactive
automation.

## 1. NVIDIA driver — Legacy branch (580.xx)

```
sudo apt update
sudo apt install -y nvidia-driver-580
sudo reboot
```

This is the Legacy branch — required because the GTX 1060 is Pascal, which
current NVIDIA branches (595.x+) no longer support. See
[`01-diagnosis.md`](01-diagnosis.md).

Installed cleanly (580.159.03), `dkms status` showed the module built for
both kernels present in the guest — but the kernel refused to load it after
reboot until Secure Boot was disabled on the VM. See the Secure Boot section
of [`03-vm-provisioning.md`](03-vm-provisioning.md) for that fix. After that:

```
$ nvidia-smi
NVIDIA-SMI 580.159.03   Driver Version: 580.159.03   CUDA Version: 13.0
GPU 0: NVIDIA GeForce GTX 1060 6GB
```

## 2. Docker CE (apt — deliberately not the snap package)

The snap-packaged Docker has confinement restrictions that interfere with
GPU device access via `nvidia-container-toolkit`. Installed the upstream
apt repo instead, matching how Docker is set up on the host:

```
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
  https://download.docker.com/linux/ubuntu jammy stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker "$USER"   # takes effect on next login/SSH session
```

Note: `jammy` (22.04) is used as the repo codename even though the guest
runs a newer Ubuntu release — Docker's apt packages are built to be
compatible across Ubuntu versions and this is a common/safe fallback when a
brand-new release codename isn't in Docker's repo yet.

## 3. nvidia-container-toolkit

```
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
  sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt update
sudo apt install -y nvidia-container-toolkit

sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

## 4. Verification

```
sudo docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu24.04 nvidia-smi
```

Output confirmed the container saw the GTX 1060 directly (driver
580.159.03, CUDA 13.0 reported inside the container) — full stack working
end to end.

## What this enables

Any GPU-aware container can now be run against the 1060 from inside the
`art` VM, e.g.:

```
docker run --rm --gpus all -v ollama:/root/.ollama -p 11434:11434 ollama/ollama
```

completely isolated from the host's RTX 4080 and its 595.x driver.
