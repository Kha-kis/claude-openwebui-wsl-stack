# Hardened Production Guide

This guide assumes:
- Ollama runs natively on Windows.
- Open WebUI runs in WSL2 via Docker Compose.
- Claude CLI in WSL talks only to Open WebUI API.

## 1) Network Exposure Principles
- Do **not** expose Ollama (`11434`) or Open WebUI (`9090`) publicly.
- Prefer localhost bindings and trusted private networks only.
- Use reverse proxy + TLS if remote access is required.

## 2) Windows Firewall (Private Profile)
- Create inbound allow rules for required ports on **Private** profile only.
- Avoid enabling on Public profile.
- Optionally restrict allowed remote source ranges (trusted subnets/devices).

## 3) Open WebUI Authentication
- Keep `WEBUI_AUTH=true`.
- Use a strong admin password and least-privileged accounts.
- Rotate API/session tokens regularly.
- Revoke tokens immediately after suspected leak.

## 4) Optional Reverse Proxy (Caddy/Nginx)
Use a reverse proxy in front of Open WebUI for:
- TLS termination (HTTPS).
- Basic auth or OIDC/SSO.
- Rate limiting and request size limits.
- Access logs and centralized controls.

Minimum controls:
- Enforce HTTPS.
- Restrict methods/paths where practical.
- Add per-IP rate limiting.

## 5) Secrets Handling
- Keep secrets in `.env` (never commit it).
- Set restrictive permissions:

```bash
chmod 600 .env
```

- Add secret patterns and runtime data to `.gitignore`.
- Avoid embedding tokens in shell history or screenshots.

## 6) Updates & Rollback
- Prefer pinned container image tags for predictable upgrades.
- Track Open WebUI/Ollama release notes.
- Use scheduled maintenance windows for updates.
- Keep a rollback plan:
  1. Backup data volume.
  2. Stop stack.
  3. Revert image tag.
  4. Restart and validate health.

## 7) Backups & Restore
Open WebUI data is persisted under `./data`.

### Backup
```bash
tar -czf openwebui-data-$(date +%F).tar.gz data/
```

### Restore
```bash
docker compose down
rm -rf data/
tar -xzf openwebui-data-<DATE>.tar.gz
docker compose up -d
```

Also periodically export Open WebUI settings/admin config from UI when possible.

## 8) Logs & Monitoring
- Container logs:

```bash
docker compose logs -f open-webui
```

- Docker daemon logs (WSL distro dependent):

```bash
journalctl -u docker --no-pager -n 200
```

- Basic health checks:

```bash
curl -f http://localhost:9090/ || echo "Open WebUI health check failed"
curl -f http://host.docker.internal:11434/api/tags || echo "Ollama health check failed"
```

## 9) WSL2-Specific Considerations
- Set sensible WSL CPU/memory limits via `%UserProfile%\\.wslconfig` on Windows.
- Expect networking changes after reboot; verify `host.docker.internal` connectivity.
- Ensure Docker service starts in WSL before Compose (`sudo service docker start` or equivalent).
- Validate startup automation after Windows updates.
