# 📦 Changelog

All notable changes to **Nova Tor Relay** are documented here.

## [v1.1.2] - 2025-09-05

### Image 
- Slimmer image builds with --no-install-recommends

## [v1.1.1] - 2025-09-05

### CI/CD
- Mirrors now perform **source-of-truth syncs**:
  - **`git push --mirror`** on branch pipelines so GitHub/GitLab/Codeberg exactly match upstream (branches **and** tags, including deletes and rewrites).
  - Tag-only pipelines push **just the triggering tag** (no branch changes).
- Fetch full history (`GIT_DEPTH=0`) and set `safe.directory` for the runner.
- Requires mirror permissions to allow **force-push** on `main` and **tag deletes/moves**.

### Fixed
- Eliminates non-fast-forward/tag-clobber errors; mirrors now stay byte-for-byte aligned with upstream.

> No image/content changes in this release; CI only.

## [v1.1.0] - 2025-09-05

### Added
- **Multi-arch distribution**: `latest`, `X.Y.Z`, and `X.Y.Z-<codename>` are now **manifest lists** that select `linux/amd64` or `linux/arm64` automatically.
- Arch-specific images are published as `*-amd64` and `*-arm64` and then assembled into multi-arch tags.

### Changed
- **Compose** now references env values (e.g., `CONTACT`, `BANDWIDTH_LIMIT`, etc.).
- **Environment defaults** refined in `entrypoint.sh`; stronger validation of `CONTACT` and saner bandwidth defaults.
- Docs: multiple README passes to reflect Compose + env model, tag strategy, and quick-start flow.

### Fixed
- Bandwidth defaults and examples (`BANDWIDTH_LIMIT`, `BANDWIDTH_BURST`) corrected and clarified.

### CI/CD
- New **autobuild** flow (separate repo) that detects Tor releases, Docker base updates, or upstream `main` changes and rebuilds/pushes:
  - Builds **per-arch images** and then **re-tags multi-arch** `latest`, version, and codename tags.
  - Ensures `latest` manifest points to the newest arch images (no stale references).

### Upgrade notes
- If you previously pinned `latest-amd64` or `latest-arm64`, you may now safely use `latest` (multi-arch).  
- If you run Watchtower, keep the label `com.centurylinklabs.watchtower.enable=true` on the `relay` service.
- The Compose file now **references .env for config values**. Copy your `.env` into place and edit (CONTACT must be updated):
  ```bash
  cp .env.example .env
  nano .env
  docker compose up -d
  ```

---

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
