# DigitalBase 利用マニュアル

オンプレ AI 業務基盤。バックエンドは単一の `api`（API + frontend 同梱）に統合済みで、native は `~/.local/db` に1バイナリ、Docker は1イメージで配備。**vLLM / Ollama の切替は `.env` の `LLM_BACKEND` だけ**で決まります。運用は native が `db` コマンド、Docker は素の `docker`（コンテナ名 `digitalbase-app`）。

---

## 1. インストール方法

| 環境 | コマンド | backend | インストール先 |
|---|---|---|---|
| Linux | `install-linux.sh` | Ollama | `~/.local/db` |
| macOS | `install-macos.sh` | Ollama | `~/.local/db` |
| Windows | `install-windows.ps1` | Ollama | `%LOCALAPPDATA%\db` |
| Linux + GPU | `install-linux-vllm.sh` | vLLM | `~/.local/db` |
| Docker | `install-docker.sh` | vLLM / Ollama | `~/digitalbase`（`/app/data` に mount） |
| Kubernetes | Docker Hub の image を pull | vLLM / Ollama | 任意（Secret + PVC） |

> native は単一バイナリ、Docker は単一 image。edition は `.env`（`LLM_BACKEND=vllm|ollama`）で決まる（Docker / GPU は **vllm 既定**、native デスクトップは ollama）。

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

依存: PostgreSQL / Ollama / FFmpeg / Tesseract（installer が winget で導入。**管理者不要**で通常ユーザーのまま実行）

> **pgvector (RAG用)**: 自前ビルド（VC++ Redistributable 不要）を dist_vite Releases から自動配置します。ただし PostgreSQL の `lib` への配置に**管理者が必要**なため、非 admin で実行した場合は RAG が無効化されます（警告のみで続行）。その場合は管理者で再実行するか、**Docker 版（pgvector 同梱、admin 不要）** を利用してください。

### Linux (vLLM)

```bash
curl -fsSL https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/vite-scripts/install-linux-vllm.sh | bash
```

GPU 必須、初回起動時に HuggingFace から model download。native Ollama 版と**同じ `~/.local/db` / `db` コマンド**（統一バイナリ。`.env` の `LLM_BACKEND=vllm` で vLLM 動作）。

### Docker

Docker Hub で配布している単一イメージ `lmlight/digitalbase:latest` を使用します。vLLM 版・Ollama 版は共通のイメージで、エディションは `.env` の `LLM_BACKEND` によって切り替わります。PostgreSQL（pgvector）および LLM（vLLM / Ollama）はイメージに含まれないため、別途用意してください。

```bash
docker pull lmlight/digitalbase:latest
```

導入方法は次の2通りです。セットアップを自動化する「A. install-docker.sh」と、既存のインフラへ組み込む「B. 手動 docker run」のいずれかを選択します。

#### A. install-docker.sh（推奨）

イメージの取得、PostgreSQL（pgvector）コンテナとアプリケーションコンテナの起動、`.env` の生成までを自動で行います。

```bash
# vLLM 版（既定）
curl -fsSL https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/vite-scripts/install-docker.sh | bash

# Ollama 版
curl -fsSL https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/vite-scripts/install-docker.sh | EDITION=ollama bash
```

- データの実体は任意のディレクトリ（既定は `~/digitalbase`、`DB_INSTALL_DIR` で変更可能）に保存し、コンテナの `/app/data` にマウントします。`.env` も同じディレクトリに配置されます。
- PostgreSQL（pgvector）を `digitalbase-postgres` コンテナとして、同一ネットワーク上に同時に起動します。
- 起動・停止・ログの確認には標準の `docker` コマンドを使用します（`docker logs -f digitalbase-app` / `docker stop digitalbase-app` / `docker start digitalbase-app`）。
- スクリプトが自動で行う処理は次のとおりです。① イメージの取得（`docker pull`）、② `~/digitalbase/.env` の生成（`JWT_SECRET` / `OAUTH_ENCRYPTION_KEY` を含む）、③ ネットワーク `digitalbase-net` の作成、④ PostgreSQL（pgvector）コンテナの起動と `digitalbase` ユーザー・データベースの作成（拡張の有効化はアプリケーションが自動実行）、⑤ アプリケーションコンテナの起動（`docker run`）、⑥ ライセンスファイル配置の案内。

#### B. 手動 docker run（既存インフラへの組み込み）

上記 A の処理のうち ①③④⑥ を手動で行う方法です。前提として、pgvector を導入済みの PostgreSQL（RAG 用）と、vLLM（ポート 8080 / 8081）または Ollama（ポート 11434）を用意してください。

