# claude-openwebui-wsl-stack

**Repo Description:** Production-style WSL2 + Docker Compose stack for running Open WebUI in Ubuntu (WSL) against Ollama on Windows, with Claude CLI routed through Open WebUI’s Anthropic-compatible API.

## Architecture

```text
+----------------------------- Windows Host ------------------------------+
|                                                                         |
|  Ollama (GPU, native)                                                   |
|  listens on <OLLAMA_PORT> (default 11434)                              |
|                                                                         |
+------------------------------^------------------------------------------+
                               |
                     http://host.docker.internal:<OLLAMA_PORT>
                               |
+------------------------------v------------------------------------------+
|                        WSL2 Ubuntu + Docker                            |
|                                                                         |
|  Open WebUI container (port <OPENWEBUI_PORT>, default 9090)            |
|  - WEBUI_AUTH=true                                                      |
|  - API endpoint: http://localhost:<OPENWEBUI_PORT>/api                 |
|                                                                         |
|  Claude CLI (WSL shell)                                                 |
|  - launched via scripts/claude-owui                                     |
|  - model selected dynamically from Open WebUI                           |
+-------------------------------------------------------------------------+
```

### Request Flow
1. `claude-owui` asks Open WebUI for available models.
2. You choose a model from an interactive menu.
3. Script launches `claude --model <selected_model>`.
4. Claude CLI calls Open WebUI API at `http://localhost:<OPENWEBUI_PORT>/api`.
5. Open WebUI forwards model calls to Ollama on Windows via `host.docker.internal`.

## Quickstart

```bash
# 1) Clone and enter repo
git clone <YOUR_REPO_URL>
cd claude-openwebui-wsl-stack

# 2) Install WSL-side dependencies
chmod +x scripts/install-wsl.sh scripts/claude-owui
./scripts/install-wsl.sh

# 3) Start Open WebUI
cp .env.example .env
docker compose up -d

# 4) Open WebUI UI
# http://localhost:9090

# 5) Add script to PATH (optional)
mkdir -p ~/.local/bin
cp scripts/claude-owui ~/.local/bin/claude-owui
chmod +x ~/.local/bin/claude-owui

# 6) Set API key from Open WebUI token
export OPENWEBUI_API_KEY='paste-your-openwebui-token-here'

# 7) Launch Claude through Open WebUI
claude-owui
```

---

## Step-by-Step Install

### 1) Install WSL2 (Windows)

Run in PowerShell (Admin):

```powershell
wsl --install
```

Then install Ubuntu from Microsoft Store (or `wsl --install -d Ubuntu`) and complete first-run user setup.

### 2) Install Docker + tools in WSL

From Ubuntu (WSL):

```bash
cd <REPO_PATH>
chmod +x scripts/install-wsl.sh
./scripts/install-wsl.sh
```

Log out/in (or restart WSL) after docker-group changes:

```bash
wsl.exe --shutdown
```

### 3) Install Ollama on Windows host

Install Ollama natively on Windows and ensure it runs at startup.

Set Ollama host binding so WSL containers can access it (PowerShell example):

```powershell
setx OLLAMA_HOST "0.0.0.0:<OLLAMA_PORT>"
```

Then restart Ollama and verify:

```powershell
curl http://localhost:<OLLAMA_PORT>/api/tags
```

### 4) Start Open WebUI in WSL via Docker Compose

From repo root in WSL:

```bash
cp .env.example .env
docker compose up -d
docker compose logs -f open-webui
```

Open WebUI: `http://localhost:<OPENWEBUI_PORT>` (default `9090`).

### 5) Connect Open WebUI to Ollama (`host.docker.internal`)

In Open WebUI Admin Settings, configure Ollama backend URL as:

```text
http://host.docker.internal:11434
```

Test model listing from WSL:

```bash
curl -s http://localhost:9090/api/models | jq .
```

### 6) Retrieve Open WebUI token and export API key

