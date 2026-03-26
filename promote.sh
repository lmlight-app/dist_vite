#!/bin/bash
# Promote a GitHub Release to Cloudflare R2 (production CDN)
# Usage: ./promote.sh [tag]
#   tag: e.g. v3.1.0 (default: latest)
set -e

REPO="lmlight-app/dist_v3"
BUCKET="r2:lmlightbinary"
TAG="${1:-latest}"

ASSETS=(
  "lmlight-perpetual-linux-amd64"
  "lmlight-perpetual-linux-amd64.sha256"
  "lmlight-perpetual-linux-arm64"
  "lmlight-perpetual-linux-arm64.sha256"
  "lmlight-perpetual-macos-arm64"
  "lmlight-perpetual-macos-arm64.sha256"
  "lmlight-perpetual-windows-amd64.exe"
  "lmlight-perpetual-windows-amd64.exe.sha256"
  "lmlight-vllm-linux-amd64"
  "lmlight-vllm-linux-amd64.sha256"
  "lmlight-vllm-linux-arm64"
  "lmlight-vllm-linux-arm64.sha256"
  "lmlight-app.tar.gz"
  "lmlight-app.tar.gz.sha256"
)

# Resolve actual tag name if "latest"
if [ "$TAG" = "latest" ]; then
  TAG=$(gh release view --repo "$REPO" --json tagName -q .tagName)
  echo "Latest tag: $TAG"
fi

echo "Promoting $TAG → R2"

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo "Downloading release assets..."
for asset in "${ASSETS[@]}"; do
  gh release download "$TAG" --repo "$REPO" -p "$asset" -D "$TMPDIR" 2>/dev/null \
    && echo "  ✓ $asset" \
    || echo "  - $asset (not found, skipping)"
done

echo "Uploading to R2..."
rclone copy "$TMPDIR/" "$BUCKET/latest/" --progress
rclone copy "$TMPDIR/" "$BUCKET/$TAG/" --progress

echo "Uploading scripts to R2..."
SCRIPT_DIR="$(cd "$(dirname "$0")/scripts" && pwd)"
rclone copy "$SCRIPT_DIR/" "$BUCKET/scripts/" --progress \
  --header-upload "Content-Type: text/plain; charset=utf-8"

echo "Uploading README.md to R2..."
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
rclone copyto "$ROOT_DIR/README.md" "$BUCKET/README.md" --s3-no-check-bucket

echo "Done."
echo "Public URL: https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/latest/"