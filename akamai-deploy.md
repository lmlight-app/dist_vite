# DigitalBase — Akamai Cloud 構築ガイド（PoC / 検証環境）

Akamai Cloud（旧 Linode）上に DigitalBase を構築するための手順書。
**「使うときだけ GPU インスタンスを起動し、終わったら削除して課金を止める。ファイルと SQL データは残す」** という PoC 運用を前提にする。

---

## 0. 構成の方針

- **compute（GPU インスタンス）＝使い捨て**。停止＝削除でしか課金は止まらないので、検証していない間は削除する。
- **データ（ファイル・PostgreSQL・モデルキャッシュ・`.env`）＝ Block Storage Volume に置いて永続化**。インスタンスを削除しても残る（ストレージ代のみ）。
- アプリは Docker / 単一バイナリで自己完結。LLM は **vLLM**（GPU）。既定モデル `Qwen3-4B`(~8GB) は **RTX 4000 Ada(20GB) に余裕で載る**。

### アーキテクチャ

```
┌──────────────── GPU インスタンス（使い捨て）────────────────┐
│  OS / NVIDIA driver / Docker / vLLM venv / app バイナリ      │
│                                                             │
│   DigitalBase app ──▶ vLLM (chat:8080 / embed:8081)  ← GPU  │
│         │                                                   │
│         └──▶ PostgreSQL(pgvector) コンテナ                  │
└───────────────────────────│────────────────────────────────┘
                            │ -v マウント
        ┌───────────────────▼────────────────────┐
        │  Block Storage Volume  /mnt/db （永続） │
        │   ├─ postgres-data/   ← SQL            │
        │   ├─ files/           ← アップロード     │
        │   ├─ hf-cache/        ← モデル          │
        │   ├─ .env                              │
        │   └─ license.lic                       │
        └────────────────────────────────────────┘
```

---

## インフラ要件（OS / GPU / vLLM のバージョン）

DigitalBase の vLLM 版は **native venv 実行が既定**で、host の CUDA に合わせて vLLM / PyTorch を自動選択する（インストーラ内で `uv pip install vllm --torch-backend=auto`）。vLLM 専用の Docker イメージは使わない。

| 項目 | 指定 | 備考 |
|---|---|---|
| OS | **Ubuntu 24.04 LTS** | Python 3.12 が標準。インストーラは `uv venv --python 3.12` |
| GPU ドライバ | **CUDA 13 対応（driver ≥ 580）** | Blackwell は CUDA 12.8+ 必須 → **13 推奨**。Ada は 12.x でも可 |
| CUDA Toolkit | **13.x（cu130）** | インストーラは CUDA≥13 で `ptxas` を使い Triton JIT を最適化（`TRITON_PTXAS_PATH`）。`/usr/local/cuda/bin/ptxas` が要る |
| Python | **3.12** | venv 固定 |
| vLLM / PyTorch | **最新 vLLM + 付属 torch（自動選択）** | `--torch-backend=auto` が host CUDA に合う wheel を入れる。**torch を個別導入しない** |
| Container runtime | **Docker + NVIDIA Container Toolkit** | PostgreSQL コンテナ用（vLLM を container で動かす場合も） |

### 使用イメージ（Docker Hub）

| 用途 | イメージ | タグ |
|---|---|---|
| PostgreSQL(pgvector) | `pgvector/pgvector` | **`pg16`**（固定。data dir 再利用のため勝手に上げない） |
| アプリ | `lmlight/digitalbase` | `latest` |
| vLLM（Docker で動かす代替構成のみ） | `vllm/vllm-openai` | CUDA 13 対応タグ（native venv 既定では不要） |

> **Akamai の GPU イメージ選定時**は driver / CUDA バージョンを確認すること。Blackwell を使うなら **CUDA 13 / driver 580+** のイメージが必須。「この GPU プランの既定 driver / CUDA は何か」を Akamai に確認する。

### 環境の2パターン（CUDA の出どころで分岐）

本ガイドは **native 実行**を前提（compose は使わない）。**vLLM + app の構築手順（§2）は両パターンで共通**で、違いは CUDA を誰が用意するかだけ。