拡張の有効化（`CREATE EXTENSION vector`）およびスキーマ・テーブルの作成は、アプリケーションの起動時に自動で実行されます。pgvector 0.5 以降は trusted extension であるため、データベースの所有者である `digitalbase` ユーザーでも実行でき、スーパーユーザーは不要です（実行に失敗した場合は警告のみを出力し、RAG を無効化したうえで起動を継続します）。ただし、ユーザーとデータベースの作成だけは、事前にスーパーユーザーで行う必要があります（アプリケーションはユーザー・データベース自体を作成できません）。

PostgreSQL は、次のいずれかの方法で用意します。

```bash
# 方法1: PostgreSQL を別途用意しない場合は、pgvector 同梱イメージで起動する
#        （ユーザー・データベースも環境変数から自動的に作成される）
docker run -d --name digitalbase-postgres --restart unless-stopped \
  -e POSTGRES_USER=digitalbase -e POSTGRES_PASSWORD=digitalbase -e POSTGRES_DB=digitalbase \
  -p 5432:5432 -v "$PWD/pgdata":/var/lib/postgresql/data \
  pgvector/pgvector:pg16

# 方法2: 既存の PostgreSQL を使用する場合は、pgvector を導入し、ユーザーとデータベースを作成する
#        （拡張の有効化はアプリケーションの起動時に自動で実行される）
#    sudo apt install postgresql-17-pgvector   # または brew install pgvector など
#    psql -U postgres -c "CREATE USER digitalbase WITH PASSWORD 'digitalbase';"
#    psql -U postgres -c "CREATE DATABASE digitalbase OWNER digitalbase;"
```

続いて、アプリケーションを起動します。

```bash
mkdir digitalbase && cd digitalbase
cat > .env <<EOF
LLM_BACKEND=vllm
DATABASE_URL=postgresql://digitalbase:digitalbase@host.docker.internal:5432/digitalbase
VLLM_BASE_URL=http://host.docker.internal:8080
VLLM_EMBED_BASE_URL=http://host.docker.internal:8081
JWT_SECRET=$(openssl rand -hex 32)
OAUTH_ENCRYPTION_KEY=$(openssl rand -hex 32)
AUTH_MODE=local
EOF
cp /path/to/license.lic ./license.lic

docker run -d --name digitalbase-app \
  -p 8000:8000 \
  --env-file .env \
  -v "$PWD":/app/data \
  --add-host=host.docker.internal:host-gateway \
  --restart unless-stopped \
  lmlight/digitalbase:latest
```

スキーマ・テーブル・初期管理者ユーザーの作成、および pgvector 拡張の有効化は、アプリケーションの起動時に自動で実行されます（PostgreSQL に pgvector が導入済みであることのみが前提です）。起動後、http://localhost:8000 にアクセスし、`admin@local` / `admin123` でログインしてください。Ollama 版を使用する場合は、`.env` を `LLM_BACKEND=ollama` および `OLLAMA_BASE_URL=http://host.docker.internal:11434` に変更します。

> データベースの所有者以外のユーザーで接続しており `CREATE EXTENSION` に失敗する場合のみ、スーパーユーザーで一度 `CREATE EXTENSION vector` を実行してください。

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
- Docker: `~/digitalbase/.env`（`install-docker.sh` が自動生成、`DB_INSTALL_DIR` で変更可）

### vLLM 版（= 既定の前提。GPU / Docker）

| 環境変数 | 説明 | デフォルト |
|---|---|---|
| `LLM_BACKEND` | バックエンド種別 | `vllm` |
| `VLLM_BASE_URL` | chat server URL | `http://localhost:8080` |
| `VLLM_EMBED_BASE_URL` | embed server URL | `http://localhost:8081` |
| `VLLM_VISION_BASE_URL` | vision server URL (= 空なら chat 兼用) | (空) |
| `VLLM_AUTO_START` | 起動時 vLLM server も spawn | `true`（Docker は `false`） |
| `VLLM_CHAT_MODEL` | chat model (HuggingFace ID) | `Qwen/Qwen3-4B` (= 4B / 32K context / ~8GB VRAM) |
| `VLLM_EMBED_MODEL` | embed model | `Qwen/Qwen3-Embedding-0.6B` |
| `VLLM_PYTHON` | vLLM venv の python path | `~/.local/db/venv/bin/python` |
| `VLLM_TENSOR_PARALLEL` | GPU 数 (= tensor parallel size) | `1` |
| `VLLM_GPU_MEMORY_UTILIZATION_CHAT` | chat GPU memory ratio (chat+embed 同 GPU 時) | `0.70` |
| `VLLM_GPU_MEMORY_UTILIZATION_EMBED` | embed GPU memory ratio | `0.10` |
| `LLM_CONTEXT_LENGTH` | context window (= `--max-model-len`、両 backend 共通) | 未設定 (model default = 32K) |
| `HF_HUB_OFFLINE` | `1` で network 不要 (= air-gapped、要 model 事前 cache) | (空) |
| `DATABASE_URL` | PostgreSQL 接続文字列 | install script が自動生成 |
| `LICENSE_FILE_PATH` | ライセンス path | `~/.local/db/license.lic`（Docker: `/app/data/license.lic`） |
| `API_HOST` / `API_PORT` | bind / port | `0.0.0.0` / `8000` |
| `JWT_SECRET` | JWT 署名 (= 自動生成、再生成すると既存 session 無効) | install 時 random |
| `OAUTH_ENCRYPTION_KEY` | OAuth 連携 token の暗号化鍵 (= 変更すると既存連携が復号不能。固定必須) | install 時 random（native は手動も可） |
| `AUTH_MODE` | 認証: `local` / `ldap` / `oidc` | `local` |

