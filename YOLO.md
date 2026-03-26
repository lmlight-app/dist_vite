# 物体検出機能 (オプション)

画像から物体を検出する機能です。YOLOモデルを別途インストールすることで利用可能になります。

## モデル比較表

| モデル | サイズ | 推論速度 (CPU) | 推論速度 (GPU) | 精度 (mAP) | 想定用途 |
|--------|--------|----------------|----------------|------------|----------|
| yolov8n | 6MB | 約80ms | 約5ms | ★★☆☆☆ | デモ・プロトタイプ |
| yolov8s | 22MB | 約130ms | 約7ms | ★★★☆☆ | 軽量リアルタイム |
| yolov8m | 52MB | 約250ms | 約10ms | ★★★★☆ | バランス型 |
| yolov8l | 87MB | 約400ms | 約13ms | ★★★★☆ | 高精度・GPU推奨 |
| yolov8x | 131MB | 約600ms | 約16ms | ★★★★★ | 最高精度・GPU推奨 |

※ 推論速度は640x640画像での目安です。実際の速度はCPU/GPU性能、画像サイズにより変動します。
※ デフォルトモデルは80クラス（person, car, dog等）を検出します。

## GPU対応状況

| GPU | macOS | Linux | Windows |
|-----|-------|-------|---------|
| Apple Silicon (M1/M2/M3/M4) | ✅ MPS | - | - |
| NVIDIA RTX 20/30/40/50シリーズ | - | ✅ CUDA | ✅ CUDA |

ultralytics は GPU を自動検出します。CUDA/MPS が利用可能な場合、自動的にGPUで推論します。

## モデルのインストール

### macOS / Linux

```bash
# デフォルト (yolov8n)
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-yolo.sh | bash

# モデル指定
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-yolo.sh | bash -s -- yolov8n
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-yolo.sh | bash -s -- yolov8s
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-yolo.sh | bash -s -- yolov8m
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-yolo.sh | bash -s -- yolov8l
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-yolo.sh | bash -s -- yolov8x
```

インストール後、LM Lightを再起動すると画像処理ページに「物体検出」タブが表示されます。

## カスタムモデル

独自に学習したYOLOモデル（.ptファイル）を使用できます。

```bash
# 学習済みモデルを配置
cp my_custom_model.pt ~/.local/lmlight/models/yolo/

# 複数モデルを配置可能（UIでモデル切替）
cp defect_detection.pt ~/.local/lmlight/models/yolo/
cp safety_helmet.pt ~/.local/lmlight/models/yolo/
```

配置後、LM Lightを再起動するとモデルセレクターに表示されます。

## 仕様

| 項目 | 内容 |
|------|------|
| 対応形式 | PNG, JPG, GIF, BMP, WebP |
| 検出クラス (デフォルト) | 80クラス (COCO: person, car, dog, cat等) |
| 信頼度閾値 | 0.25 (デフォルト) |
| GPU対応 | MPS (macOS), CUDA (Linux/Windows) |

## モデルの変更・追加

複数モデルの共存が可能です。不要なモデルを削除する場合:

```bash
# 特定のモデルを削除
rm ~/.local/lmlight/models/yolo/yolov8n.pt

# 全モデル削除
rm -rf ~/.local/lmlight/models/yolo
```

## 出力形式

検出結果はJSON形式で出力されます。Copyボタンでチャットに貼り付けて分析できます。

```json
[
  { "label": "person", "confidence": 0.95, "bbox": [100, 50, 300, 400] },
  { "label": "car", "confidence": 0.87, "bbox": [400, 200, 700, 500] }
]
```

- `label`: 検出されたオブジェクト名
- `confidence`: 信頼度 (0.0〜1.0)
- `bbox`: バウンディングボックス [x1, y1, x2, y2]

## 前提条件

- ultralytics パッケージ（インストールスクリプトが自動インストール）
- PyTorch（ultralytics の依存で自動インストール）
