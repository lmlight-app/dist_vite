#!/bin/bash
# LM Light — Docker Installation (Ollama Edition)
# Usage: curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_vite/main/scripts/install-docker.sh | bash
set -e

DOCKER_USER="lmlight"
IMAGE="$DOCKER_USER/lmlight-vite:latest"
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
    cat > "$DATA_DIR/.env" <<EOF
DATABASE_URL=postgresql://digitalbase:digitalbase@host.docker.internal:5432/digitalbase
OLLAMA_BASE_URL=http://host.docker.internal:11434
JWT_SECRET=$JWT_SECRET
AUTH_MODE=local
EOF
    echo "📝 Created $DATA_DIR/.env"
    echo "   Edit this file to configure database and Ollama settings."
fi

# Setup database
echo "🗄️ Setting up database..."
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_vite/main/scripts/db_setup.sh | bash

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
