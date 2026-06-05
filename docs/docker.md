> ⚠️ **DEPRECATED / EOL** — 旧 `digitalbase-ollama` / `digitalbase-vllm` イメージ前提の旧手順です。現行は単一イメージ `lmlight/digitalbase:latest`（edition は `.env` の `LLM_BACKEND` で切替）+ `install-docker.sh`。最新は [README](README.md) を参照。

# Docker / Kubernetes

API + UI を 1 コンテナに同梱、`linux/amd64` / `linux/arm64` 両対応。

| イメージ | LLM バックエンド | 推奨用途 |
|---|---|---|
| `lmlight/digitalbase:latest` | Ollama | CPU/GPU 混在、軽量モデル中心 (≤7B) |
| `lmlight/digitalbase:latest` | vLLM | NVIDIA GPU、高スループット、マルチテナント |

タグ運用:

| タグ | 追従 | 推奨 |
|---|---|---|
| `1.2.3` | 完全固定 | 本番 |
| `1.2`   | パッチ追従 | ステージング |
| `1`     | マイナー追従 | 互換確認 |
| `latest`| 全追従 | 開発・お試し |

## アーキテクチャ

LLM 推論 / 音声書起 / DB はコンテナ外に分離する設計。

```
┌─ digitalbase コンテナ ──────────┐    ┌─ コンテナ外 ─────────────────────┐
│  API (FastAPI :8000)             │    │  Ollama / vLLM       LLM 推論    │
│  UI (Vite ビルド、API が配信)     │ →  │  Whisper ASR        音声書起 (任意) │
│  Pipeline / RAG / chat / helpdesk │    │  Postgres + pgvector 状態 + RAG  │
└─────────────────────────────────┘    └──────────────────────────────────┘
```

設計理由: GPU メモリ制御 (`gpu_memory_utilization`) を細かく行いたい / LLM ライフサイクルを別管理にしたい / Postgres は永続化が必要 — のため。

## Ollama 版

```bash
docker pull lmlight/digitalbase:latest

docker run -d \
  --name db \
  -p 8000:8000 \
  -e DATABASE_URL=postgresql://digitalbase:digitalbase@host.docker.internal:5432/digitalbase \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  -e JWT_SECRET=$(openssl rand -hex 32) \
  -e AUTH_MODE=local \
  -v ~/.local/db/license.lic:/app/license.lic:ro \
  --restart unless-stopped \
  lmlight/digitalbase:latest
```

## vLLM 版（GPU）

vLLM サーバー本体はコンテナ外で運用。コンテナは API のみ。

```bash
docker pull lmlight/digitalbase:latest

docker run -d \
  --name db-vllm \
  -p 8000:8000 \
  -e DATABASE_URL=postgresql://digitalbase:digitalbase@host.docker.internal:5432/digitalbase \
  -e VLLM_BASE_URL=http://host.docker.internal:8080 \
  -e VLLM_EMBED_BASE_URL=http://host.docker.internal:8081 \
  -e VLLM_AUTO_START=false \
  -e JWT_SECRET=$(openssl rand -hex 32) \
  -e AUTH_MODE=local \
  -v ~/.local/db-vllm/license.lic:/app/license.lic:ro \
  --restart unless-stopped \
  lmlight/digitalbase:latest
```

## docker-compose (Postgres + Whisper 込み)

```yaml
services:
  postgres:
    image: pgvector/pgvector:pg16
    environment:
      POSTGRES_USER: digitalbase
      POSTGRES_PASSWORD: digitalbase
      POSTGRES_DB: digitalbase
    volumes: [pgdata:/var/lib/postgresql/data]
    restart: unless-stopped

  whisper:
    image: onerahmet/openai-whisper-asr-webservice:latest
    environment:
      ASR_MODEL: base
      ASR_ENGINE: openai_whisper
    ports: ["9000:9000"]
    restart: unless-stopped

  api:
    image: lmlight/digitalbase:latest
    env_file: .env
    volumes:
      - ./license.lic:/app/license.lic:ro
    ports: ["8000:8000"]
    extra_hosts:
      - "host.docker.internal:host-gateway"
    depends_on: [postgres, whisper]
    restart: unless-stopped

volumes:
  pgdata:
```

`.env` 例:

```bash
DATABASE_URL=postgresql://digitalbase:digitalbase@postgres:5432/digitalbase
WHISPER_API_URL=http://whisper:9000
JWT_SECRET=change-me-to-random-secret
AUTH_MODE=local

# vLLM 版
VLLM_BASE_URL=http://host.docker.internal:8080
VLLM_EMBED_BASE_URL=http://host.docker.internal:8081
VLLM_AUTO_START=false

# Ollama 版に切替えるなら VLLM_* を消して以下を追加
# OLLAMA_BASE_URL=http://host.docker.internal:11434
```

## 必須環境変数

### 共通
| 変数 | デフォルト | 説明 |
|---|---|---|
| `DATABASE_URL` | – | `postgresql://user:pw@host:5432/db` (pgvector 必須) |
| `WHISPER_API_URL` | – | `http://whisper:9000` (省略で文字起こし無効) |
| `LICENSE_FILE_PATH` | `/app/license.lic` | ライセンス mount 先 |
| `API_PORT` | `8000` | コンテナポート |