1. **Akamai の GPU インスタンス** — driver + CUDA は **Akamai が供給**（Ada=プリインストール / Blackwell=cloud-init）。そのまま §2 へ。
2. **自前 NVIDIA 環境**（GMI / 他クラウド / 自社 GPU など） — **先に driver + CUDA 13 を導入**してから、§2 と同一手順:
   ```bash
   sudo apt install -y nvidia-driver-580 cuda-toolkit-13   # 環境に応じて
   nvidia-smi                                              # CUDA 13.x を確認
   ```
   以降は §2 と全く同じ（`install-linux-vllm.sh` が CUDA に自動追従）。

> Akamai では①、GMI のように素ホストから立てる場合は②。手順本体は変わらないので、運用は1本に保てる。

---

## 1. インスタンス選定

| 用途 | プラン | GPU | $/時 | $/月* | 備考 |
|---|---|---|---|---|---|
| **PoC / Tier2** | RTX 4000 Ada x1 (Small/Medium) | 20GB | **$0.52〜** | $350〜 | `Qwen3-4B` + embed が載る。**大阪**提供中。余剰在庫あり |
| 中規模 | RTX 4000 Ada x1 Large | 20GB | $0.96 | $638 | 64GB RAM / 16 vCPU |
| **Tier3 / 大型モデル** | RTX PRO 6000 Blackwell x1 | 96GB | $2.50 | $1,665 | 35B 級・FT 向け。東京/大阪 |

`*` 2026年7月に価格体系の変更予定（月額上限の廃止）。**契約前に最新単価を要確認**。

- **PoC は Ada 一択**（安い・余ってる・既定モデルにジャスト）。Blackwell は大型モデルを試す数時間だけ。
- ストレージ: **Block Storage $0.10/GB/月**（例 50GB = $5/月）。これが「インスタンス削除中も残る」常時コスト。

---

## 2. 初回構築

### 2-1. Block Storage Volume

1. Cloud Manager で **Block Storage Volume** を作成（大阪、例 50GB）。
2. GPU インスタンスにアタッチ → マウント。

```bash
# Volume を /mnt/db にマウント（デバイス名は環境で確認）
sudo mkfs.ext4 /dev/disk/by-id/scsi-0Linode_Volume_<name>   # ← 初回のみ
sudo mkdir -p /mnt/db
sudo mount /dev/disk/by-id/scsi-0Linode_Volume_<name> /mnt/db
# 再起動・restore 後も自動マウント（nofail=Volume 無しでも boot を止めない）
echo "/dev/disk/by-id/scsi-0Linode_Volume_<name> /mnt/db ext4 defaults,noatime,nofail 0 2" | sudo tee -a /etc/fstab
```

### 2-2. GPU インスタンス（Ubuntu 24.04 / 大阪）

Akamai の **GPU 対応イメージ**（NVIDIA driver 導入済み）を選ぶ。**CUDA 13 / driver 580+** であることを確認する。

```bash
nvidia-smi                       # GPU と CUDA Version を確認（13.x 推奨）
ls /usr/local/cuda/bin/ptxas     # Triton JIT 用。無ければ CUDA Toolkit を導入
# 要件を満たさない場合のみ: sudo apt install -y cuda-toolkit-13 nvidia-driver-580
```

> bare-metal native では **Docker は不要**（PostgreSQL はホストに入れる）。Docker-PG を選ぶ場合のみ §4 末尾の代替構成で導入する。

### 2-3. PostgreSQL(pgvector) — ホスト導入 + データを Volume に移設

**ここが永続化のキモ。** apt の既定だと PG データは `/var/lib/postgresql/16/main`（＝インスタンスのローカルディスク）に作られ、**インスタンス削除で消える**。`data_directory` を `/mnt/db/pgdata` に移すことで Volume に残る。**この設定は Image に焼けるので初回1回だけ**。

```bash
# 1) PostgreSQL + pgvector + OCR を apt で
sudo apt install -y postgresql postgresql-16-pgvector tesseract-ocr tesseract-ocr-jpn

# 2) ★ データ領域を Volume へ移設（これが無いと teardown で SQL が消える）
sudo systemctl stop postgresql
sudo mv /var/lib/postgresql/16/main /mnt/db/pgdata
sudo sed -i "s|^#\?data_directory.*|data_directory = '/mnt/db/pgdata'|" \
  /etc/postgresql/16/main/postgresql.conf

# 3) /mnt/db マウント後に PG が上がるよう順序保証
sudo mkdir -p /etc/systemd/system/postgresql@16-main.service.d
printf '[Unit]\nRequiresMountsFor=/mnt/db\n' | \
  sudo tee /etc/systemd/system/postgresql@16-main.service.d/mnt.conf
sudo systemctl daemon-reload && sudo systemctl start postgresql

# 4) 移設確認
sudo -u postgres psql -c "SHOW data_directory;"   # → /mnt/db/pgdata なら成功
```