1. Sign in to Open WebUI.
2. Open browser DevTools → Application/Storage → Local Storage.
3. Copy auth token/JWT used by Open WebUI session.
4. In WSL, export it:

```bash
export OPENWEBUI_API_KEY='paste-your-openwebui-token-here'
```

Persist in shell profile if desired:

```bash
echo "export OPENWEBUI_API_KEY='paste-your-openwebui-token-here'" >> ~/.bashrc
```

### Required Environment Variables for `claude-owui`

Set these in your WSL shell before running `claude-owui`:

```bash
export OPENWEBUI_API_KEY='paste-your-openwebui-token-here'
# Optional if Open WebUI is not on localhost:9090
export OPENWEBUI_BASE_URL='http://localhost:9090'
```

- `OPENWEBUI_API_KEY` (required): your Open WebUI bearer token/session token.
- `OPENWEBUI_BASE_URL` (optional): defaults to `http://localhost:9090`.

### 7) Use dynamic model launcher (`claude-owui`)

```bash
chmod +x scripts/claude-owui
./scripts/claude-owui "your prompt here"
```

or from PATH:

```bash
claude-owui "summarize this repo"
```

Script behavior:
- Reads `OPENWEBUI_API_KEY` (required) and `OPENWEBUI_BASE_URL` (optional).
- Calls `${OPENWEBUI_BASE_URL}/api/models` (default `http://localhost:9090/api/models`).
- Shows interactive model menu from `.data[].id`.
- Runs `claude --model "$model"` with per-invocation env:
  - `ANTHROPIC_BASE_URL=${OPENWEBUI_BASE_URL}/api`
  - `ANTHROPIC_AUTH_TOKEN=$OPENWEBUI_API_KEY`
  - `ANTHROPIC_API_KEY=""`

---

## Troubleshooting

## Common Issues

### `host.docker.internal` not resolving
- Ensure `extra_hosts` is present in `docker-compose.yml`.
- Restart container:

```bash
docker compose down
docker compose up -d
```

### Ports already in use
- Check listeners:

```bash
ss -ltnp | rg ':9090|:11434'
```

- Change `<OPENWEBUI_PORT>` mapping in `docker-compose.yml` if needed.

### Token invalid/expired
- Re-login to Open WebUI and copy a fresh token.
- Re-export:

```bash
export OPENWEBUI_API_KEY='paste-your-openwebui-token-here'
```

### Docker permission denied
- User likely not in docker group:

```bash
sudo usermod -aG docker "$USER"
wsl.exe --shutdown
```

Then start WSL again.

### Docker service not running in WSL

```bash
sudo service docker start
sudo service docker status
```

---


## User Checklist (Documented Manual Steps)

Use this as your completion checklist after cloning:

- [ ] Install Ollama on Windows and confirm it runs at startup.
- [ ] Set and verify Ollama host binding (`OLLAMA_HOST=0.0.0.0:<OLLAMA_PORT>`).
- [ ] In WSL, run `./scripts/install-wsl.sh` and restart WSL (`wsl.exe --shutdown`).
- [ ] Start Open WebUI in WSL (`docker compose up -d`) from your `~/openwebui` workspace.
- [ ] Sign in to Open WebUI and configure Ollama backend URL to `http://host.docker.internal:11434`.
- [ ] Create/confirm Open WebUI admin account with strong password.
- [ ] Retrieve Open WebUI token and export `OPENWEBUI_API_KEY` in WSL.
- [ ] Run `claude-owui` and verify model selection + inference works.
- [ ] Configure Windows Firewall rules for Private profile only (no public exposure for `11434`/`9090`).
- [ ] Configure Windows boot autostart (Task Scheduler recommended).

---

## Production Guidance

See [docs/production-hardening.md](docs/production-hardening.md) for network, auth, proxy/TLS, updates, backup, and monitoring recommendations.

## Windows Boot Autostart

See [scripts/windows-autostart.md](scripts/windows-autostart.md) for Task Scheduler and Startup-folder methods.
