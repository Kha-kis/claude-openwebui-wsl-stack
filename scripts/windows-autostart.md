# Windows Boot Autostart Guide

This guide starts Ollama (Windows host) and Open WebUI (WSL Docker Compose) at boot.

## Method A: Task Scheduler (Recommended)

### Why this method
- Can run whether a user is logged in or not.
- Better reliability after reboot.
- Supports startup trigger and retries.

### A1) Ensure Ollama starts on boot
Pick one:
1. If Ollama is installed as a Windows service, set startup type to **Automatic**.
2. If Ollama uses a desktop app/executable, create a Task Scheduler action to run it at startup.

### A2) Create startup task for WSL + Compose
1. Open **Task Scheduler** → **Create Task**.
2. **General**:
   - Name: `OpenWebUI-WSL-Autostart`
   - Run whether user is logged on or not
   - Run with highest privileges (optional)
3. **Triggers**:
   - New → Begin the task: **At startup**
4. **Actions**:
   - New Action 1 (optional if needed): start Ollama executable/service helper.
   - New Action 2:
     - Program/script: `wsl.exe`
     - Add arguments:
       ```text
       -d Ubuntu -- bash -lc "cd ~/openwebui && docker compose up -d"
       ```
     - Start in (optional):
       ```text
       C:\Windows\System32
       ```
5. **Conditions/Settings**:
   - Configure retries on failure (recommended).

## Method B: Startup Folder (Simpler, Less Reliable)

1. Create `start-openwebui.bat`:

```bat
@echo off
wsl.exe -d Ubuntu -- bash -lc "cd ~/openwebui && docker compose up -d"
```

2. Press `Win + R`, run:

```text
shell:startup
```

3. Place `start-openwebui.bat` in that folder.

> This method only runs after user login and is less reliable than Task Scheduler.

## Verify on Boot Checklist

After restart, verify:
1. Ollama reachable on host:

```powershell
curl http://localhost:11434/api/tags
```

2. WSL stack running:

```bash
wsl -d Ubuntu -- bash -lc "docker ps --format 'table {{.Names}}\t{{.Status}}'"
```

3. Open WebUI reachable:
- Browse `http://localhost:9090`

4. Model API works from WSL:

```bash
curl -s http://localhost:9090/api/models | jq .
```
