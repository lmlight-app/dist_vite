#!/bin/bash
# LM Light — Docker Installation (vLLM Edition)
# Usage: curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_vite/main/scripts/install-docker-vllm.sh | bash
set -e

DOCKER_USER="lmlight"
IMAGE="$DOCKER_USER/lmlight-vllm-vite:latest"
CONTAINER_NAME="db-vllm"

echo "🚀 Installing LM Light (Docker - vLLM Edition)"
echo ""

# Check Docker
if ! command -v docker &>/dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    echo "   https://docs.docker.com/get-docker/"
    exit 1
fi

# Check NVIDIA Docker runtime
if ! docker info 2>/dev/null | grep -q nvidia; then
    echo "⚠️  NVIDIA Container Toolkit not detected."
    echo "   vLLM requires NVIDIA GPU. Install: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/"
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
DATA_DIR="$HOME/.local/db-vllm"
mkdir -p "$DATA_DIR"

# Generate JWT secret if not exists
if [ ! -f "$DATA_DIR/.env" ]; then
    JWT_SECRET=$(openssl rand -hex 32)
    cat > "$DATA_DIR/.env" <<EOF
DATABASE_URL=postgresql://digitalbase:digitalbase@host.docker.internal:5432/digitalbase
VLLM_BASE_URL=http://localhost:8080
VLLM_EMBED_BASE_URL=http://localhost:8081
VLLM_AUTO_START=true
JWT_SECRET=$JWT_SECRET
AUTH_MODE=local
EOF
    echo "📝 Created $DATA_DIR/.env"
fi

# Setup database
echo "🗄️ Setting up database..."
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_vite/main/scripts/db_setup.sh | bash

# Run container with GPU
echo "🐳 Starting container (GPU enabled)..."
docker run -d \
    --name "$CONTAINER_NAME" \
    --gpus all \
    --env-file "$DATA_DIR/.env" \
    -p 8000:8000 \
    -v "$DATA_DIR:/app/data" \
    -v "$HOME/.cache/huggingface:/root/.cache/huggingface" \
    --restart unless-stopped \
    "$IMAGE"

echo ""
echo "✅ LM Light (vLLM) is running!"
echo "   http://localhost:8000"
echo ""
echo "Note: First run will download models from HuggingFace (~3GB)."
echo "      Models are cached at ~/.cache/huggingface/hub/"
echo ""
echo "Commands:"
echo "  docker logs $CONTAINER_NAME          # View logs"
echo "  docker stop $CONTAINER_NAME          # Stop"
echo "  docker start $CONTAINER_NAME         # Start"
echo "  docker pull $IMAGE && docker restart $CONTAINER_NAME  # Update"
