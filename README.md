# 🛰️ Nova Tor Relay

- [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
- [![Docker Pulls](https://img.shields.io/docker/pulls/nullusionist/nova-tor-relay)](https://hub.docker.com/r/nullusionist/nova-tor-relay)
- Mirrors: [GitHub](https://github.com/nullusionist/nova-tor-relay) · [GitLab](https://gitlab.com/nullusionist/nova-tor-relay) · [Codeberg](https://codeberg.org/nullusionist/nova-tor-relay)

Minimal, opinionated Docker image to run a secure Tor **relay**.  
Image: **`nullusionist/nova-tor-relay`**

> Repo ships **`compose.yaml.example`** and **`.env.example`**. Copy both, tweak email, and start.
>
> ```bash
> cp .env.example .env
> cp compose.yaml.example compose.yaml
> docker compose up -d
> ```

---

## 🚀 Quick Start

1) **Create `.env`**
   - We ship sane defaults; only `CONTACT` is required.
   - Example file already includes:
     ```env
     CONTACT=your@email.com
     BANDWIDTH_LIMIT=100 KB
     BANDWIDTH_BURST=200 KB
     # ...more optional vars commented below
     ```
   - Update `CONTACT` to **your** email.

2) **Start**
   ```bash
   docker compose up -d
   ```

3) **Check logs**
   ```bash
   docker logs -f --tail 200 nova-relay
   ```
   Your relay will appear on: https://metrics.torproject.org/rs.html

> **State:** `/var/lib/tor` is persisted in the `tor-data` volume (keeps relay identity).  
> **Ports:** exposes **9001/tcp** (ORPort) and **9030/tcp** (DirPort). ControlPort is off unless you set it.

---

## 📦 Reference `compose.yaml` (uses `.env` variables)

```yaml
services:
  relay:
    image: nullusionist/nova-tor-relay:latest
    container_name: nova-relay
    ports:
      - "9001:9001"   # ORPort
      - "9030:9030"   # DirPort
      - "9051:9051"   # ControlPort
    volumes:
      - tor-data:/var/lib/tor
    restart: unless-stopped
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
    environment:
      CONTACT: ${CONTACT}
      BANDWIDTH_LIMIT: ${BANDWIDTH_LIMIT:-100 KB}
      BANDWIDTH_BURST: ${BANDWIDTH_BURST:-200 KB}
      NICKNAME: ${NICKNAME:-}
      OR_PORT: ${OR_PORT:-9001}
      DIR_PORT: ${DIR_PORT:-9030}
      CONTROL_PORT: ${CONTROL_PORT:-}
      EXIT_RELAY: ${EXIT_RELAY:-0}
      EXIT_POLICY: ${EXIT_POLICY:-}
      ACCOUNTING_START: ${ACCOUNTING_START:-}
      ACCOUNTING_MAX: ${ACCOUNTING_MAX:-}
      TOR_EXTRA_LINES: ${TOR_EXTRA_LINES:-}

# Optional self-updating Watchtower for automatic updates
#  watchtower:
#    image: containrrr/watchtower
#    container_name: watchtower
#    restart: unless-stopped
#    labels:
#      - "com.centurylinklabs.watchtower.enable=true"
#    volumes:
#      - /var/run/docker.sock:/var/run/docker.sock
#    command: --label-enable --cleanup --interval 300

volumes:
  tor-data:
```

---

## ⚙️ Environment Variables (summary)

- **Required**
  - `CONTACT` — abuse/contact email for directory listing.

- **Auto-generated if empty**
  - `NICKNAME` — random stable nickname persisted under `/var/lib/tor`.

- **Bandwidth**
  - `BANDWIDTH_LIMIT` (default `100 KB`)
  - `BANDWIDTH_BURST` (default `200 KB`)

- **Ports** (defaults if unset)
  - `OR_PORT=9001`, `DIR_PORT=9030`, `SOCKS_PORT=0`

- **ControlPort** (off unless both set)
  - `CONTROL_PORT` (e.g. `0.0.0.0:9051`) **and** `COOKIE_AUTH=1`

- **Exit Relay (opt-in)**
  - `EXIT_RELAY=1`, `EXIT_POLICY=accept *:*` (use with care)

- **Accounting (optional)**
  - `ACCOUNTING_START`, `ACCOUNTING_MAX`

- **Extras**
  - `TOR_EXTRA_LINES` — injected verbatim into `torrc` (use `\n` for newlines)

---

## 🧭 Tags & Manifests (Multi‑Arch)

Published for `linux/amd64` and `linux/arm64`:

- `latest` → current release (**multi‑arch** manifest)  
- `X.Y.Z` → pinned Tor version (multi‑arch), e.g. `0.4.8.17`  
- `X.Y.Z-<codename>` → Tor + Debian codename (multi‑arch), e.g. `0.4.8.17-trixie`  
- Arch feeder tags: `latest-amd64`, `latest-arm64`, plus `X.Y.Z[-codename]-amd64|arm64`

Examples:
```bash
docker pull nullusionist/nova-tor-relay:latest
docker pull nullusionist/nova-tor-relay:0.4.8.17
docker pull nullusionist/nova-tor-relay:0.4.8.17-trixie
docker pull --platform=linux/amd64 nullusionist/nova-tor-relay:latest
docker pull --platform=linux/arm64 nullusionist/nova-tor-relay:latest
```

Verify multi‑arch:
```bash
docker buildx imagetools inspect nullusionist/nova-tor-relay:latest
```

---

## ⚠️ Exit Relay Notice

Running an **exit node** has legal/abuse implications. Exit mode is **off by default**. Enable `EXIT_RELAY=1` only if you understand the risks and policies.

---

## 🔁 Automatic Updates

The service is labeled for Watchtower. If you do not run a separate Watchtower instance, just uncomment the container in the compose provided.

---

## 📄 License

MIT
