# LM Light 利用マニュアル (Vite Edition)

> **Vite Edition**: Node.js不要。バイナリ1つでAPI + フロントエンドが動作します。

## セットアップ

このリポジトリはprivateです。インストールにはGitHub Personal Access Token (PAT) が必要です。

```bash
export GH_TOKEN="ghp_your_token_here"
```

## Ollamaバージョン

### インストール | アップデート

#### macOS

```bash
curl -fsSL -H "Authorization: token $GH_TOKEN" \
  https://raw.githubusercontent.com/lmlight-app/dist_vite/main/scripts/install-macos.sh | bash
```

#### Linux

```bash
curl -fsSL -H "Authorization: token $GH_TOKEN" \
  https://raw.githubusercontent.com/lmlight-app/dist_vite/main/scripts/install-linux.sh | bash
```

#### Windows

```powershell
$env:GH_TOKEN = "ghp_your_token_here"
$h = @{ Authorization = "token $env:GH_TOKEN" }
iex (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/lmlight-app/dist_vite/main/scripts/install-windows.ps1" -Headers $h).Content
```

#### Staging (GitHub Releases直接、R2昇格前のテスト用)

```bash
# macOS
LMLIGHT_BASE_URL=https://github.com/lmlight-app/dist_vite/releases/latest/download \
  curl -fsSL -H "Authorization: token $GH_TOKEN" \
  https://raw.githubusercontent.com/lmlight-app/dist_vite/main/scripts/install-macos.sh | bash

# Linux
LMLIGHT_BASE_URL=https://github.com/lmlight-app/dist_vite/releases/latest/download \
  curl -fsSL -H "Authorization: token $GH_TOKEN" \
  https://raw.githubusercontent.com/lmlight-app/dist_vite/main/scripts/install-linux.sh | bash
```

---

インストール先:
- macOS/Linux: `~/.local/lmlight`
- Windows: `%LOCALAPPDATA%\lmlight`

## 環境構築 (インストール前に実行)

### 必要な依存関係

> **Note:** Vite EditionではNode.jsは不要です。

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

> **⚠️ [Visual C++ Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/) が必須です。** pgvector のビルドに必要です。

PostgreSQL 17, Ollama, FFmpeg, Tesseract OCR

```powershell
winget install PostgreSQL.PostgreSQL.17 Ollama.Ollama Gyan.FFmpeg UB-Mannheim.TesseractOCR
```

