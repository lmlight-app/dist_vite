#!/bin/bash
# DigitalBase — Docker Installation (Ollama Edition)
# Usage: curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_vite/main/scripts/install-docker.sh | bash
#
# 手動セットアップする場合は templates/example.env を参照:
#   https://github.com/lmlight-app/dist_vite/blob/main/templates/example.env
set -e

DOCKER_USER="lmlight"
IMAGE="$DOCKER_USER/digitalbase-ollama:1"
CONTAINER_NAME="db"

echo "🚀 Installing LM Light (Docker - Ollama Edition)"
echo ""

# Check Docker
if ! command -v docker &>/dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    echo "   https://docs.docker.com/get-docker/"
    exit 1
fi

# Pull latest image
echo "📦 Pulling latest image..."
docker pull "$IMAGE"

# Stop existing container
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "🔄 Stopping existing container..."
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
fi

# Create data directory
DATA_DIR="$HOME/.local/db"
mkdir -p "$DATA_DIR"

# Generate JWT secret if not exists
if [ ! -f "$DATA_DIR/.env" ]; then
    JWT_SECRET=$(openssl rand -hex 32)
    OAUTH_KEY=$(openssl rand -hex 32)
    cat > "$DATA_DIR/.env" <<EOF
DATABASE_URL=postgresql://digitalbase:digitalbase@host.docker.internal:5432/digitalbase
OLLAMA_BASE_URL=http://host.docker.internal:11434
# Ollama daemon の num_ctx (default 2048 → 16384)、ホスト ollama serve に別途設定要
OLLAMA_CONTEXT_LENGTH=16384
JWT_SECRET=$JWT_SECRET
OAUTH_ENCRYPTION_KEY=$OAUTH_KEY
AUTH_MODE=local
EOF
    chmod 600 "$DATA_DIR/.env"
    echo "📝 Created $DATA_DIR/.env"
    echo "   Edit this file to configure database and Ollama settings."
fi

# License file check (なくても起動はする、ただし API は 403 を返す)
if [ ! -f "$DATA_DIR/license.lic" ]; then
    echo "⚠️  License file not found at $DATA_DIR/license.lic"
    echo "   Place your license file there to activate the API."
fi

# ── DB bootstrap (= ホスト側 Postgres に user/DB/extension 作成) ────────────
# schema / table / index / column / 初期 admin は container 起動後 migrations.py
# が冪等に作成する。psql コマンドはホストの postgres で実行。
echo "🗄️ Setting up database (bootstrap only)..."
DB_USER="digitalbase"
DB_PASS="digitalbase"
DB_NAME="digitalbase"

if ! command -v psql &>/dev/null; then
    echo "❌ PostgreSQL がインストールされていません (= host 側に必要)。"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "   brew install postgresql@16 && brew services start postgresql@16"
    else
        echo "   sudo apt install postgresql && sudo systemctl start postgresql"
    fi
    exit 1
fi
if ! pg_isready -q 2>/dev/null; then
    echo "❌ PostgreSQL に接続できません (host:5432)。起動してから再実行してください。"
    exit 1
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
    PSQL_ADMIN="psql -U postgres"
else
    PSQL_ADMIN="sudo -u postgres psql"
fi
$PSQL_ADMIN -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';" 2>/dev/null || true
$PSQL_ADMIN -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" 2>/dev/null || true
$PSQL_ADMIN -c "ALTER USER $DB_USER CREATEDB;" 2>/dev/null || true
if ! $PSQL_ADMIN -d $DB_NAME -c "CREATE EXTENSION IF NOT EXISTS vector;" >/dev/null 2>&1; then
    echo "⚠️  pgvector 拡張の有効化に失敗 (= RAG は無効になります)"
fi
echo "✅ DB bootstrap 完了 (= schemas / tables は container 起動時に自動作成)"

# Run container
echo "🐳 Starting container..."
docker run -d \
    --name "$CONTAINER_NAME" \
    --env-file "$DATA_DIR/.env" \
    -p 8000:8000 \
    -v "$DATA_DIR:/app/data" \
    --restart unless-stopped \
    "$IMAGE"

echo ""
echo "✅ LM Light is running!"
echo "   http://localhost:8000"
echo ""
echo "Commands:"
echo "  docker logs $CONTAINER_NAME          # View logs"
echo "  docker stop $CONTAINER_NAME          # Stop"
echo "  docker start $CONTAINER_NAME         # Start"
echo "  docker pull $IMAGE && docker restart $CONTAINER_NAME  # Update"
