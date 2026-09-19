#!/usr/bin/env bash
# Idempotent toolchain install for the Docker-Local-Setup repo.
#
# The repo ships Windows-targeted PowerShell installers that generate and run
# local Docker Compose stacks. To run and verify them inside a Linux Cloud Agent
# we need: PowerShell 7 (pwsh), Docker Engine + Compose v2, fuse-overlayfs (the
# storage driver that works in the nested VM), and the .NET SDK (used by the
# SonarCube scan path). This script installs each only when missing so it stays
# fast on snapshot-backed boots.
set -euo pipefail

POWERSHELL_VERSION="7.4.6"
DOTNET_CHANNEL="8.0"

log() { printf '\n=== %s ===\n' "$*"; }

log "apt packages (docker, compose v2, fuse-overlayfs, tooling)"
sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
  ca-certificates curl wget apt-transport-https \
  docker.io docker-compose-v2 fuse-overlayfs fuse3 uidmap iptables
# fuse3 ships an interactive conffile prompt; finish any pending config quietly.
sudo DEBIAN_FRONTEND=noninteractive dpkg --configure -a --force-confold

log "PowerShell ${POWERSHELL_VERSION}"
if ! command -v pwsh >/dev/null 2>&1; then
  tmp_deb="$(mktemp --suffix=.deb)"
  wget -q "https://github.com/PowerShell/PowerShell/releases/download/v${POWERSHELL_VERSION}/powershell_${POWERSHELL_VERSION}-1.deb_amd64.deb" -O "$tmp_deb"
  sudo DEBIAN_FRONTEND=noninteractive dpkg -i "$tmp_deb" || sudo DEBIAN_FRONTEND=noninteractive apt-get install -f -y -qq
  rm -f "$tmp_deb"
fi
pwsh --version

log ".NET SDK ${DOTNET_CHANNEL} (dotnet-sonarscanner dependency)"
if ! command -v dotnet >/dev/null 2>&1; then
  tmp_dotnet="$(mktemp)"
  wget -q https://dot.net/v1/dotnet-install.sh -O "$tmp_dotnet"
  chmod +x "$tmp_dotnet"
  sudo "$tmp_dotnet" --channel "$DOTNET_CHANNEL" --install-dir /usr/share/dotnet
  sudo ln -sf /usr/share/dotnet/dotnet /usr/bin/dotnet
  rm -f "$tmp_dotnet"
fi
dotnet --version

log "Docker daemon config (fuse-overlayfs storage driver)"
sudo mkdir -p /etc/docker
echo '{"storage-driver":"fuse-overlayfs"}' | sudo tee /etc/docker/daemon.json >/dev/null

log "Docker group membership for $(whoami)"
sudo groupadd -f docker
sudo usermod -aG docker "$(whoami)"

log "Install-root folder beside the repo (installers' default INSTALL_ROOT_FOLDER)"
# The checked-in configs set INSTALL_ROOT_FOLDER to ..\Docker-Local-Setup--Installs,
# which resolves to a sibling of the repo checkout. On Linux that parent dir is
# not user-writable by default, so pre-create the install root owned by the user.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_PARENT="$(dirname "$REPO_ROOT")"
INSTALL_ROOT="${REPO_PARENT%/}/Docker-Local-Setup--Installs"
sudo mkdir -p "$INSTALL_ROOT"
sudo chown "$(id -u):$(id -g)" "$INSTALL_ROOT"
echo "Install root ready: $INSTALL_ROOT"

log "install.sh complete"
