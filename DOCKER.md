> ⚠️ **DEPRECATED / EOL** — 旧 `digitalbase-ollama` / `digitalbase-vllm` イメージ前提の旧手順です。現行は単一イメージ `lmlight/digitalbase:latest`（edition は `.env` の `LLM_BACKEND` で切替）+ `install-docker.sh`。最新は [README](README.md) を参照。

# Docker 詳細 (= manual / docker-compose 構成)

> **簡単な install** は `install-docker.sh` を使ってください ([README.md](README.md#docker) 参照)。
> 以下は **手動構成 / マルチ container 構成 (docker-compose)** が必要な場合の詳細手順。

---

## 提供 image

| Image | LLM Backend | 推奨用途 |
|---|---|---|
| `lmlight/digitalbase:latest` | Ollama | CPU/GPU 混在、軽量モデル (≤7B) |
| `lmlight/digitalbase:latest` | vLLM | NVIDIA GPU、高 throughput |

両 image とも `linux/amd64` / `linux/arm64` 対応。API + UI を 1 container 同梱。

> **注**: api-vllm/ legacy build は 2026-06-05 で deprecated。新規 deploy は `digitalbase:latest` image (= `LLM_BACKEND=ollama` env で ollama mode) + `LLM_BACKEND=vllm` env で vllm mode 可能。

---

## 手動 docker run 構成

### Step 1: PostgreSQL bootstrap (= 初回のみ)

**macOS / Linux** (= host の postgres を使う場合):
```bash
psql -U postgres <<'SQL'
CREATE USER digitalbase WITH PASSWORD 'digitalbase';
CREATE DATABASE digitalbase OWNER digitalbase;
ALTER USER digitalbase CREATEDB;
\c digitalbase
CREATE EXTENSION IF NOT EXISTS vector;
SQL
```

### Step 2: 作業 dir + `.env` + license

```bash
mkdir digitalbase && cd digitalbase

cat > .env <<EOF
DATABASE_URL=postgresql://digitalbase:digitalbase@host.docker.internal:5432/digitalbase
OLLAMA_BASE_URL=http://host.docker.internal:11434
OLLAMA_AUTO_START=false
LLM_CONTEXT_LENGTH=16384
JWT_SECRET=$(openssl rand -hex 32)
OAUTH_ENCRYPTION_KEY=$(openssl rand -hex 32)
AUTH_MODE=local
EOF
chmod 600 .env

cp /path/to/license.lic ./license.lic
```

> `JWT_SECRET` / `OAUTH_ENCRYPTION_KEY` は **container 再作成時に値が変わると既存データ復号不能**。`.env` 保存必須。

### Step 3: container 起動

```bash
docker pull lmlight/digitalbase:latest

docker run -d \
  --name db \
  -p 8000:8000 \
  --env-file .env \
  -v "$PWD":/app/data \
  --add-host=host.docker.internal:host-gateway \
  --restart unless-stopped \
  lmlight/digitalbase:latest
```

container 起動時に **DB schema / table / index / 初期 admin user は自動作成**。
アクセス: http://localhost:8000、初回: `admin@local` / `admin123`。

### vLLM mode で起動する場合

`.env` で `LLM_BACKEND=vllm` 設定 + 外部 vLLM server を起動 + URL を `.env` に追加:

```bash
LLM_BACKEND=vllm
VLLM_BASE_URL=http://host.docker.internal:8080
VLLM_EMBED_BASE_URL=http://host.docker.internal:8081
VLLM_AUTO_START=false   # container 内 spawn 不可
```

---

## docker-compose (= フルスタック 1 発起動)

API + Postgres + Whisper + vLLM (chat/embed) を同時起動。GPU は `nvidia-container-toolkit` で自動 mount。

```yaml
services:
  postgres:
    image: pgvector/pgvector:pg16
    environment:
      POSTGRES_USER: digitalbase
      POSTGRES_PASSWORD: digitalbase
      POSTGRES_DB: digitalbase
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./init-pgvector.sql:/docker-entrypoint-initdb.d/init-pgvector.sql:ro
    restart: unless-stopped

  whisper:
    image: onerahmet/openai-whisper-asr-webservice:latest
    environment:
      ASR_MODEL: base
      ASR_ENGINE: openai_whisper
    ports: ["9000:9000"]
    restart: unless-stopped

  vllm-chat:
    image: vllm/vllm-openai:latest
    command:
      - --model=Qwen/Qwen3-4B
      - --max-model-len=32768
      - --gpu-memory-utilization=0.55
    volumes:
      - ${HOME}/.cache/huggingface:/root/.cache/huggingface
    deploy:
      resources:
        reservations:
          devices: [{ driver: nvidia, count: 1, capabilities: [gpu] }]
    restart: unless-stopped

  vllm-embed:
    image: vllm/vllm-openai:latest
    command:
      - --model=Qwen/Qwen3-Embedding-0.6B
      - --task=embed
      - --max-model-len=2048
      - --gpu-memory-utilization=0.35
    volumes:
      - ${HOME}/.cache/huggingface:/root/.cache/huggingface
    deploy:
      resources:
        reservations:
          devices: [{ driver: nvidia, count: 1, capabilities: [gpu] }]
    restart: unless-stopped

  api:
    image: lmlight/digitalbase:latest
    env_file: .env
    volumes:
      - ./license.lic:/app/data/license.lic:ro
    ports: ["8000:8000"]
    extra_hosts:
      - "host.docker.internal:host-gateway"
    depends_on: [postgres, whisper, vllm-chat, vllm-embed]
    restart: unless-stopped

volumes:
  pgdata:
```

`init-pgvector.sql`:
```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

`.env` (vLLM 版):
```bash
LLM_BACKEND=vllm
DATABASE_URL=postgresql://digitalbase:digitalbase@postgres:5432/digitalbase
WHISPER_API_URL=http://whisper:9000
VLLM_BASE_URL=http://vllm-chat:8000
VLLM_EMBED_BASE_URL=http://vllm-embed:8000
VLLM_AUTO_START=false
VLLM_CHAT_MODEL=Qwen/Qwen3-4B
VLLM_EMBED_MODEL=Qwen/Qwen3-Embedding-0.6B
LLM_CONTEXT_LENGTH=32768
JWT_SECRET=change-me-to-random-secret
OAUTH_ENCRYPTION_KEY=random
AUTH_MODE=local
```

Ollama 版に切替えるなら `vllm-*` services を削除、`.env` で `LLM_BACKEND=ollama` + `OLLAMA_BASE_URL=http://host.docker.internal:11434` (= host で起動した Ollama 参照)。

```bash
docker compose up -d      # 起動 (= 初回は vLLM model DL に数分)
docker compose logs -f    # log
docker compose down       # 停止
```

---

## 操作

```bash
docker logs db        # log
docker stop db        # 停止
docker start db       # 起動
```

### アップデート (= 手動)

```bash
cd digitalbase
docker pull lmlight/digitalbase:latest
docker stop db && docker rm db
docker run -d --name db -p 8000:8000 --env-file .env \
  -v "$PWD":/app/data --add-host=host.docker.internal:host-gateway \
  --restart unless-stopped \
  lmlight/digitalbase:latest
```

> `.env` 再利用で **`JWT_SECRET` / `OAUTH_ENCRYPTION_KEY` 不変** = 既存 session / 暗号化 connection 設定保持。

---

## トラブルシューティング

### License 認識されない (= "License required" 403)

container 内パス: **`/app/data/license.lic`** (= `/app/license.lic` ではない)

```yaml
volumes:
  - ./license.lic:/app/data/license.lic:ro
```

ファイル mount できない環境 (= GMI Cloud 等の constrained container) では起動後 API 経由 upload:
```bash
db-docker upload-license <license.lic>
# または admin UI > ライセンス > upload
```

### GPU 無い環境で vllm-chat が "unhealthy"

vLLM 版は GPU 必須。代替:
- Ollama 版に切替え
- Modal / RunPod 等の managed 推論 API URL を `VLLM_BASE_URL` に指定

### 初回起動が遅い (= 数分)

vLLM model DL + load で 1-3 分。`docker compose logs vllm-chat` で進捗確認、完了まで `api` の `/health` も 503。
