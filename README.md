# 🛰️ Nova Tor Relay

- [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
- [![Docker Pulls](https://img.shields.io/docker/pulls/nullusionist/nova-tor-relay)](https://hub.docker.com/r/nullusionist/nova-tor-relay)
- [![Mirror: GitHub](https://img.shields.io/badge/mirror-github-blue?logo=github)](https://github.com/nullusionist/nova-tor-relay)
- [![Mirror: GitLab](https://img.shields.io/badge/mirror-gitlab-orange?logo=gitlab)](https://gitlab.com/nullusionist/nova-tor-relay)
- [![Mirror: Codeberg](https://img.shields.io/badge/mirror-codeberg-lightblue?logo=codeberg)](https://codeberg.org/nullusionist/nova-tor-relay)

Nova Tor Relay is a minimal, opinionated Docker image for running a secure Tor **relay** with simple configuration via environment variables or Compose.  
Image: **`nullusionist/nova-tor-relay`**

---

## 🚀 Quick Start (clean & ordered)

### 1) Create your `.env`
Copy the example and edit values to taste.
```bash
cp .env.example .env
# then edit .env
```

Typical keys in `.env`:
```env
CONTACT=you@example.com
BANDWIDTH_LIMIT=100 KB
BANDWIDTH_BURST=200 KB
# NICKNAME=MyRelay
# EXIT_RELAY=0
# EXIT_POLICY=accept 80,443
# ACCOUNTING_START=day 1 00:00
# ACCOUNTING_MAX=5 GB
# TOR_EXTRA_LINES=Log notice stdout\nMyFamily ABC123,DEF456
```

> **Ports:** expose **9001/tcp** (ORPort) and optionally **9030/tcp** (DirPort).  
> **State:** persist `/var/lib/tor` to keep your relay identity across restarts.

---

### 2A) Start with **Compose** (recommended)
Compose auto-loads `.env` from the project directory.
```bash
docker compose up -d
```

### 2B) Or start with the **Docker CLI** (one‑liner + overrides)
Load baseline values from `.env` and optionally override inline:
```bash
docker run -d --name nova-tor-relay   --env-file .env   -e CONTACT="you@example.com"   -e BANDWIDTH_LIMIT="100 KB"   -e BANDWIDTH_BURST="200 KB"   -p 9001:9001   -p 9030:9030   -v nova-tor-data:/var/lib/tor   nullusionist/nova-tor-relay:latest
```

**Verify it’s up:**
```bash
docker logs -f --tail 200 nova-tor-relay
# When bootstrapped, the relay will appear on:
# https://metrics.torproject.org/rs.html#search/
```

---

## ⚙️ Configuration

All settings are driven by environment variables (see `.env.example`).

**Volumes**
- `/var/lib/tor` — persist identity/keys

**Ports**
- `9001/tcp` — ORPort
- `9030/tcp` — DirPort (optional)
- `9051/tcp` — ControlPort (optional; typically disabled)

---

## 🧭 Tags & Manifests (Multi‑Arch)

This project publishes **multi‑arch** images for `linux/amd64` and `linux/arm64`.

**Tags**
- `latest` → current release (**multi‑arch manifest**)
- `X.Y.Z` → pinned Tor version (multi‑arch), e.g. `0.4.8.17`
- `X.Y.Z-<codename>` → Tor version + Debian codename (multi‑arch), e.g. `0.4.8.17-trixie`
- `latest-amd64`, `latest-arm64` → arch‑specific images (feed the multi‑arch `latest`)
- `X.Y.Z-amd64`, `X.Y.Z-arm64` and `X.Y.Z-<codename>-amd64`, `…-arm64` → arch‑specific pins

**Examples**
```bash
# Most users (auto-selects arch)
docker pull nullusionist/nova-tor-relay:latest

# Pin to a Tor version (multi-arch)
docker pull nullusionist/nova-tor-relay:0.4.8.17

# Pin to Tor version + Debian codename (multi-arch)
docker pull nullusionist/nova-tor-relay:0.4.8.17-trixie

# Force an explicit platform
docker pull --platform=linux/amd64 nullusionist/nova-tor-relay:latest
docker pull --platform=linux/arm64 nullusionist/nova-tor-relay:latest
```

**Verify multi‑arch**
```bash
docker buildx imagetools inspect nullusionist/nova-tor-relay:latest
# should list both linux/amd64 and linux/arm64
```

---

## 🔁 Automatic Updates

Watchtower label example:
```yaml
labels:
  - "com.centurylinklabs.watchtower.enable=true"
```

---

## ⚠️ Exit Relay Notice

Running an **exit node** has legal/abuse implications. Exit mode is **off by default**. Enable `EXIT_RELAY=1` only if you understand the risks and policies.

---

## ✅ Check Your Relay

After startup, find your relay:
- Tor Relay Search: https://metrics.torproject.org/rs.html#search/

---

## 🧰 Maintainers

Release process (summary):
1. Build & push arch images (`*-amd64`, `*-arm64`).
2. Create multi‑arch manifests for `latest`, `X.Y.Z`, and `X.Y.Z-<codename>`.
3. Verify with `imagetools inspect`.

Internal helper scripts live under `scripts/` (not required for users).

---

## 🌐 Mirrors

- GitHub: https://github.com/nullusionist/nova-tor-relay  
- GitLab: https://gitlab.com/nullusionist/nova-tor-relay  
- Codeberg: https://codeberg.org/nullusionist/nova-tor-relay

Primary source: https://git.nullusionist.dev/infra/nova-tor-relay

---

## 📄 License

MIT
