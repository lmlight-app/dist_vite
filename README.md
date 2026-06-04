# DigitalBase 利用マニュアル



## Ollamaバージョン

### インストール | アップデート

#### macOS

```bash
curl -fsSL https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/vite-scripts/install-macos.sh | bash
```

#### Linux

```bash
curl -fsSL https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/vite-scripts/install-linux.sh | bash
```

#### Windows

```powershell
irm https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/vite-scripts/install-windows.ps1 | iex
```

---

インストール先:
- macOS/Linux: `~/.local/db`
- Windows: `%LOCALAPPDATA%\db`

## 環境構築 (インストール前に実行)

### 必要な依存関係

#### macOS

PostgreSQL 17, pgvector, Ollama, FFmpeg, Tesseract OCR

```bash
brew install postgresql@17 pgvector ollama ffmpeg tesseract
```

#### Linux (Ubuntu/Debian)

PostgreSQL, FFmpeg, Tesseract OCR, Ollama

```bash
sudo apt install -y postgresql ffmpeg tesseract-ocr
```

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

**pgvector:** インストール済みの PostgreSQL バージョンに合わせてインストールしてください。

```bash
# PostgreSQL のバージョン確認
psql --version

# バージョンに合わせてインストール (例: PG17 の場合)
sudo apt install -y postgresql-17-pgvector
```

#### Windows

PostgreSQL 17, Ollama, FFmpeg, Tesseract OCR

```powershell
winget install PostgreSQL.PostgreSQL.17 Ollama.Ollama Gyan.FFmpeg UB-Mannheim.TesseractOCR
```

> **Note:** pgvector はインストーラーが自動でセットアップします。

### データベース

インストーラーは **DB ユーザー / データベース / pgvector 拡張** だけを作成します (= superuser でないと作れないため)。
スキーマ・テーブル・インデックス・初期管理ユーザーは **バックエンド初回起動時に自動作成**されます (= 冪等)。
アップデート時も既存データは保持されます。

#### 手動セットアップが必要なケース

通常は不要ですが、以下の場合は手動で `db_setup.sh` を実行してください:

| 状況 | 対応 |
|---|---|
| バックエンド起動時に **権限エラーで table が作れない** | DBA に superuser 権限で `db_setup.sh` を実行してもらう |
| **air-gapped 環境** で DB だけ事前に用意したい | 同上 |
| バックエンドが起動できず schema を手で投入したい | 同上 |

**実行方法 (= superuser として):**

```bash
# macOS/Linux
curl -fsSL https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/vite-scripts/db_setup.sh | bash
```

このスクリプトは DB ユーザー / データベース / pgvector に加えて、全スキーマ・テーブル・インデックスを raw SQL で一括投入します。
実行後はバックエンドを起動するだけで利用可能です。

#### データベース削除

```bash
psql -U postgres -c "DROP DATABASE digitalbase;"
# その後インストーラーを再実行 (= バックエンド起動時に再構築されます)
```

### Ollamaモデル

