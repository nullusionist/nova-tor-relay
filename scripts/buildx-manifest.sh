#!/usr/bin/env bash
set -euo pipefail

# Build/push per-arch images, then create multi-arch manifest tags.
# This version fixes Tor version parsing and supports --amend.
#
# Usage:
#   scripts/buildx-manifest.new.sh [CONTEXT] [DOCKERFILE] [--amend]
#
# Env overrides:
#   IMAGE_NS (default: nullusionist)
#   IMAGE_NAME (default: nova-tor-relay)
#   ARCHES (default: "amd64 arm64")

IMAGE_NS="${IMAGE_NS:-nullusionist}"
IMAGE_NAME="${IMAGE_NAME:-nova-tor-relay}"
IMAGE="${IMAGE_NS}/${IMAGE_NAME}"

CTX="${1:-.}"
DF="${2:-Dockerfile}"

# Parse optional flags (only --amend recognized)
AMEND=0
for arg in "${@:3}"; do
  case "$arg" in
    --amend) AMEND=1 ;;
    *) : ;;  # ignore other flags like --push if passed
  esac
done

# Arch list
: "${ARCHES:=amd64 arm64}"
read -r -a ARCH_ARR <<<"$ARCHES"

# Ensure buildx builder exists
if ! docker buildx inspect ntr-builder >/dev/null 2>&1; then
  docker buildx create --name ntr-builder --driver docker-container --use >/dev/null
  docker buildx inspect --bootstrap >/dev/null
fi

echo "==> Prebuilding ${IMAGE}:detect to read metadata"
docker build -f "$DF" -t "${IMAGE}:detect" "$CTX" 1>&2

echo "==> Reading Tor version"
TOR_VERSION="$(
  docker run --rm --entrypoint /bin/sh "${IMAGE}:detect" -c '
    # tor --version output varies:
    #   "Tor 0.4.8.17"
    #   "Tor version 0.4.8.17."
    tor --version 2>/dev/null | sed -nE "s/^Tor (version )?([0-9]+(\.[0-9]+){1,3})\.?$/\2/p" | head -n1
  ' | tr -d "\r\n"
)"
if [[ -z "${TOR_VERSION}" ]]; then
  echo "ERROR: could not parse Tor version"; exit 1
fi

echo "==> Reading Debian codename"
CODENAME="$(
  docker run --rm --entrypoint /bin/sh "${IMAGE}:detect" -c '
    if command -v lsb_release >/dev/null 2>&1; then
      CN=$(lsb_release -sc 2>/dev/null || true)
    elif [ -r /etc/os-release ]; then
      . /etc/os-release; CN="${VERSION_CODENAME:-${DEBIAN_CODENAME:-unknown}}"
    else
      CN=unknown
    fi
    printf "%s" "$CN" | tr -c "A-Za-z0-9._-" "-" | sed "s/^-*//; s/-*$//"
  ' | tr -d "\r\n"
)"
[[ -n "$CODENAME" ]] || CODENAME="unknown"

VER_TAG="${TOR_VERSION}"
VER_CODENAME_TAG="${TOR_VERSION}-${CODENAME}"
echo "==> Tags: latest, ${VER_TAG}, ${VER_CODENAME_TAG}"

# Build & push arch images
for A in "${ARCH_ARR[@]}"; do
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

echo "==> Creating and pushing manifest lists"

manifest_exists() {
  docker manifest inspect "${IMAGE}:$1" >/dev/null 2>&1
}

mk_manifest() {
  local tag="$1"
  local refs=()
  for A in "${ARCH_ARR[@]}"; do refs+=("${IMAGE}:${tag}-${A}"); done

  local create_flags=()
  if manifest_exists "$tag"; then
    if (( AMEND )); then
      create_flags+=(--amend)
      echo "   (amend) ${IMAGE}:${tag} exists; amending…"
    else
      echo "ERROR: manifest ${IMAGE}:${tag} already exists."
      echo "       Re-run with --amend or remove it:"
      echo "         docker manifest rm ${IMAGE}:${tag}"
      exit 1
    fi
  fi

  docker manifest create "${create_flags[@]}" "${IMAGE}:${tag}" "${refs[@]}"

  # Annotate for each arch
  for A in "${ARCH_ARR[@]}"; do
    docker manifest annotate "${IMAGE}:${tag}" "${IMAGE}:${tag}-${A}" --arch "${A}" --os linux
  done

  docker manifest push "${IMAGE}:${tag}"
}

mk_manifest "latest"
mk_manifest "${VER_TAG}"
mk_manifest "${VER_CODENAME_TAG}"

echo "==> Done."
echo "Published/updated:"
echo "  - ${IMAGE}:latest"
echo "  - ${IMAGE}:${VER_TAG}"
echo "  - ${IMAGE}:${VER_CODENAME_TAG}"
