# 📦 Changelog

## [v1.0.2] - 2025-06-20

- Updated CI to trigger mirror job on tag creation (`CI_COMMIT_TAG`)
- Ensures all future tags like `v1.x.y` auto-sync to:
  - GitHub
  - GitLab.com
  - Codeberg
- Tag-only pushes now work without requiring a branch commit

## [v1.0.1] - 2025-06-20

- Added `CHANGELOG.md`
- Trimmed CI to stop force-pushing `main` now that all mirrors are stable
- Confirmed `v1.0.0` tag sync across all mirrors

## [v1.0.0] - 2025-06-20

- Initial public release of the Nova Tor Relay Docker image
- Auto-detects public IP and generates persistent nickname
- Exposes all relevant torrc settings via environment variables
- Docker Compose support with volume-based data persistence
- Optional ControlPort and ExitRelay support
- Watchtower compatibility for auto-updating deployments
- CI/CD pipeline mirrors `main` and tags to:
  - GitHub
  - GitLab.com
  - Codeberg