### Ollama 版のみ
| 変数 | デフォルト | 説明 |
|---|---|---|
| `OLLAMA_BASE_URL` | `http://host.docker.internal:11434` | Ollama サーバー |

### vLLM 版のみ
| 変数 | デフォルト | 説明 |
|---|---|---|
| `VLLM_BASE_URL` | `http://host.docker.internal:8080` | チャット推論 |
| `VLLM_EMBED_BASE_URL` | `http://host.docker.internal:8081` | 埋め込み推論 |
| `VLLM_AUTO_START` | `false` | コンテナ側で vLLM を起動しない (host で管理) |
| `VLLM_CHAT_MODEL` | `Qwen/Qwen2.5-1.5B-Instruct` | API がアドレッシングに使う |

## Health check

`GET /health` が DB 到達可で 200 を返す。K8s liveness/readiness probe に利用可:

```yaml
livenessProbe:
  httpGet: { path: /health, port: 8000 }
  initialDelaySeconds: 30
readinessProbe:
  httpGet: { path: /health, port: 8000 }
  periodSeconds: 5
```

## 操作

```bash
docker logs db                                              # ログ
docker stop db                                              # 停止
docker start db                                             # 起動
docker pull lmlight/digitalbase:latest && docker restart db   # アップデート
```

- アクセス: http://localhost:8000
- 初回ログイン: `admin@local` / `admin123`

## 旧イメージ名から移行

| 旧 | 新 |
|---|---|
| `lmlight/lmlight-vite:latest` | `lmlight/digitalbase:latest` |
| `lmlight/lmlight-vllm-vite:latest` | `lmlight/digitalbase:latest` |

設定値・データ互換性あり、イメージ名差し替えで移行可。

---

## Kubernetes

本番・複数ノード・HA 構成向け。Helm チャートと Kustomize マニフェストの両方を同梱、3 モードから選択。

| モード | 用途 | 特徴 |
|---|---|---|
| `vllm-in-cluster` | クラスタ内 GPU ノード | `nvidia.com/gpu` ラベル必須、運用統合 |
| `vllm-external` | クラスタ外 GPU マシン | 既存 GPU 資産活用、ExternalName Service で名前解決 |
| `vllm-managed` | マネージド推論 API (Modal / RunPod / Anyscale) | GPU インフラ不要、OpenAI 互換 |

### Helm でインストール

```bash
kubectl create namespace digitalbase

# Postgres 認証情報
kubectl -n digitalbase create secret generic digitalbase-postgres-creds \
  --from-literal=POSTGRES_USER=digitalbase \
  --from-literal=POSTGRES_PASSWORD=$(openssl rand -hex 16) \
  --from-literal=POSTGRES_DB=digitalbase

# ライセンス
kubectl -n digitalbase create secret generic digitalbase-license \
  --from-file=license.lic=./license.lic

# モード B (外部 GPU) の例
helm install digitalbase ./deploy/helm/digitalbase -n digitalbase \
  --set image.edition=vllm \
  --set image.tag=1 \
  --set vllm.mode=external \
  --set vllm.external.chatUrl=http://gpu-host.internal:8080 \
  --set vllm.external.embedUrl=http://gpu-host.internal:8081
```

### Kustomize でインストール

```bash
kubectl apply -k deploy/k8s/overlays/vllm-external -n digitalbase
```

### 同梱ファイル

```
deploy/
├── PARTNER-GUIDE.md               # 配備ガイド (詳細版)
├── docker-hub-README.md           # Docker Hub 用 README
├── helm/digitalbase/              # Helm chart (3 モードを values で切替)
│   ├── Chart.yaml
│   ├── values.yaml                # 全設定項目
│   └── templates/                 # api / postgres / whisper / vllm
└── k8s/                           # Kustomize マニフェスト
    ├── README.md                  # K8s 構成選択ガイド
    ├── base/                      # postgres / whisper / api 共通
    └── overlays/                  # 3 モード分の overlay
        ├── vllm-in-cluster/
        ├── vllm-external/
        └── vllm-managed/
```

### よくある質問

**Q. GPU が無いクラスタでも動きますか？**
モード C (マネージド推論 API) を使えば GPU なしクラスタで動作。Modal / RunPod / Anyscale 等の OpenAI 互換エンドポイントを指定。

**Q. Postgres は外部の RDS / Cloud SQL を使えますか？**
`postgres.enabled=false` + `postgres.externalUrl=postgresql://...` で外部 DB 接続可。pgvector 拡張が必須。

**Q. ローリングアップデートできますか？**
API Pod は `RollingUpdate` 戦略、Postgres は PVC 制約上 `Recreate` 戦略。

**Q. SSO / OIDC 連携できますか？**
LDAP / OIDC 認証に対応。`OIDC_*` / `LDAP_*` 環境変数で設定。

**Q. ライセンスは Perpetual と Subscription どちらを使うべき？**
K8s / Docker 配備は **Subscription 推奨**。Pod 再スケジュール / スケールアウトで Hardware UUID が変動するため Perpetual だと構成上の制約大。
