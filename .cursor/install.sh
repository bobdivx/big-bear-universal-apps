#!/usr/bin/env bash
# Idempotent Cloud Agent setup for big-bear-universal-apps.
# Installs the toolchain the conversion/validation scripts and Bun tooling need,
# then refreshes JavaScript dependencies from the committed lockfile.
set -euo pipefail

BUN_INSTALL_DIR="/usr/local/bun"

log() { printf '\n=== %s ===\n' "$1"; }

log "System packages (jq, imagemagick, rsync)"
# jq: JSON processing in the converter/validator.
# imagemagick: logo conversion in convert-to-platforms.sh (ffmpeg is a fallback).
# rsync: used by sync-to-platforms.sh.
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq jq imagemagick rsync

log "mikefarah yq"
# The scripts rely on mikefarah's Go yq ("yq eval ..."), not the Python yq that
# ships in the base image. Install it ahead of /usr/bin on PATH.
if ! yq --version 2>/dev/null | grep -q 'mikefarah'; then
  sudo wget -q https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq
  sudo chmod +x /usr/local/bin/yq
fi

log "Bun"
if [ ! -x "${BUN_INSTALL_DIR}/bin/bun" ]; then
  sudo mkdir -p "${BUN_INSTALL_DIR}"
  sudo chown -R "$(id -u):$(id -g)" "${BUN_INSTALL_DIR}"
  curl -fsSL https://bun.sh/install | BUN_INSTALL="${BUN_INSTALL_DIR}" bash
fi
sudo ln -sf "${BUN_INSTALL_DIR}/bin/bun" /usr/local/bin/bun
sudo ln -sf "${BUN_INSTALL_DIR}/bin/bunx" /usr/local/bin/bunx

log "JavaScript dependencies"
cd "$(dirname "$0")/.."
bun install --frozen-lockfile

log "Toolchain versions"
yq --version
bun --version
jq --version
