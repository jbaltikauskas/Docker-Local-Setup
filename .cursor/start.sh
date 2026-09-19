#!/usr/bin/env bash
# Idempotent per-boot startup for the Docker-Local-Setup repo.
#
# The Cloud Agent VM has no systemd, so the Docker daemon must be started by
# hand on every boot. This script starts dockerd (if it is not already
# responding), waits for the socket, and relaxes the socket permissions so the
# repo's PowerShell installers can call `docker` without sudo.
set -euo pipefail

DOCKERD_LOG="/tmp/dockerd.log"

if sudo docker info >/dev/null 2>&1; then
  echo "Docker daemon already running."
else
  echo "Starting dockerd (logging to ${DOCKERD_LOG}) ..."
  # Remove any stale log so the fresh root-owned daemon can always write it.
  sudo rm -f "${DOCKERD_LOG}"
  sudo bash -c "nohup dockerd >'${DOCKERD_LOG}' 2>&1 &"

  for i in $(seq 1 30); do
    if sudo docker info >/dev/null 2>&1; then
      echo "Docker daemon ready after ${i}s."
      break
    fi
    if [ "$i" -eq 30 ]; then
      echo "Docker daemon did not become ready in time; see ${DOCKERD_LOG}" >&2
      tail -n 40 "${DOCKERD_LOG}" >&2 || true
      exit 1
    fi
    sleep 1
  done
fi

# Allow non-root `docker` usage (group membership needs a fresh login otherwise).
if [ -S /var/run/docker.sock ]; then
  sudo chmod 666 /var/run/docker.sock || true
fi

docker version --format 'Docker client {{.Client.Version}} / server {{.Server.Version}}' || true
docker compose version --short || true
echo "start.sh complete"
