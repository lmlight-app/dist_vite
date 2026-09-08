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
  # deb/rpm パッケージ (pkg-publish.yml が pkg* タグで生成・古い release には無い)
  "digitalbase-amd64.deb"
  "digitalbase-amd64.deb.sha256"
  "digitalbase-arm64.deb"
  "digitalbase-arm64.deb.sha256"
  "digitalbase-amd64.rpm"
  "digitalbase-amd64.rpm.sha256"
  "digitalbase-arm64.rpm"
  "digitalbase-arm64.rpm.sha256"
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

# pgvector (Windows) zip は本線 release (x*) とは独立した固定タグ release
# 'pgvector-latest' に置かれる (release-pgvector-windows.yml が rolling 上書き)。
# 固定タグを直接参照するので、x* の本数・latest に一切依存しない。版非依存の固定名
# pgvector-pg<major>-windows-x64.zip をバイナリと同じく R2 (vite-latest / vite-$TAG) に同梱。
PGVEC_TAG="pgvector-latest"
echo "Downloading pgvector (Windows) assets from $PGVEC_TAG release..."
gh release download "$PGVEC_TAG" --repo "$REPO" -p "pgvector-pg*-windows-x64.zip*" -D "$TMPDIR" 2>/dev/null \
  && echo "  ✓ pgvector ($PGVEC_TAG)" \
  || echo "  - pgvector assets (not found in $PGVEC_TAG, skipping)"

# latest.json: app 内の「最新状況を確認」が参照する版マニフェスト (タグ x20260812 → "26.0812")。
# 推論エンジン / uv の固定版 (scripts/engine-versions.env が正本) も同居させ、installer が読んで版固定 install する
RAW="${TAG#x}"; RAW="${RAW%%-*}"
VERSION="$(printf '%s' "$RAW" | sed -E 's/^20([0-9]{2})([0-9]{4})/\1.\2/')"
# shellcheck source=scripts/engine-versions.env
. "$(dirname "$0")/scripts/engine-versions.env"
: "${VLLM_VERSION:?engine-versions.env: VLLM_VERSION is required}" "${SGLANG_VERSION:?engine-versions.env: SGLANG_VERSION is required}" "${UV_VERSION:?engine-versions.env: UV_VERSION is required}"
printf '{"version":"%s","released_at":"%s","vllm_version":"%s","sglang_version":"%s","uv_version":"%s","torch_index":"%s"}\n' \
  "$VERSION" "$(date -u +%Y-%m-%d)" "$VLLM_VERSION" "$SGLANG_VERSION" "$UV_VERSION" "${TORCH_INDEX:-}" > "$TMPDIR/latest.json"
echo "  ✓ latest.json (version $VERSION, vllm $VLLM_VERSION, sglang $SGLANG_VERSION, uv $UV_VERSION)"

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
