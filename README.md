# DigitalBase 利用マニュアル

オンプレ AI 業務基盤。バックエンドは単一の `api`（API + frontend 同梱）に統合済みで、native は `~/.local/db` に1バイナリ、Docker は1イメージで配備。**Ollama / vLLM の切替は `.env` の `LLM_BACKEND` だけ**で決まり、運用コマンドは `db`（native）/ `db-docker`（Docker）に統一されています。

---

## 1. インストール方法

| 環境 | コマンド | backend | インストール先 |
|---|---|---|---|
| Linux | `install-linux.sh` | Ollama | `~/.local/db` |
| macOS | `install-macos.sh` | Ollama | `~/.local/db` |
| Windows | `install-windows.ps1` | Ollama | `%LOCALAPPDATA%\db` |
| Linux + GPU | `install-linux-vllm.sh` | vLLM | `~/.local/db` |
| Docker | `install-docker.sh` | Ollama / vLLM | `~/.local/db`（`/app/data` に mount） |
| Kubernetes | Docker Hub の image を pull | Ollama / vLLM | 任意（Secret + PVC） |

> native は単一バイナリ、Docker は単一 image。edition は `.env`（`LLM_BACKEND=ollama|vllm`）で決まる。

### Linux

```bash
curl -fsSL https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/vite-scripts/install-linux.sh | bash
```

依存: `sudo apt install -y postgresql postgresql-17-pgvector ffmpeg tesseract-ocr` + `curl -fsSL https://ollama.com/install.sh | sh`

### macOS

```bash
curl -fsSL https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/vite-scripts/install-macos.sh | bash
```

依存: `brew install postgresql@17 pgvector ollama ffmpeg tesseract`

### Windows

```powershell
irm https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/vite-scripts/install-windows.ps1 | iex
```

依存: PostgreSQL / pgvector / Ollama / FFmpeg / Tesseract（installer が自動 install）

### Linux + GPU (vLLM)

```bash
curl -fsSL https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/vite-scripts/install-linux-vllm.sh | bash
```

GPU 必須、初回起動時に HuggingFace から model download。native Ollama 版と**同じ `~/.local/db` / `db` コマンド**（統一バイナリ。`.env` の `LLM_BACKEND=vllm` で vLLM 動作）。

### Docker

```bash
# Ollama 版
curl -fsSL https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/vite-scripts/install-docker.sh | bash

# vLLM 版 (= EDITION を bash に渡す)
curl -fsSL https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/vite-scripts/install-docker.sh | EDITION=vllm bash
```

- データ実体は `~/.local/db`（= `db` dir）に置き、container の `/app/data` に mount。`.env` も同 dir。
- PostgreSQL(pgvector) を `digitalbase-postgres` container として同 network で同梱起動。
- 操作: `db-docker {start|stop|restart|logs|status|pull|upload-license}`。
- image: `lmlight/digitalbase:latest`（Docker Hub。Ollama / vLLM 共通、edition は `.env` の `LLM_BACKEND` で決まる）。

### Kubernetes

専用 chart は配布していません。Docker Hub の image を引いて、自前の manifest で配備してください（env は Secret/ConfigMap、`/app/data` は PVC）。

```
lmlight/digitalbase:latest
```

---

## 2. .env 設定

`.env` ファイル位置:
- Linux / macOS: `~/.local/db/.env`
- Windows: `%LOCALAPPDATA%\db\.env`
- Docker: `~/.local/db/.env`（`install-docker.sh` が自動生成）

### Linux / macOS / Windows (= Ollama 版)

| 環境変数 | 説明 | デフォルト |
|---|---|---|
| `LLM_BACKEND` | バックエンド種別 | `ollama` |
| `OLLAMA_BASE_URL` | Ollama サーバ URL | `http://localhost:11434` |
| `OLLAMA_AUTO_START` | 起動時 Ollama daemon を spawn | `true` (= install script default) |
| `LLM_CONTEXT_LENGTH` | context window 上限 (= 両 backend 共通) | 未設定 (model default) |
| `DATABASE_URL` | PostgreSQL 接続文字列 | install script が自動生成 |
| `LICENSE_FILE_PATH` | ライセンス path | `~/.local/db/license.lic` |
| `API_HOST` / `API_PORT` | bind / port | `0.0.0.0` / `8000` |
| `JWT_SECRET` | JWT 署名 (= 自動生成、再生成すると既存 session 無効) | install 時 random |
| `OAUTH_ENCRYPTION_KEY` | OAuth 連携 token の暗号化鍵 (= 変更すると既存連携が復号不能。再起動 / 再配置で固定必須) | Docker は自動生成 / native・k8s は手動設定 |
| `AUTH_MODE` | 認証: `local` / `ldap` / `oidc` | `local` |

### vLLM 版

| 環境変数 | 説明 | デフォルト |
|---|---|---|
| `LLM_BACKEND` | バックエンド種別 | `vllm` |
| `VLLM_BASE_URL` | chat server URL | `http://localhost:8080` |
| `VLLM_EMBED_BASE_URL` | embed server URL | `http://localhost:8081` |
| `VLLM_VISION_BASE_URL` | vision server URL (= 空なら chat 兼用) | (空) |
| `VLLM_AUTO_START` | 起動時 vLLM server も spawn | `true` |
| `VLLM_CHAT_MODEL` | chat model (HuggingFace ID) | `Qwen/Qwen3-4B` (= 4B / 32K context / ~8GB VRAM) |
| `VLLM_EMBED_MODEL` | embed model | `Qwen/Qwen3-Embedding-0.6B` |
| `VLLM_PYTHON` | vLLM venv の python path | `~/.local/db/venv/bin/python` |
| `VLLM_TENSOR_PARALLEL` | GPU 数 (= tensor parallel size) | `1` |
| `VLLM_GPU_MEMORY_UTILIZATION_CHAT` | chat GPU memory ratio (chat+embed 同 GPU 時) | `0.70` |
| `VLLM_GPU_MEMORY_UTILIZATION_EMBED` | embed GPU memory ratio | `0.10` |
| `LLM_CONTEXT_LENGTH` | context window (= `--max-model-len`) | 未設定 (model default = 32K) |
| `HF_HUB_OFFLINE` | `1` で network 不要 (= air-gapped、要 model 事前 cache) | (空) |