### Ollama 版（native デスクトップ: Linux / macOS / Windows）

| 環境変数 | 説明 | デフォルト |
|---|---|---|
| `LLM_BACKEND` | バックエンド種別 | `ollama` |
| `OLLAMA_BASE_URL` | Ollama サーバ URL | `http://localhost:11434` |
| `OLLAMA_AUTO_START` | 起動時 Ollama daemon を spawn | `true`（Docker は `false`） |

その他（DB / License / JWT / OAUTH / AUTH / API / LLM_CONTEXT_LENGTH）は vLLM 版と同じ。

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

## 3. データベース

インストーラ（`install-*.sh`）が触る DB は **bootstrap のみ**（superuser でしかできない 3 つ）:

- DB ユーザー作成（`digitalbase`）
- データベース作成（`digitalbase`、owner = 同ユーザー）
- pgvector 拡張の有効化（`CREATE EXTENSION vector`。失敗時は RAG を無効化して続行）

> 接続情報は `.env` の `DATABASE_URL` で変更可。既存 PostgreSQL / RDS 等に向ける場合はここを書き換える（その場合 DBA に上記 3 つを依頼）。

**schema / table / index / 初期 admin user は backend 初回起動時に `migrations.py` が冪等に自動作成**します（アップデート時の列追加・移行も自動。再 install してもデータは保持）。**手動操作は不要。**

schema 構成: `public`（主要 entity）/ `approval` / `helpdesk` / `vision` / `log` / `datalake` / `pgvector`

前提: **PostgreSQL が起動していること**（停止中は bootstrap がスキップされる）。DBA 管理 / air-gapped で table まで事前投入したい場合のみ `db_setup.sh` を superuser で実行（user/DB/拡張 + 全 schema・table・index を一括投入）。

---

## 4. ライセンス

### 配置

`license.lic` を取得後:
- Linux / macOS: `~/.local/db/license.lic`
- Windows: `%LOCALAPPDATA%\db\license.lic`
- Docker: `~/digitalbase/license.lic` に置いて `docker restart digitalbase-app`、または admin UI から upload
- Kubernetes: Secret を `/app/data/license.lic` に mount

---

## 5. 起動・停止 / アクセス

### コマンド

| Edition | start | stop | logs |
|---|---|---|---|
| Linux / macOS / Win (vLLM / Ollama) | `db start` | `db stop` | `db logs` |
| Docker (`digitalbase-app`) | `docker start digitalbase-app` | `docker stop digitalbase-app` | `docker logs -f digitalbase-app` |

### アクセス

- ローカル: http://localhost:8000
- LAN: 起動時に LAN IP 表示、他 PC / モバイルからアクセス可
- 初回ログイン: `admin@local` / `admin123` (= ログイン後パスワード変更必須)

---

## 6. アップデート

同じインストールコマンドを再実行 (= データ保持、`.env` 上書きしない)。

Docker は `docker pull lmlight/digitalbase:latest` → install を再実行（container 作り直し、data は volume 保持）。

---

## 7. アンインストール

```bash
# Linux / macOS (vLLM / Ollama 共通)
rm -rf ~/.local/db && sudo rm -f /usr/local/bin/db

# Docker
docker rm -f digitalbase-app digitalbase-postgres
docker network rm digitalbase-net
rm -rf ~/digitalbase
```

Windows:
```powershell
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\db"
```

---

## 8. 文字起こし (オプション)

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
~/.local/db/                  # native の data 実体 (Docker は ~/digitalbase)
├── api                       # binary (= API + frontend 同梱、native のみ)
├── .env                      # 設定
├── license.lic               # ライセンス
├── files/                    # ユーザ file
├── postgres-data/            # (Docker 版のみ) PG data
└── start.sh / stop.sh        # (native のみ)
```