> `RequiresMountsFor=/mnt/db` により、再起動・restore 時も **Volume マウント後に PG が自動起動**する。拡張有効化（`CREATE EXTENSION vector`）は次のインストーラ or アプリ起動時に自動。

### 2-4. vLLM + アプリ（native / GPU）

vLLM の auto-start を含むので、**native の vLLM インストーラ**を使う。インストーラが **Python 3.12 venv を作り、`uv pip install vllm --torch-backend=auto` で host の CUDA に合う vLLM / PyTorch を導入**する（バージョンは固定せず CUDA に自動追従）。データとモデルを Volume に向ける。

```bash
# DB_INSTALL_DIR を Volume に向けて実行（app バイナリ・venv・.env・files が /mnt/db に入る）
DB_INSTALL_DIR=/mnt/db \
  curl -fsSL https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/vite-scripts/install-linux-vllm.sh | bash
```

`/mnt/db/.env` を調整:

```bash
LLM_BACKEND=vllm
# ホストの PostgreSQL（localhost:5432）に向ける
DATABASE_URL=postgresql://digitalbase:digitalbase@localhost:5432/digitalbase
# モデルキャッシュを Volume に（再起動・再構築時の再ダウンロードを回避）
HF_HOME=/mnt/db/hf-cache
# 既定モデル（Ada 20GB に収まる）
VLLM_CHAT_MODEL=Qwen/Qwen3-4B
VLLM_EMBED_MODEL=Qwen/Qwen3-Embedding-0.6B
VLLM_AUTO_START=true
```

> ホストに PostgreSQL がある状態なので、**インストーラの PG bootstrap（user/DB 作成・`CREATE EXTENSION vector`）がそのまま走る**。スキーマ/テーブルは起動時の migrations.py が冪等に作成。

### 2-5. ライセンスと起動

```bash
cp /path/to/license.lic /mnt/db/license.lic
db start          # vLLM を spawn し、app を起動
```

- 初回はモデルを HuggingFace から DL（`/mnt/db/hf-cache` に保存）。
- アクセス: `http://<インスタンスIP>:8000` → `admin@local` / `admin123`。
- 公開する場合は Akamai の **Cloud Firewall** で 8000 を絞る／LB を前段に置く。

### 2-6. ★ この状態を Image に保存

動作確認できたら、**この一式（PG＋設定・NVIDIA driver/CUDA・vLLM venv・app バイナリ）を Image 化**しておく。以後の restore で再インストールが不要になる。

Cloud Manager → `digitalbase-gpu` → 「…」→ **Create Image** → ラベル例 `digitalbase-gpu-base`。

- サイズ目安 **5〜8GB（$0.50〜0.80/月）**。
- **DB データ実体（`/mnt/db/pgdata`）・モデルキャッシュ（`/mnt/db/hf-cache`）は Volume 側**なのでイメージに含まれない（含める必要もない）。

---

## 3. 課金停止（teardown）

検証が終わったら、**データを残してインスタンスを削除**する。

```bash
db stop
sudo systemctl stop postgresql    # PG をクリーンに停止（次回 crash recovery を避ける）
sync
# Cloud Manager で：インスタンスを削除（Volume は自動 detach され、残る）
```

- 残るもの: `/mnt/db`（pgdata / files / hf-cache / .env / license）、Block Storage Volume、（保存した場合）Image。
- 残コスト: **Block Storage 代**（例 50GB = $5/月）＋（Image 保存時）**~$0.5〜0.8/月**。GPU compute は $0。

---

## 4. 再開（restore）

**§2-6 の Image** から起動し、**作成時に既存 Volume をアタッチ**しておけば、fstab が自動マウント → PG 自動起動 → あとは `db start` だけ。

```bash
# 1) Cloud Manager: Images → digitalbase-gpu-base → Deploy to new Linode
#    リージョン=大阪 / プラン=RTX4000 Ada / ★ 作成時に既存 Volume をアタッチ
# 2) 起動するだけ（fstab が /mnt/db を自動マウント、PG も自動起動）
db start
```