その他 (DB, License, JWT, AUTH) は Ollama 版と同じ。

### Docker 版

`install-docker.sh` が `.env` を自動生成。docker 特有の差分:

| 環境変数 | docker 特有設定 |
|---|---|
| `DATABASE_URL` | 同 docker network 内 PostgreSQL → `digitalbase-postgres:5432` |
| `OLLAMA_BASE_URL` | host の Ollama 参照 → `http://host.docker.internal:11434` |
| `OLLAMA_AUTO_START` | **`false` 必須** (= 1 container 1 process 原則、container 内 spawn 不可) |
| `VLLM_BASE_URL` | 外部 vLLM 参照 → `http://host.docker.internal:8080` |
| `VLLM_AUTO_START` | **`false` 必須** |
| `LICENSE_FILE_PATH` | image ENV 既定 → `/app/data/license.lic`（mount 経由） |
| `FILES_DIR` | image ENV 既定 → `/app/data/files`（mount 経由） |

Cloud LLM (= OpenAI / Anthropic / Gemini) 利用時はすべての版で:
```
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GEMINI_API_KEY=AIza...
```

---

## 3. ライセンス

**Hardware UUID 紐付け永続ライセンス** (= 1 device 1 license、有効期限なし、オフライン可)。

### Hardware UUID 取得

| OS | Command |
|---|---|
| macOS | `ioreg -d2 -c IOPlatformExpertDevice \| awk -F\\" '/IOPlatformUUID/{print $4}'` |
| Linux | `sudo cat /sys/class/dmi/id/product_uuid` |
| Windows | `(Get-CimInstance Win32_ComputerSystemProduct).UUID` |

### 配置

`license.lic` を取得後:
- Linux / macOS: `~/.local/db/license.lic`
- Windows: `%LOCALAPPDATA%\db\license.lic`
- Docker: `db-docker upload-license <license.lic>` または admin UI から upload
- Kubernetes: Secret を `/app/data/license.lic` に mount

---

## 4. 起動・停止 / アクセス

### コマンド

| Edition | start | stop | logs |
|---|---|---|---|
| Linux / macOS / Win (Ollama / vLLM) | `db start` | `db stop` | `db logs` |
| Docker | `db-docker start` | `db-docker stop` | `db-docker logs` |

### アクセス

- ローカル: http://localhost:8000
- LAN: 起動時に LAN IP 表示、他 PC / モバイルからアクセス可
- 初回ログイン: `admin@local` / `admin123` (= ログイン後パスワード変更必須)

---

## 5. アップデート

同じインストールコマンドを再実行 (= データ保持、`.env` 上書きしない)。

Docker は `db-docker pull && db-docker restart`。

---

## 6. アンインストール

```bash
# Linux / macOS (Ollama / vLLM 共通)
rm -rf ~/.local/db && sudo rm -f /usr/local/bin/db

# Docker
db-docker stop && docker rm digitalbase-app digitalbase-postgres
docker network rm digitalbase-net
rm -rf ~/.local/db
```

Windows:
```powershell
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\db"
```

---

## 7. 文字起こし (オプション)

```bash
# Linux / macOS
curl -fsSL https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/vite-scripts/install-transcribe.sh | bash

# Windows
irm https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/vite-scripts/install-transcribe.ps1 | iex
```

詳細: [TRANSCRIBE.md](TRANSCRIBE.md)

---

## 付録

### ディレクトリ構造

```
~/.local/db/                  # native / Docker 共通 (= data 実体)
├── api                       # binary (= API + frontend 同梱、native のみ)
├── .env                      # 設定
├── license.lic               # ライセンス
├── files/                    # ユーザ file
├── postgres-data/            # (Docker 版のみ) PG data
└── start.sh / stop.sh        # (native のみ)
```

Docker は上記 `~/.local/db` を container の `/app/data` に mount。

### Docker compose (= フルスタック 1 発起動)

詳細手順 + サンプル `docker-compose.yml`: [DOCKER.md](DOCKER.md)

### ネットワーク詳細 (= LAN / VPN / リバプロ 構成例)

[NETWORK.md](NETWORK.md)

### Troubleshooting

- **ライセンス認識されない (= "License required" 403)**: `LICENSE_FILE_PATH` の path 確認、Docker / k8s なら `/app/data/license.lic` に mount
- **Ollama 接続失敗 (= `connection refused`)**: `OLLAMA_AUTO_START=true` で daemon spawn される、または `ollama serve` を別途起動
- **vLLM 起動失敗 (= ModuleNotFoundError)**: vLLM venv に install 必須、`install-linux-vllm.sh` が venv 構築
- **embed が 404 / RAG が効かない**: `VLLM_EMBED_BASE_URL` が embed server (:8081) を指しているか確認 (= chat server :8080 は `/v1/embeddings` 非対応)
- **port 8000 衝突**: `.env` の `API_PORT` を変更 (= Docker は `APP_PORT=8001 db-docker start`)
- **チャットで 400 context error**: `LLM_CONTEXT_LENGTH` を model に合わせて設定 (= 例: Qwen3-4B なら `32768`)
