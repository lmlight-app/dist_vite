# DigitalBase Deployment Examples

動作確認済みのデプロイレシピ。`git clone` してそのまま使えます。

## 提供パターン

| ディレクトリ | 用途 | GPU | 一発起動 |
|---|---|---|---|
| [`docker-compose-vllm/`](docker-compose-vllm/) | NVIDIA GPU + 高スループット推論 | 必須 | ✅ `docker compose up -d` |
| [`docker-compose-ollama/`](docker-compose-ollama/) | 軽量、CPU 可、ホストで Ollama | 任意 | ✅ + Ollama を host で起動 |

K8s / Helm 用のマニフェストは、開発リポジトリ側の `deploy/k8s/` および `deploy/helm/` を参照してください。

## 使い方の基本

```bash
git clone https://github.com/lmlight-app/dist_vite.git
cd dist_vite/examples/<choose-one>
cp .env.example .env
nano .env                # 必須: POSTGRES_PASSWORD, JWT_SECRET
cp /path/to/license.lic .
docker compose up -d
```

各ディレクトリの README に詳細手順・トラブルシューティング・カスタマイズ方法があります。

## ライセンスについて

Docker / K8s 配備では **サブスクリプションライセンス**を使用してください（永年ライセンスは特定マシンの Hardware UUID に紐づくため、コンテナ環境では運用が困難）。

ライセンス入手は営業窓口へ。

## バイナリ単一サーバー版

開発・PoC・1 ノード本番なら PyInstaller 版がシンプル：

```bash
curl -fsSL https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/vite-scripts/install-linux-vllm.sh | bash
db-vllm start
```

詳細は [トップの README](../README.md) を参照。
