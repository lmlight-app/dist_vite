#!/bin/bash
# Promote a GitHub Release to Cloudflare R2 (production CDN)
# Usage: ./promote.sh [tag]
#   tag: e.g. vite1.0.0 (default: latest)
set -e

REPO="lmlight-app/dist_vite"
BUCKET="r2:lmlightbinary"
TAG="${1:-latest}"

ASSETS=(
  # Ollama edition
  "lmlight-vite-linux-amd64"
  "lmlight-vite-linux-amd64.sha256"
  "lmlight-vite-linux-arm64"
  "lmlight-vite-linux-arm64.sha256"
  "lmlight-vite-macos-arm64"
  "lmlight-vite-macos-arm64.sha256"
  "lmlight-vite-windows-amd64.exe"
  "lmlight-vite-windows-amd64.exe.sha256"
#   "ai-server-installer-windows.exe"
#   "ai-server-installer-windows.exe.sha256"
  # vLLM edition — 統一binary化により廃止 (install-linux-vllm.sh は lmlight-vite-linux-* + LLM_BACKEND=vllm を使用)
  # "lmlight-vite-vllm-linux-amd64"
  # "lmlight-vite-vllm-linux-amd64.sha256"
  # "lmlight-vite-vllm-linux-arm64"
  # "lmlight-vite-vllm-linux-arm64.sha256"
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

# deb/rpm は release の Linux 本体からここで作る (CI の runner は使わない。nfpm か Docker が要る)
PKG_DIR="${DB_PKG_DIR:-$(cd "$(dirname "$0")/../digitalbase/pkg" 2>/dev/null && pwd || true)}"
echo "Building deb/rpm..."
if [ -n "$PKG_DIR" ] && [ -x "$PKG_DIR/build-packages.sh" ]; then
  "$PKG_DIR/build-packages.sh" "$TMPDIR" "$TAG" || echo "  - deb/rpm (failed, skipping)"
else
  echo "  - deb/rpm (digitalbase/pkg not found; set DB_PKG_DIR, skipping)"
fi

# pgvector (Windows) zip は本線 release (x*) とは独立した固定タグ release
# 'pgvector-latest' に置かれる (release-pgvector-windows.yml が rolling 上書き)。
# 固定タグを直接参照するので、x* の本数・latest に一切依存しない。版非依存の固定名
# pgvector-pg<major>-windows-x64.zip をバイナリと同じく R2 (vite-latest / vite-$TAG) に同梱。
PGVEC_TAG="pgvector-latest"
echo "Downloading pgvector (Windows) assets from $PGVEC_TAG release..."
gh release download "$PGVEC_TAG" --repo "$REPO" -p "pgvector-pg*-windows-x64.zip*" -D "$TMPDIR" 2>/dev/null \
  && echo "  ✓ pgvector ($PGVEC_TAG)" \
  || echo "  - pgvector assets (not found in $PGVEC_TAG, skipping)"

# latest.json: app 内の「最新状況を確認」と installer が参照するバージョン (タグ x20261012.4 → "26.10.124"、
# 年.月.(日×10 + その日の枝番)。digitalbase の api/scripts/release_version.sh と同じ規則)。
# 推論エンジンのバージョンは各機械で決める (installer の --vllm-version / 管理画面の「バージョンを変更」、無ければ latest)
RAW="${TAG#x}"; RAW="${RAW%%-*}"; DAY="${RAW%%.*}"; BUILD=0
[ "$RAW" = "$DAY" ] || BUILD="${RAW#*.}"
VERSION="${DAY:2:2}.$((10#${DAY:4:2})).$((10#${DAY:6:2} * 10 + 10#$BUILD))"
printf '{"version":"%s","released_at":"%s"}\n' "$VERSION" "$(date -u +%Y-%m-%d)" > "$TMPDIR/latest.json"
echo "  ✓ latest.json (version $VERSION)"

echo "Uploading to R2..."
rclone copy "$TMPDIR/" "$BUCKET/vite-latest/" --progress
rclone copy "$TMPDIR/" "$BUCKET/vite-$TAG/" --progress
rclone copy "$TMPDIR/" "$BUCKET/vite-$VERSION/" --progress

echo "Uploading scripts to R2..."
SCRIPT_DIR="$(cd "$(dirname "$0")/scripts" && pwd)"
rclone copy "$SCRIPT_DIR/" "$BUCKET/vite-scripts/" --progress \
  --header-upload "Content-Type: text/plain; charset=utf-8"

# echo "Uploading README.md to R2..."
# ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
# rclone copyto "$ROOT_DIR/README.md" "$BUCKET/vite-README.md" --s3-no-check-bucket

echo "Done."
echo "Public URL: https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/vite-latest/"
