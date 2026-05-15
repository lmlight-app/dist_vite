# DigitalBase Ollama Edition — Docker Compose

GPU 任意の軽量構成。Ollama は **ホスト側で別途実行** します。

## Prerequisites

| 項目 | 要件 |
|---|---|
| Docker | 20.10+ (with `compose` v2 plugin) |
| Ollama | host にインストール ([ollama.com](https://ollama.com)) |
| GPU | 任意（CPU でも動作可、ただし遅い） |
| メモリ | RAM 8 GB+ |
| ディスク | 20 GB+ (DB + Ollama モデル + image) |
| License | サブスクリプション版 `license.lic` |

## Quick Start

```bash
# 1. ファイル取得
git clone https://github.com/lmlight-app/dist_vite.git
cd dist_vite/examples/docker-compose-ollama

# 2. ライセンス配置
cp /path/to/your/license.lic .

# 3. 環境変数
cp .env.example .env
nano .env       # POSTGRES_PASSWORD, JWT_SECRET を必ず変更

# 4. ホスト側で Ollama 準備
curl -fsSL https://ollama.com/install.sh | sh
ollama pull gemma3:4b
ollama pull nomic-embed-text       # RAG 用

# 5. 起動
docker compose up -d
docker compose logs -f
```

起動完了後：
- UI: <http://localhost:8000>
- 初期ログイン: `admin@local` / `admin123`

## 構成

```
┌── ホスト ────────────────────────────────────────┐
│                                                  │
│  ollama serve :11434  ← LLM 推論 (ホストで実行)   │
│                                                  │
│  ┌── docker compose ─────────────────────────┐  │
│  │                                            │  │
│  │  postgres :5432   ← state, RAG             │  │
│  │  whisper          ← 音声書起               │  │
│  │  api :8000        ← API + UI               │  │
│  │     ↑                                      │  │
│  │     └── host.docker.internal:11434 へ──→  │  │
│  │                                            │  │
│  └────────────────────────────────────────────┘  │
│                                                  │
└──────────────────────────────────────────────────┘
                  ↑
         http://localhost:8000
```

## 操作

```bash
docker compose up -d         # 起動
docker compose down          # 停止（データ保持）
docker compose down -v       # 停止 + DB 削除
docker compose logs -f api   # ログ確認
docker compose pull && docker compose up -d   # アップデート
```

## Ollama モデルの追加

```bash
ollama list                 # 現在のモデル
ollama pull llama3.2:3b     # 追加
ollama pull qwen2.5:7b      # 追加
```

DigitalBase の UI から自動的に検出されます。

## トラブルシューティング

### `host.docker.internal` で Ollama に到達できない
- ホスト側で Ollama が listening しているか: `curl http://localhost:11434/api/tags`
- 別マシンで Ollama を動かしている場合、`.env` の `OLLAMA_BASE_URL` をその IP に変更
- Linux で `host.docker.internal` が解決されない場合は compose の `extra_hosts` で `host-gateway` 設定済み（v20.10+ で動作）

### `License required` 403
- `license.lic` がディレクトリにあること
- mount path は `/app/data/license.lic`（compose で設定済み）

### pgvector が無い
`init-pgvector.sql` が同じディレクトリにあること。volume を削除して再作成：
```bash
docker compose down -v
docker compose up -d
```

## vLLM 版へ移行

GPU を持っていて高スループット推論が必要なら [`../docker-compose-vllm/`](../docker-compose-vllm/) へ。
DB データは共通フォーマットなので、`.env` を新ディレクトリにコピー + DB volume を引き継げば移行可能。