pgvector は [手動インストール](https://github.com/pgvector/pgvector#windows) が必要です。

### データベース

インストーラーがDB作成・テーブル作成・初期ユーザー作成を自動実行します。

データベースのみを手動実行:

```bash
# macOS/Linux
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_vite/main/scripts/db_setup.sh | bash
```

**データベース削除:**
```bash
psql -U postgres -c "DROP DATABASE lmlight;"
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
- macOS/Linux: `~/.local/lmlight/.env`
- Windows: `%LOCALAPPDATA%\lmlight\.env`

| 環境変数 | 説明 | デフォルト |
|---------|------|-----------|
| `DATABASE_URL` | PostgreSQL接続URL | `postgresql://lmlight:lmlight@localhost:5432/lmlight` |
| `OLLAMA_BASE_URL` | OllamaサーバーURL | `http://localhost:11434` |
| `LICENSE_FILE_PATH` | ライセンスファイルのパス | `~/.local/lmlight/license.lic` |
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
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_vite/main/scripts/install-transcribe.sh | bash
```

```powershell
# Windows
irm https://raw.githubusercontent.com/lmlight-app/dist_vite/main/scripts/install-transcribe.ps1 | iex
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

- macOS/Linux: `~/.local/lmlight/license.lic`
- Windows: `%LOCALAPPDATA%\lmlight\license.lic`


## 起動・停止

**macOS / Linux:**
```bash
lmlight start   # 起動
lmlight stop    # 停止
```

**Windows:**
```powershell
lmlight start   # 起動
lmlight stop    # 停止
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
rm -rf ~/.local/lmlight
sudo rm -f /usr/local/bin/lmlight
```

**Linux:**
```bash
rm -rf ~/.local/lmlight
sudo rm -f /usr/local/bin/lmlight
```

**Windows (PowerShell):**

```powershell
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\lmlight"
$p = [Environment]::GetEnvironmentVariable("Path", "User") -split ";" | Where-Object { $_ -notlike "*lmlight*" }
[Environment]::SetEnvironmentVariable("Path", ($p -join ";"), "User")
```

## ディレクトリ構造

```
~/.local/lmlight/
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
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_vite/main/scripts/install-linux-vllm.sh | bash
```

インストール先: `~/.local/lmlight-vllm`

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

`~/.local/lmlight-vllm/.env` を編集:

| 環境変数 | 説明 | デフォルト |
|---------|------|-----------|
| `DATABASE_URL` | PostgreSQL接続URL | `postgresql://lmlight:lmlight@localhost:5432/lmlight` |
| `VLLM_BASE_URL` | vLLMチャットサーバーURL | `http://localhost:8080` |
| `VLLM_EMBED_BASE_URL` | vLLM埋め込みサーバーURL | `http://localhost:8081` |
| `VLLM_AUTO_START` | vLLM自動起動 | `true` |
| `VLLM_CHAT_MODEL` | チャットモデル (HuggingFace ID) | `Qwen/Qwen2.5-1.5B-Instruct` |
| `VLLM_EMBED_MODEL` | 埋め込みモデル | `intfloat/multilingual-e5-large-instruct` |
| `API_HOST` | バインドアドレス | `0.0.0.0` |
| `API_PORT` | ポート (API + Web) | `8000` |
| `JWT_SECRET` | JWT認証シークレット | インストーラーが自動生成 |
| `AUTH_MODE` | 認証方式 | `local` |
| `LICENSE_FILE_PATH` | ライセンスファイル | `~/.local/lmlight-vllm/license.lic` |

### 起動・停止

```bash
lmlight-vllm start   # 起動
lmlight-vllm stop    # 停止
```

---

## Docker版

Docker Compose を使ったデプロイ。PostgreSQL (pgvector) も含まれるため、DB の個別インストールは不要です。

### docker-compose.yml

```yaml
services:
  postgres:
    image: pgvector/pgvector:pg16
    environment:
      POSTGRES_USER: lmlight
      POSTGRES_PASSWORD: lmlight
      POSTGRES_DB: lmlight
    volumes:
      - pgdata:/var/lib/postgresql/data
    restart: unless-stopped

  api:
    image: lmlight/lmlight-vite:latest
    env_file: .env
    volumes:
      - ./license.lic:/app/license.lic:ro
    ports:
      - "8000:8000"
    extra_hosts:
      - "host.docker.internal:host-gateway"
    depends_on:
      - postgres
    restart: unless-stopped

volumes:
  pgdata:
```

### .env

```bash
DATABASE_URL=postgresql://lmlight:lmlight@postgres:5432/lmlight
OLLAMA_BASE_URL=http://host.docker.internal:11434
API_PORT=8000
API_HOST=0.0.0.0
JWT_SECRET=change-me-to-random-secret
AUTH_MODE=local
LICENSE_FILE_PATH=/app/license.lic
```

### 起動

```bash
docker compose up -d      # 起動
docker compose logs -f    # ログ確認
docker compose down       # 停止
```

- アクセス: http://localhost:8000
- 初回ログイン: `admin@local` / `admin123`

> **Note:** Vite Editionではフロントエンドコンテナは不要です。APIコンテナ1つで完結します。

---

## ライセンス比較

| 項目 | Subscription | Perpetual |
|------|---------------------|---------------------|
| ライセンスチェック | 有効期限 | Hardware UUID |
| ライセンスタイプ | サブスクリプション | 永続 |
