#!/usr/bin/env bash
set -euo pipefail

echo "[1/5] Installing Docker, Compose plugin, and jq..."
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-plugin jq

echo "[2/5] Enabling Docker service..."
sudo service docker start >/dev/null 2>&1 || true

echo "[3/5] Adding $USER to docker group..."
sudo usermod -aG docker "$USER"

echo "[4/5] Preparing ~/openwebui workspace..."
mkdir -p "$HOME/openwebui"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cp "$REPO_ROOT/docker-compose.yml" "$HOME/openwebui/docker-compose.yml"
cp "$REPO_ROOT/.env.example" "$HOME/openwebui/.env.example"

echo "[5/5] Done."
cat <<'NEXT'

Next steps:
  1) Restart WSL session to apply docker group membership:
       wsl.exe --shutdown
  2) In WSL, start stack:
       cd ~/openwebui
       cp .env.example .env
       docker compose up -d
  3) Open Open WebUI:
       http://localhost:9090
  4) Set required env vars and run claude-owui:
       export OPENWEBUI_API_KEY='paste-your-openwebui-token-here'
       # optional: export OPENWEBUI_BASE_URL='http://localhost:9090'
       claude-owui

Notes:
  - This script does not perform privileged Windows host operations.
  - Install/configure Ollama on Windows separately.
NEXT
