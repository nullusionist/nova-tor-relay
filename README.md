# 🛰️ Nova Tor Relay

- [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
- [![Docker Pulls](https://img.shields.io/docker/pulls/nullusionist/nova-tor-relay)](https://hub.docker.com/r/nullusionist/nova-tor-relay)
- [![Mirror: GitHub](https://img.shields.io/badge/mirror-github-blue?logo=github)](https://github.com/nullusionist/nova-tor-relay)
- [![Mirror: GitLab](https://img.shields.io/badge/mirror-gitlab-orange?logo=gitlab)](https://gitlab.com/nullusionist/nova-tor-relay)
- [![Mirror: Codeberg](https://img.shields.io/badge/mirror-codeberg-lightblue?logo=codeberg)](https://codeberg.org/nullusionist/nova-tor-relay)

Nova Tor Relay is a minimal, opinionated Docker image for running a secure Tor relay node with simple configuration via environment variables and `docker-compose`.

Image: [nullusionist/nova-tor-relay](https://hub.docker.com/r/nullusionist/nova-tor-relay)

## 🚀 Quick Start

1. Clone the repo
2. Copy `.env.example` to `.env` and edit as needed
3. Launch with Docker Compose:

```bash
docker compose up -d
```

> 📌 Make sure to forward ports `9001` (ORPort) and `9030` (DirPort) from your router/firewall to this host.  
> Future versions may optionally support automatic UPnP port forwarding.

Your relay will automatically:

- Detect its public IP
- Generate a persistent random nickname based on your chosen prefix
- Apply bandwidth limits
- Register with the Tor network

## ⚙️ Configuration

All settings are configured via environment variables. See `.env.example` for all available options.

### Common overrides

```env
CONTACT=your@email.com
BANDWIDTH_LIMIT=100 KB
BANDWIDTH_BURST=200 KB
# NICKNAME=MyRelay
# EXIT_RELAY=1
# EXIT_POLICY=accept 80,443
# ACCOUNTING_START=day 1 00:00
# ACCOUNTING_MAX=5 GB
```

Multiline config (like `MyFamily` or logging) can be injected via:

```env
TOR_EXTRA_LINES=Log notice stdout\nMyFamily ABC123,DEF456
```

## 🔁 Automatic Updates

This repo includes a Watchtower config to auto-update your relay container when a new image is pushed.

```yaml
labels:
  - "com.centurylinklabs.watchtower.enable=true"
```

## ⚠️ Exit Relay Notice

Running an **exit node** comes with legal and abuse implications. Exit mode is disabled by default. Only enable `EXIT_RELAY=1` if you know what you're doing.

## 🌐 Mirrors

This repository is actively mirrored to:

- [GitLab.com](https://gitlab.com/nullusionist/nova-tor-relay)
- [GitHub](https://github.com/nullusionist/nova-tor-relay)
- [Codeberg](https://codeberg.org/nullusionist/nova-tor-relay)

Primary source: [git.nullusionist.dev/infra/nova-tor-relay](https://git.nullusionist.dev/infra/nova-tor-relay)

## ✅ Check Your Relay

After startup, check the status of your relay here:

[Tor Relay Search](https://metrics.torproject.org/rs.html#search/NovaRelay)