- **モデルは `/mnt/db/hf-cache` から即ロード**（再 DL 不要）、**DB は `/mnt/db/pgdata` からそのまま**。
- Image 込みなら再インストール / cloud-init ゼロ → **数分で前回状態に復帰**。

> Volume を**作成後に**アタッチした場合は手動で:
> `sudo mount -a && sudo systemctl start postgresql && db start`

### （代替構成）Docker-PG を使う場合

bare-metal が使えない事情（既存インフラとの兼ね合い等）があれば Docker-PG に戻す。Volume 永続化は `-v` 1行で済むが、restore で `docker run` が要る。

```bash
# Docker + NVIDIA Container Toolkit
curl -fsSL https://get.docker.com | sh
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker && sudo systemctl restart docker

# PostgreSQL コンテナ（データは Volume）
docker run -d --name digitalbase-postgres --restart unless-stopped \
  -e POSTGRES_USER=digitalbase -e POSTGRES_PASSWORD=digitalbase -e POSTGRES_DB=digitalbase \
  -p 5432:5432 -v /mnt/db/postgres-data:/var/lib/postgresql/data pgvector/pgvector:pg16
# この場合 install-linux-vllm.sh の PG bootstrap は空振り(|| true)。restore は mount + 上の docker run + db start。
```

| | Docker-PG | bare-metal native（推奨） |
|---|---|---|
| Volume 永続化 | `-v` 1行 | `data_directory` 移設（初回1回・Image に焼ける） |
| Docker | 要 | 不要 |
| restore | mount + docker run + db start | **mount + db start** |

---

## 5. コストモデル（目安・GPU なし期間も含む）

| 使い方 | Block(50GB) | GPU compute | 月合計 |
|---|---|---|---|
| 保持のみ（インスタンス削除中） | $5 | $0 | **約 $5** |
| 週2回×5h デモ（Ada, 40h/月） | $5 | ~$21（$0.52×40） | **約 $26** |
| 常時起動（Ada 24/7） | $5 | $350 | $355 |

GPU を「使うときだけ」にすれば、保持コストは月 $5 前後に収まる。

---

## 6. PoC で測る・残すこと

**技術検証**
- [ ] `Qwen3-4B` のモデルロード時間 / tokens/sec / 同時接続
- [ ] RAG（pgvector）の検索レイテンシ、file upload → embedding → 検索の一連
- [ ] フルスタック疎通（PostgreSQL / 認証 / API / BiKey）
- [ ] **teardown → restore を一度通す**（この運用の実証）
- [ ] Egress 実測（Akamai は $0.005/GB）
- [ ] （任意）Blackwell で 35B 級を短時間

**営業資産化**
- [ ] 上記の **性能＋実コスト**を「DigitalBase on Akamai」リファレンス／顧客向けコストモデルに

---

## 7. Akamai と詰めること

- **GPU 在庫 / quota のコミット**（本番スケール時の供給）
- **2026年7月の価格改定後の単価**
- **ISV / スタートアップ プログラムと追加クレジット**（PoC 後の継続枠）
- 保険会社型のローカル LLM 事例の **co-marketing**、エンプラ AE 紹介
- マーケットプレイス掲載（「Akamai で DigitalBase を起動」ブループリント）

---

## 8. 注意点

- **Ada 20GB の上限**: 既定の 4B/8B + embed は載るが、上位 `Qwen3.5-35B-A3B`(>24GB) は載らない → Tier3 は Blackwell 前提でコスト再計算。
- **PostgreSQL のメジャーバージョン固定**: `pgvector/pgvector:pg16` のまま。data dir を再利用するので PG17 等に変えると起動しない。
- **ポータビリティは維持**: 本構成は Docker + PostgreSQL + vLLM で完結しており Akamai 固有ではない。Akamai をコスト最適な既定としつつ、AWS / オンプレも選べる状態を保つ（ロックイン回避＋交渉力）。

---

## 代替構成（必要に応じて）

- **PostgreSQL を Akamai Managed Database（Aiven）に**: SQL が常時マネージドで永続（インスタンス削除と無関係）。Block Storage はファイル＋モデルだけでよくなる。コストは上がるが運用は楽。
- **完全 native（PG も host）**: PG の data_directory を `/mnt/db/pgdata` に移して永続化。Docker を使わない構成だが、PG データ移設の手間がある。
