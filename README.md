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

インストーラーがDB作成・テーブル作成・初期ユーザー作成を自動実行します。

データベースのみを手動実行:

```bash
# macOS/Linux
curl -fsSL https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/vite-scripts/db_setup.sh | bash
```

**データベース削除:**
```bash
psql -U postgres -c "DROP DATABASE digitalbase;"
# その後、上記のdb_setupを再実行
```

※ アップデート時も既存データは保持されます

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
└── logs/                  # ログ
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

> **Note:** Node.js は不要です。NVIDIA GPU + CUDA 12.x 以上が必要です。

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
| `lmlight/digitalbase-ollama:1` | Ollama | CPU/GPU 混在、軽量モデル中心 (≤7B) |
| `lmlight/digitalbase-vllm:1` | vLLM | NVIDIA GPU、高スループット、マルチテナント |

タグ運用:

| タグ | 追従 | 推奨 |
|---|---|---|
| `1.2.3` | 完全固定 | **本番** |
| `1.2`   | パッチ追従 | ステージング |
| `1`     | マイナー追従 | 互換確認 |
| `latest`| 全追従 | 開発・お試し |

### Ollama版

```bash
docker pull lmlight/digitalbase-ollama:1

docker run -d \
  --name db \
  -p 8000:8000 \
  -e DATABASE_URL=postgresql://digitalbase:digitalbase@host.docker.internal:5432/digitalbase \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  -e JWT_SECRET=$(openssl rand -hex 32) \
  -e AUTH_MODE=local \
  -v ~/.local/db/license.lic:/app/license.lic:ro \
  --restart unless-stopped \
  lmlight/digitalbase-ollama:1
```

### vLLM版（GPU）

vLLM サーバー本体はコンテナ外で運用 (GPU メモリ制御が容易)。コンテナは API だけ。

```bash
docker pull lmlight/digitalbase-vllm:1

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
  lmlight/digitalbase-vllm:1
```

### Postgres / Whisper も一緒に起動 (docker-compose)

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
    image: lmlight/digitalbase-vllm:1   # Ollama 版なら lmlight/digitalbase-ollama:1
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

最小 `.env`:

```bash
DATABASE_URL=postgresql://digitalbase:digitalbase@postgres:5432/digitalbase
WHISPER_API_URL=http://whisper:9000
JWT_SECRET=change-me-to-random-secret
AUTH_MODE=local

# vLLM 版
VLLM_BASE_URL=http://host.docker.internal:8080
VLLM_EMBED_BASE_URL=http://host.docker.internal:8081
VLLM_AUTO_START=false

# Ollama 版は VLLM_* を消して以下を追加
# OLLAMA_BASE_URL=http://host.docker.internal:11434
```

```bash
docker compose up -d      # 起動
docker compose logs -f    # ログ確認
docker compose down       # 停止
```

### 操作

```bash
docker logs db                                                    # ログ
docker stop db                                                    # 停止
docker start db                                                   # 起動
docker pull lmlight/digitalbase-ollama:1 && docker restart db     # アップデート
```

- アクセス: http://localhost:8000
- 初回ログイン: `admin@local` / `admin123`

> **Note:** フロントエンドコンテナは不要、API コンテナ 1 つで完結。

### 旧イメージ名から移行

| 旧 | 新 |
|---|---|
| `lmlight/lmlight-vite:latest` | `lmlight/digitalbase-ollama:1` |
| `lmlight/lmlight-vllm-vite:latest` | `lmlight/digitalbase-vllm:1` |

設定値・データ互換性あり、イメージ名差し替えで移行可。

---

## Kubernetes版 (Helm / Kustomize)

本番・複数ノード・HA 構成向け。GPU 配置によって 3 モードから選択。

| モード | 用途 | 特徴 |
|---|---|---|
| `vllm-in-cluster` | クラスタ内 GPU ノード | 統合運用、`nvidia.com/gpu` ラベル必須 |
| `vllm-external` | クラスタ外 GPU マシン | 既存 GPU 資産活用、ExternalName Service で名前解決 |
| `vllm-managed` | マネージド推論 API (Modal / RunPod / Anyscale 等) | GPU インフラ不要、OpenAI 互換エンドポイント |

### Helm でインストール (例: 外部 GPU モード)

```bash
kubectl create namespace digitalbase

# Postgres 認証情報
kubectl -n digitalbase create secret generic digitalbase-postgres-creds \
  --from-literal=POSTGRES_USER=digitalbase \
  --from-literal=POSTGRES_PASSWORD=$(openssl rand -hex 16) \
  --from-literal=POSTGRES_DB=digitalbase

# ライセンスファイル
kubectl -n digitalbase create secret generic digitalbase-license \
  --from-file=license.lic=./license.lic

# Helm install
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
├── helm/digitalbase/              # Helm chart (3 モードを values で切替)
│   ├── Chart.yaml
│   ├── values.yaml                # 全設定項目
│   └── templates/                 # api / postgres / whisper / vllm
└── k8s/                           # Kustomize マニフェスト
    ├── base/                      # postgres / whisper / api 共通部
    └── overlays/                  # 3 モード分の overlay
        ├── vllm-in-cluster/
        ├── vllm-external/
        └── vllm-managed/
```

詳細は配布パッケージ内の [PARTNER-GUIDE.md](deploy/PARTNER-GUIDE.md) を参照。

### システム要件 (Pod ごとの目安)

| Pod | CPU 推奨 | メモリ推奨 | ストレージ |
|---|---|---|---|
| API + UI | 2 core | 2 GB | 5 GB |
| Postgres + pgvector | 2 core | 4 GB | 50 GB+ (RAG 量に依存) |
| Whisper (任意) | 4 core | 6 GB | base モデル 74 MB |
| vLLM (in-cluster 時) | – | – | VRAM 4-24 GB (モデルサイズ依存) |

vLLM の VRAM 目安:

| モデル | VRAM | GPU 例 |
|---|---|---|
| 1〜2B | 4 GB+ | T4 / RTX 4060 |
| 4B | 8 GB+ | RTX 4070 / L4 |
| 7〜9B | 16 GB+ | RTX 4080 / A10G |
| 13〜30B (量子化) | 24 GB+ | RTX 4090 / A100 40GB |

`gpu_memory_utilization` を 0.55 (chat) + 0.35 (embed) = 0.90 に分割すると 1 GPU で chat + embedding 共存可。

---

## ライセンス比較

| 項目 | Subscription | Perpetual |
|------|---------------------|---------------------|
| ライセンスチェック | 有効期限 | Hardware UUID |
| ライセンスタイプ | サブスクリプション | 永続 |
| 推奨配備 | **Docker / K8s** | バイナリ単体 (1 ノード) |

> **K8s / Docker 配備は Subscription 推奨**: Pod 再スケジュール / スケールアウトで Hardware UUID が変動するため、Perpetual だと構成上の制約大。Subscription なら任意ノードで起動可、ローリングアップデートも問題なし。
