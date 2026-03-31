# Docker

## Ollama版

```bash
docker pull lmlight/lmlight-vite:latest

docker run -d \
  --name lmlight \
  -p 8000:8000 \
  -e DATABASE_URL=postgresql://digitalbase:digitalbase@host.docker.internal:5432/digitalbase \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  -e JWT_SECRET=your-secret-here \
  -e AUTH_MODE=local \
  lmlight/lmlight-vite:latest
```

## vLLM版（GPU）

```bash
docker pull lmlight/lmlight-vllm-vite:latest

docker run -d \
  --name lmlight-vllm \
  --gpus all \
  -p 8000:8000 \
  -e DATABASE_URL=postgresql://digitalbase:digitalbase@host.docker.internal:5432/digitalbase \
  -e VLLM_BASE_URL=http://localhost:8080 \
  -e VLLM_EMBED_BASE_URL=http://localhost:8081 \
  -e VLLM_AUTO_START=true \
  -e JWT_SECRET=your-secret-here \
  -e AUTH_MODE=local \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  lmlight/lmlight-vllm-vite:latest
```

## 操作

```bash
docker logs lmlight           # ログ
docker stop lmlight            # 停止
docker start lmlight           # 起動
docker pull lmlight/lmlight-vite:latest && docker restart lmlight  # 更新
```

## DB準備

PostgreSQLが必要です。別コンテナで起動する場合:

```bash
docker run -d \
  --name postgres \
  -p 5432:5432 \
  -e POSTGRES_USER=digitalbase \
  -e POSTGRES_PASSWORD=digitalbase \
  -e POSTGRES_DB=digitalbase \
  -v pgdata:/var/lib/postgresql/data \
  postgres:16
```
