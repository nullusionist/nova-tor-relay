#!/usr/bin/env bash
set -euo pipefail

IMAGE_NS="${IMAGE_NS:-nullusionist}"
IMAGE_NAME="${IMAGE_NAME:-nova-tor-relay}"
IMAGE="${IMAGE_NS}/${IMAGE_NAME}"

CTX="${1:-.}"
DF="${2:-Dockerfile}"

# Arch list (change if you only want one)
ARCHES=("amd64" "arm64")

# 1) Build a local helper image to read metadata (NEVER pushed)
echo "==> Prebuilding ${IMAGE}:detect to read metadata"
docker build -f "$DF" -t "${IMAGE}:detect" "$CTX" 1>&2

echo "==> Reading Tor version"
TOR_VERSION="$(docker run --rm --entrypoint /bin/sh "${IMAGE}:detect" -c \
  'tor --version | awk "/^Tor version /{print \$3}" | sed "s/\\.\$//"')"
[ -n "$TOR_VERSION" ] || { echo "ERROR: could not read Tor version"; exit 1; }

echo "==> Reading Debian codename"
CODENAME="$(docker run --rm --entrypoint /bin/sh "${IMAGE}:detect" -c '
  if command -v lsb_release >/dev/null 2>&1; then
    CN=$(lsb_release -sc 2>/dev/null || true)
  elif [ -r /etc/os-release ]; then
    . /etc/os-release; CN="${VERSION_CODENAME:-${DEBIAN_CODENAME:-unknown}}"
  else
    CN=unknown
  fi
  printf "%s" "$CN" | tr -c "A-Za-z0-9._-" "-" | sed "s/^-*//; s/-*$//"
')"
[ -n "$CODENAME" ] || CODENAME="unknown"

VER_TAG="${TOR_VERSION}"
VER_CODENAME_TAG="${TOR_VERSION}-${CODENAME}"
echo "==> Tags: latest, ${VER_TAG}, ${VER_CODENAME_TAG}"

# 2) For each arch, build and PUSH arch-suffixed images
for A in "${ARCHES[@]}"; do
  echo "==> Building & pushing ${A}"
  docker buildx build \
    --builder ntr-builder \
    --platform "linux/${A}" \
    -f "$DF" \
    -t "${IMAGE}:latest-${A}" \
    -t "${IMAGE}:${VER_TAG}-${A}" \
    -t "${IMAGE}:${VER_CODENAME_TAG}-${A}" \
    --push \
    "$CTX"
done

# 3) Create + push multi-arch manifests (no detect pushes)
echo "==> Creating and pushing manifest lists"

# Helper to annotate and push one tag
mk_manifest() {
  local TAG="$1"; shift
  docker manifest create "${IMAGE}:${TAG}" \
    $(for A in "${ARCHES[@]}"; do printf "%s:%s-%s " "${IMAGE}" "${TAG}" "${A}"; done)
  for A in "${ARCHES[@]}"; do
    docker manifest annotate "${IMAGE}:${TAG}" "${IMAGE}:${TAG}-${A}" --arch "${A}"
  done
  docker manifest push "${IMAGE}:${TAG}"
}

mk_manifest "latest"
mk_manifest "${VER_TAG}"
mk_manifest "${VER_CODENAME_TAG}"

echo "==> Done."
echo "Published:"
echo "  - ${IMAGE}:latest"
echo "  - ${IMAGE}:${VER_TAG}"
echo "  - ${IMAGE}:${VER_CODENAME_TAG}"
