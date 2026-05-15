# DigitalBase vLLM Edition — Docker Compose

Single-host deployment with everything on one GPU machine.

## Prerequisites

| 項目 | 要件 |
|---|---|
| Docker | 20.10+ (with `compose` v2 plugin) |
| GPU | NVIDIA, CUDA 12+ |
| Driver | `nvidia-container-toolkit` ([install guide](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)) |
| メモリ | RAM 16 GB+, VRAM 16 GB+ (default model: gemma-4-E2B-it) |
| ディスク | 50 GB+ (DB + HF キャッシュ + image) |
| License | サブスクリプション版 `license.lic` |

## Quick Start

```bash
# 1. ファイル取得
git clone https://github.com/lmlight-app/dist_vite.git
cd dist_vite/examples/docker-compose-vllm

# 2. ライセンス配置（営業窓口から受領）
cp /path/to/your/license.lic .

# 3. 環境変数を設定
cp .env.example .env
nano .env       # POSTGRES_PASSWORD, JWT_SECRET を必ず変更

# 4. 起動
docker compose up -d

# 5. 進捗確認（初回は vLLM のモデル DL に 5〜10 分）
docker compose logs -f
```

起動完了後：
- UI: <http://localhost:8000>
- 初期ログイン: `admin@local` / `admin123`（初回ログイン後にパスワード変更）

## 構成

```
┌──── ホスト ─────────────────────────────────────────┐
│                                                    │
│  ┌── docker compose で起動するもの ─────────────┐ │
│  │                                                │ │
│  │  postgres :5432   ← state, RAG embedding      │ │
│  │  whisper  :9000   ← 音声書起 (内部のみ)        │ │
│  │  vllm-chat        ← GPU 上のチャット推論        │ │
│  │  vllm-embed       ← GPU 上の埋め込み            │ │
│  │  api      :8000   ← API + UI (顧客アクセス)    │ │
│  │                                                │ │
│  └────────────────────────────────────────────────┘ │
│                                                    │
└────────────────────────────────────────────────────┘
                       ↑
              http://localhost:8000
```

## 操作

```bash
docker compose up -d         # 起動
docker compose down          # 停止（データは保持）
docker compose down -v       # 停止 + DB データ削除
docker compose logs -f api   # 特定サービスのログ
docker compose pull          # 全イメージ最新化
docker compose restart api   # API だけ再起動
```

## カスタマイズ

### モデル変更
`.env` の `VLLM_CHAT_MODEL` / `VLLM_EMBED_MODEL` を変更し `docker compose up -d` で再起動。
HuggingFace の任意モデル ID 指定可（gated モデルは別途 HF_TOKEN 設定が必要）。

### GPU メモリの分配を変更
1 GPU で chat + embed を共存する場合は合計 0.90 以下に：
```
VLLM_GPU_MEM_CHAT=0.55
VLLM_GPU_MEM_EMBED=0.35
```
別 GPU に分けるなら両方 0.85 程度に上げる（その場合は GPU 番号指定が必要、下記参照）。

### 複数 GPU で chat / embed を分ける
`docker-compose.yml` の vllm-chat / vllm-embed の `deploy.resources.reservations.devices` を編集：
```yaml
vllm-chat:
  deploy:
    resources:
      reservations:
        devices:
          - { driver: nvidia, device_ids: ["0"], capabilities: [gpu] }
vllm-embed:
  deploy:
    resources:
      reservations:
        devices:
          - { driver: nvidia, device_ids: ["1"], capabilities: [gpu] }
```

### HF キャッシュを共有
`.env` の `HF_HOME` を host 側の既存キャッシュへ向けると再 DL を避けられる：
```
HF_HOME=/srv/hf-cache
```

## トラブルシューティング

### 「License required」403 で API が起動しない
- `license.lic` がディレクトリにあるか確認
- mount target が `/app/data/license.lic` であること（compose ファイルで設定済み）

### vllm-chat が起動しない / OOM
- GPU メモリ不足。`VLLM_MAX_MODEL_LEN` を小さく（例 2048）するか `VLLM_GPU_MEM_CHAT` を上げる
- モデル変更（より小さいモデルへ）
- `docker compose logs vllm-chat` で詳細

### `nvidia-container-toolkit` が無いと言われる
```bash
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list \
  | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt update && sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### pgvector extension が無いとエラー
`init-pgvector.sql` が同じディレクトリに存在することを確認。
**volume を削除して再作成**しないと反映されません：
```bash
docker compose down -v   # ⚠️ DB データ消えます
docker compose up -d
```

### 初回起動が遅い
vLLM が HF からモデルをダウンロード + CUDA graph をコンパイル。typical は 5〜10 分。
`docker compose logs -f vllm-chat` で進捗。

## バックアップ

Postgres を host 側に dump：
```bash
docker compose exec postgres pg_dump -U digitalbase digitalbase | gzip > db-$(date +%F).sql.gz
```

リストア：
```bash
gunzip -c db-2026-05-15.sql.gz | docker compose exec -T postgres psql -U digitalbase digitalbase
```

## アップデート

```bash
# .env で IMAGE_TAG を固定している場合
nano .env                           # IMAGE_TAG=1.2.4 などに変更
docker compose pull && docker compose up -d

# tag が "1" や "latest" の場合（自動追従）
docker compose pull && docker compose up -d
```