[Ollama モデル一覧](https://ollama.com/search) から好みのモデルを選択:

```bash
ollama pull <model_name>        # 例: gemma3:4b, llama3.2, qwen2.5 など
ollama pull nomic-embed-text    # RAG用埋め込みモデル (推奨)
```

### 設定ファイル (.env)

インストール後、`.env` を編集:
- macOS/Linux: `~/.local/db/.env`
- Windows: `%LOCALAPPDATA%\db\.env`

| 環境変数 | 説明 | デフォルト |
|---------|------|-----------|
| `DATABASE_URL` | PostgreSQL接続URL | `postgresql://digitalbase:digitalbase@localhost:5432/digitalbase` |
| `OLLAMA_BASE_URL` | OllamaサーバーURL | `http://localhost:11434` |
| `LICENSE_FILE_PATH` | ライセンスファイルのパス | `~/.local/db/license.lic` |
| `API_HOST` | バインドアドレス | `0.0.0.0` (全インターフェース) |
| `API_PORT` | ポート (API + Web) | `8000` |
| `JWT_SECRET` | JWT認証シークレット | インストーラーが自動生成 |
| `AUTH_MODE` | 認証方式 (local/ldap/oidc) | `local` |

**ネットワーク設定:**
- `API_HOST` を `0.0.0.0` に設定すると、同じLAN内の他のPCからアクセス可能
- `127.0.0.1` に設定すると、同じマシンからのみアクセス可能（セキュリティ強化）

※ インストーラーが自動設定します。手動変更が必要な場合のみ編集してください。

### 文字起こし機能 (オプション)

音声ファイルをテキストに変換する機能です。詳細は [TRANSCRIBE.md](TRANSCRIBE.md) を参照。

```bash
# macOS / Linux
curl -fsSL https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/vite-scripts/install-transcribe.sh | bash
```

```powershell
# Windows
irm https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/vite-scripts/install-transcribe.ps1 | iex
```

### ライセンス (Perpetual License)

**ライセンス方式**: Hardware UUIDベース永続ライセンス

- デバイスのHardware UUIDに紐付けられた永続ライセンス
- 有効期限なし
- オフライン・オンプレミス環境での利用に最適
- 1ライセンス = 1デバイス

#### Hardware UUID 取得方法

**macOS:**
- 設定 → 一般 → 情報 → システムレポート → ハードウェア → 「ハードウェアUUID」
- またはターミナルで: `ioreg -d2 -c IOPlatformExpertDevice | awk -F\" '/IOPlatformUUID/{print $4}'`

**Windows:**
- PowerShellで: `(Get-CimInstance Win32_ComputerSystemProduct).UUID`

**Linux:**
- ターミナルで: `sudo cat /sys/class/dmi/id/product_uuid` または `sudo dmidecode -s system-uuid`

#### ライセンスファイル配置

`license.lic` を下記に配置:

- macOS/Linux: `~/.local/db/license.lic`
- Windows: `%LOCALAPPDATA%\db\license.lic`


## 起動・停止

**macOS / Linux:**
```bash
db start   # 起動
db stop    # 停止
```

**Windows:**
```powershell
db start   # 起動
db stop    # 停止
```

## アクセス

### ローカルアクセス（同じPC）

- http://localhost:8000

### LANアクセス（他のPC・スマホ・タブレット）

起動時に表示される LAN IP アドレスを使用してください：

```
✅ Started - http://localhost:8000
🌐 LAN: http://192.168.1.100:8000
```

**IP アドレスの確認方法:**
- macOS: `ifconfig | grep "inet "`
- Linux: `ip addr show`
- Windows: `ipconfig`

**ネットワーク接続の詳細:** [NETWORK.md](NETWORK.md) を参照

### デフォルトログイン

`admin@local` / `admin123`

※ 初回ログイン後、パスワードを変更してください

## アップデート

同じインストールコマンドを再実行 (データは保持)

## アンインストール

**macOS:**
```bash
rm -rf ~/.local/db
sudo rm -f /usr/local/bin/db
```

**Linux:**
```bash
rm -rf ~/.local/db
sudo rm -f /usr/local/bin/db
```

**Windows (PowerShell):**

```powershell
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\db"
$p = [Environment]::GetEnvironmentVariable("Path", "User") -split ";" | Where-Object { $_ -notlike "*\db" -and $_ -notlike "*\db\*" }
[Environment]::SetEnvironmentVariable("Path", ($p -join ";"), "User")
```

## ディレクトリ構造

```
~/.local/db/
├── api                    # バイナリ (API + フロントエンド一体型)
├── models/whisper/        # 文字起こしモデル (オプション)
├── .env                   # 設定ファイル
├── license.lic            # ライセンス (Hardware UUIDベース)
├── start.sh               # 起動
├── stop.sh                # 停止
```

---

## vLLMバージョン

### インストール | アップデート (Linux のみ)

```bash
curl -fsSL https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/vite-scripts/install-linux-vllm.sh | bash
```

インストール先: `~/.local/db-vllm`

### 必要な依存関係

| 依存関係 | インストール |
|---------|------------|
| PostgreSQL | `sudo apt install postgresql` |
| uv (Python パッケージマネージャー) | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| FFmpeg (文字起こし用) | `sudo apt install ffmpeg` |
| Tesseract OCR | `sudo apt install tesseract-ocr tesseract-ocr-jpn` |


**pgvector:**

```bash
psql --version
sudo apt install -y postgresql-17-pgvector
```

### 設定ファイル (.env)

`~/.local/db-vllm/.env` を編集:

| 環境変数 | 説明 | デフォルト |
|---------|------|-----------|
| `DATABASE_URL` | PostgreSQL接続URL | `postgresql://digitalbase:digitalbase@localhost:5432/digitalbase` |
| `VLLM_BASE_URL` | vLLMチャットサーバーURL | `http://localhost:8080` |
| `VLLM_EMBED_BASE_URL` | vLLM埋め込みサーバーURL | `http://localhost:8081` |
| `VLLM_AUTO_START` | vLLM自動起動 | `true` |
| `VLLM_CHAT_MODEL` | チャットモデル (HuggingFace ID) | `Qwen/Qwen2.5-1.5B-Instruct` |
| `VLLM_EMBED_MODEL` | 埋め込みモデル | `intfloat/multilingual-e5-large-instruct` |
| `API_HOST` | バインドアドレス | `0.0.0.0` |
| `API_PORT` | ポート (API + Web) | `8000` |
| `JWT_SECRET` | JWT認証シークレット | インストーラーが自動生成 |
| `AUTH_MODE` | 認証方式 | `local` |
| `LICENSE_FILE_PATH` | ライセンスファイル | `~/.local/db-vllm/license.lic` |

### 起動・停止

```bash
db-vllm start   # 起動
db-vllm stop    # 停止
```

---

## Docker版

Docker Hub で公開。API + UI を 1 コンテナに同梱、`linux/amd64` / `linux/arm64` 両対応。

| イメージ | LLM バックエンド | 推奨用途 |
|---|---|---|
| `lmlight/digitalbase-ollama:latest` | Ollama | CPU/GPU 混在、軽量モデル中心 (≤7B) |
| `lmlight/digitalbase-vllm:latest` | vLLM | NVIDIA GPU、高スループット、マルチテナント |


### 前提条件

| 必須 | 用途 |
|---|---|
| Docker (Desktop / Engine) | container 実行 |
| **PostgreSQL 16+ + pgvector 拡張** (host or 別 container) | DB |
| Ollama (Ollama 版のみ、host or 別 container) | LLM 推論 |
| NVIDIA GPU + nvidia-container-toolkit (vLLM 版のみ) | GPU 推論 |

### Step 1: PostgreSQL の bootstrap (= 初回のみ)

DigitalBase 用に **user / database / extension** を作成します。superuser 権限で実行:

```bash
# macOS (= host の postgres を使う場合)
psql -U postgres <<'SQL'
CREATE USER digitalbase WITH PASSWORD 'digitalbase';
CREATE DATABASE digitalbase OWNER digitalbase;
ALTER USER digitalbase CREATEDB;
\c digitalbase
CREATE EXTENSION IF NOT EXISTS vector;
SQL

# Linux
sudo -u postgres psql <<'SQL'
CREATE USER digitalbase WITH PASSWORD 'digitalbase';
CREATE DATABASE digitalbase OWNER digitalbase;
ALTER USER digitalbase CREATEDB;
\c digitalbase
CREATE EXTENSION IF NOT EXISTS vector;
SQL
```

> `digitalbase` 以外の DB 名/ユーザー名を使う場合は、後述の `DATABASE_URL` で合わせて変更します。

### Step 2: 作業ディレクトリと `.env` 作成 (= 初回のみ、secret を固定化)

任意のディレクトリを 1 つ作り、その中に `.env` と `license.lic` を置きます (compose 版と同じ流儀。`~/.local/db` 等の固定パスである必要はありません)。

`JWT_SECRET` / `OAUTH_ENCRYPTION_KEY` は **container 再作成時に値が変わると既存データが復号不能** になります。`.env` に保存して再利用してください。

**Ollama 版:**

```bash
mkdir digitalbase && cd digitalbase

cat > .env <<EOF
DATABASE_URL=postgresql://digitalbase:digitalbase@host.docker.internal:5432/digitalbase
OLLAMA_BASE_URL=http://host.docker.internal:11434
OLLAMA_CONTEXT_LENGTH=16384
JWT_SECRET=$(openssl rand -hex 32)
OAUTH_ENCRYPTION_KEY=$(openssl rand -hex 32)
AUTH_MODE=local
EOF
chmod 600 .env

cp /path/to/license.lic ./license.lic
```

**vLLM 版:**

```bash
mkdir digitalbase-vllm && cd digitalbase-vllm

cat > .env <<EOF
DATABASE_URL=postgresql://digitalbase:digitalbase@host.docker.internal:5432/digitalbase
VLLM_BASE_URL=http://host.docker.internal:8080
VLLM_EMBED_BASE_URL=http://host.docker.internal:8081
VLLM_AUTO_START=false
JWT_SECRET=$(openssl rand -hex 32)
OAUTH_ENCRYPTION_KEY=$(openssl rand -hex 32)
AUTH_MODE=local
EOF
chmod 600 .env

cp /path/to/license.lic ./license.lic
```

### Step 3: container 起動 (= Step 2 で作ったディレクトリ内で実行)

**Ollama 版:**

```bash
docker pull lmlight/digitalbase-ollama:latest

docker run -d \
  --name db \
  -p 8000:8000 \
  --env-file .env \
  -v "$PWD":/app/data \
  --restart unless-stopped \
  lmlight/digitalbase-ollama:latest
```

**vLLM 版:**

```bash
docker pull lmlight/digitalbase-vllm:latest

docker run -d \
  --name db-vllm \
  -p 8000:8000 \
  --env-file .env \
  -v "$PWD":/app/data \
  --restart unless-stopped \
  lmlight/digitalbase-vllm:latest
```

> `docker run` 単体では vLLM 本体は別途起動する必要があります 

container 起動時に **DB schema / table / index / 初期 admin user は自動作成** されます
アクセス: http://localhost:8000、初回ログイン: `admin@local` / `admin123`。

### フルスタックで一発起動 (docker-compose)

`docker compose up -d` で **API + Postgres + Whisper + vLLM (chat/embed)** が同時起動します。
GPU は `nvidia-container-toolkit` 経由で自動マウント。

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
      # 起動時に digitalbase DB に pgvector 拡張を有効化
      - ./init-pgvector.sql:/docker-entrypoint-initdb.d/init-pgvector.sql:ro
    restart: unless-stopped

  whisper:
    image: onerahmet/openai-whisper-asr-webservice:latest
    environment:
      ASR_MODEL: base
      ASR_ENGINE: openai_whisper
    ports: ["9000:9000"]
    restart: unless-stopped

  # ── vLLM chat 推論サーバー (vLLM 版のときだけ。Ollama 版は削除) ──
  vllm-chat:
    image: vllm/vllm-openai:latest
    command:
      - --model=google/gemma-4-E2B-it
      - --max-model-len=4096
      - --gpu-memory-utilization=0.55
    volumes:
      - ${HOME}/.cache/huggingface:/root/.cache/huggingface   # モデル DL キャッシュ共有
    deploy:
      resources:
        reservations:
          devices:
            - { driver: nvidia, count: 1, capabilities: [gpu] }
    restart: unless-stopped

  # ── vLLM embedding サーバー (RAG / pgvector 用) ──
  vllm-embed:
    image: vllm/vllm-openai:latest
    command:
      - --model=google/embeddinggemma-300m
      - --task=embed
      - --max-model-len=2048
      - --gpu-memory-utilization=0.35
    volumes:
      - ${HOME}/.cache/huggingface:/root/.cache/huggingface
    deploy:
      resources:
        reservations:
          devices:
            - { driver: nvidia, count: 1, capabilities: [gpu] }
    restart: unless-stopped

  api:
    image: lmlight/digitalbase-vllm:latest   # Ollama 版なら lmlight/digitalbase-ollama:latest
    env_file: .env
    volumes:
      - ./license.lic:/app/data/license.lic:ro
    ports: ["8000:8000"]
    extra_hosts:
      - "host.docker.internal:host-gateway"
    depends_on: [postgres, whisper, vllm-chat, vllm-embed]   # Ollama 版は vllm-* を消す
    restart: unless-stopped

volumes:
  pgdata:
```

**`init-pgvector.sql` を同じディレクトリに作成** (pgvector 拡張の初期化):

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

最小 `.env`:

```bash
DATABASE_URL=postgresql://digitalbase:digitalbase@postgres:5432/digitalbase
WHISPER_API_URL=http://whisper:9000
JWT_SECRET=change-me-to-random-secret
OAUTH_ENCRYPTION_KEY=random
AUTH_MODE=local

# vLLM 版 — 同じ compose 内の vllm-chat / vllm-embed Service を参照
VLLM_BASE_URL=http://vllm-chat:8000
VLLM_EMBED_BASE_URL=http://vllm-embed:8000
VLLM_AUTO_START=false
VLLM_CHAT_MODEL=google/gemma-4-E2B-it
VLLM_EMBED_MODEL=google/embeddinggemma-300m

# Ollama 版は VLLM_* を消して以下を追加 (host で起動した Ollama を参照)
# OLLAMA_BASE_URL=http://host.docker.internal:11434
```

```bash
docker compose up -d      # 起動（初回は vLLM のモデル DL に数分かかります）
docker compose logs -f    # ログ確認
docker compose down       # 停止
```

> **GPU が無い場合**: vLLM 版は使えません。Ollama 版に切替えるか、Modal / RunPod 等のマネージド推論 API を `VLLM_BASE_URL` に指定してください。

> **`docker compose ps` で vllm-chat が "unhealthy" になる**: 初回起動はモデル DL + ロードで 1〜3 分かかります。`docker compose logs vllm-chat` で進捗確認。完了するまで `api` の `/health` も 503 を返します。

### 操作

```bash
docker logs db                               # ログ
docker stop db                               # 停止
docker start db                              # 起動
```

#### アップデート

**Ollama 版:**

```bash
cd digitalbase   # Step 2 で作ったディレクトリ
docker pull lmlight/digitalbase-ollama:latest
docker stop db && docker rm db
docker run -d \
  --name db \
  -p 8000:8000 \
  --env-file .env \
  -v "$PWD":/app/data \
  --restart unless-stopped \
  lmlight/digitalbase-ollama:latest
```

**vLLM 版:**

```bash
cd digitalbase-vllm   # Step 2 で作ったディレクトリ
docker pull lmlight/digitalbase-vllm:latest
docker stop db-vllm && docker rm db-vllm
docker run -d \
  --name db-vllm \
  -p 8000:8000 \
  --env-file .env \
  -v "$PWD":/app/data \
  --restart unless-stopped \
  lmlight/digitalbase-vllm:latest
```

> **`.env` を再利用するので JWT_SECRET / OAUTH_ENCRYPTION_KEY は不変** = 既存ユーザー認証 token + 暗号化 connection 設定がそのまま使えます。

- アクセス: http://localhost:8000
- 初回ログイン: `admin@local` / `admin123`

---

#### Docker でのライセンス mount

```yaml
volumes:
  - ./license.lic:/app/data/license.lic:ro   # ← コンテナ内のパスは /app/data/license.lic
```

コンテナ内パスは `/app/license.lic` ではなく **`/app/data/license.lic`**。間違えると「License required」エラーで 403 拒否されます。
