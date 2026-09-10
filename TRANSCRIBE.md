# 文字起こし機能 (オプション)

音声ファイルをテキストに変換する機能です。Whisper モデルを別途インストールすることで利用可能になります。
チャットの音声添付・RAG 取込に加え、API キー (`sk-...`) から `POST /v1/audio/transcriptions` (OpenAI Audio 互換) でも使えます。音声は外部に送られません。

## エンジンは 2 種類 (自動選択)

| エンジン | モデル形式 | 導入 | 向く環境 |
|---|---|---|---|
| **whisper.cpp** (pywhispercpp) | ggml (`ggml-<model>.bin`) | 既定。追加インストール不要。バイナリ配布でも動く | CPU、Apple Silicon (Metal) |
| **faster-whisper** (CTranslate2) | CT2 (`ct2-<model>/`) | `--gpu` または `--ct2` (ソース配布のみ) | NVIDIA GPU (x86_64)、CPU でも int8 で高速。無音区間の VAD 付き |

どちらを使うかは **配置されたモデル形式と GPU の有無で本体が自動判定**します。`.env` に GPU 設定は要りません。
両方置いた場合は CUDA が見えれば faster-whisper、見えなければ whisper.cpp を選びます。

## モデル比較表

| モデル | サイズ | 30分音声の処理時間 (CPU) | 30分音声の処理時間 (GPU) | 精度 | 想定用途 |
|--------|--------|--------------------------|--------------------------|------|----------|
| tiny | 75MB | 約3分 | 約30秒 | ★★☆☆☆ | 高速プレビュー、メモ程度 |
| base | 145MB | 約5分 | 約45秒 | ★★★☆☆ | 日常会話、簡易議事録 |
| small | 480MB | 約15分 | 約1.5分 | ★★★★☆ | ビジネス文書、インタビュー |
| medium | 1.5GB | 約40分 | 約3分 | ★★★★☆ | 専門用語含む録音 |
| large | 3.0GB | 約90分 | 約5分 | ★★★★★ | 高精度が必須の文書化 (large-v3) |
| distil-large | 1.5GB | 約40分 | 約2分 | ★★★★★ | large 相当の精度で medium 並みの速度 (faster-whisper のみ) |

※ 処理時間は目安です。実際の時間は CPU/GPU 性能、音声品質により変動します。faster-whisper は同じモデルで whisper.cpp / 参照実装の 2〜4 倍速です。
※ GPU 未使用時は CPU のみで処理されます。

## GPU 対応状況

| GPU | macOS | Linux | Windows |
|-----|-------|-------|---------|
| Apple Silicon (M1/M2/M3/M4) | ✅ Metal (whisper.cpp) | - | - |
| NVIDIA RTX 20/30/40 シリーズ (x86_64) | - | ✅ CUDA (`--gpu`) | ✅ CUDA (whisper.cpp ソースビルド) |
| NVIDIA RTX 50 シリーズ (Blackwell、x86_64) | - | ✅ CUDA (`--gpu`) | ⚠️ (下記) |
| NVIDIA DGX Spark / Grace (Linux aarch64、CUDA 13) | - | ⚠️ (下記) | - |

### Linux x86_64 + NVIDIA — `--gpu`

`--gpu` で faster-whisper と CUDA ライブラリ (cuBLAS / cuDNN 9) を入れ、CT2 形式のモデルを配置します。CUDA 12 系のドライバが入っていれば追加設定なしで GPU が使われます。

### DGX Spark / Grace (Linux aarch64、CUDA 13) — ⚠️

公式の ctranslate2 wheel は aarch64 では **CPU 専用**です (CUDA 13 も未対応)。`--gpu` を付けてもエラーにはならず、faster-whisper が CPU (int8) で動きます。短い発話 (数秒) なら CPU でも実用になります。GPU で動かす場合は次のいずれか:

- CUDA 13 向け community ビルドの ctranslate2: https://github.com/assix/ctranslate2-aarch64-cuda13-binaries
- whisper.cpp を CUDA 有効でビルドし、ggml 形式に戻す (下記の RTX 50 と同じ手順、`CMAKE_CUDA_ARCHITECTURES=121a-real`)

### Windows / RTX 50 シリーズ — whisper.cpp を CUDA 有効でビルド

Windows 配布はバイナリ版 (whisper.cpp 同梱) のため、GPU を使うには pywhispercpp をソースからビルドします。

**前提条件:**
- CUDA Toolkit 12.8 以上
- Visual Studio 2022 (C++ ビルドツール)

**Windows でのビルド:**
```powershell
$env:GGML_CUDA = "1"
$env:CMAKE_CUDA_ARCHITECTURES = "120"  # Blackwell
pip install git+https://github.com/absadiki/pywhispercpp --force-reinstall --no-cache-dir
```

**Linux でのビルド:**
```bash
GGML_CUDA=1 CMAKE_CUDA_ARCHITECTURES=120 uv pip install git+https://github.com/absadiki/pywhispercpp --force-reinstall --no-cache-dir
```

※ ビルドに失敗する場合は `CMAKE_CUDA_ARCHITECTURES=90` を試してください

## モデルのインストール

### macOS / Linux

```bash
# デフォルト (tiny、whisper.cpp)
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_vite/main/scripts/install-transcribe.sh | bash

# モデル指定 + 日本語固定 (短い発話の認識が安定する)
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_vite/main/scripts/install-transcribe.sh | bash -s -- small --lang ja

# GPU (faster-whisper、ソース配布のみ)
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_vite/main/scripts/install-transcribe.sh | bash -s -- medium --gpu --lang ja
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_vite/main/scripts/install-transcribe.sh | bash -s -- distil-large --gpu --lang ja

# CPU で faster-whisper (VAD 付き、int8。ソース配布のみ)
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_vite/main/scripts/install-transcribe.sh | bash -s -- small --ct2 --lang ja
```

### Windows

```powershell
# デフォルト (tiny)
irm https://raw.githubusercontent.com/lmlight-app/dist_vite/main/scripts/install-transcribe.ps1 | iex

# モデル指定 + 日本語固定
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/lmlight-app/dist_vite/main/scripts/install-transcribe.ps1))) -ModelName small -Lang ja
```

インストール後、DigitalBase を再起動するとサイドバーに「文字起こし」が表示されます。
管理画面 → ライセンス → 文字起こし (または `GET /api/transcribe`) で、使われている backend (`faster-whisper` / `pywhispercpp`) と device (`cuda` / `cpu`) を確認できます。

## 設定 (.env、いずれも任意)

| 変数 | 内容 | 推奨 |
|---|---|---|
| `WHISPER_LANGUAGE` | 既定言語 (ISO-639-1)。空なら自動判定 | 日本語運用なら `ja` (`--lang ja` で設定される) |
| `WHISPER_INITIAL_PROMPT` | 認識を誘導する語彙・文脈 | 専門用語や短い命令語 (例: `前進、後退、停止`) |
| `WHISPER_VAD_FILTER` | 無音区間を除いてから認識 (faster-whisper のみ、幻聴対策) | 既定 `1` のまま |
| `WHISPER_COMPUTE_TYPE` | faster-whisper の精度 (`float16` / `int8` 等) | 空で自動 (CUDA=float16、CPU=int8) |
| `WHISPER_MODEL` | モデルが複数ある時の絞り込み、またはモデルのパス | インストーラが設定 |

## 仕様

| 項目 | 内容 |
|------|------|
| 対応形式 | WAV, MP3, M4A, OGG, FLAC, AAC、動画コンテナ (MP4, WebM 等) の音声トラック |
| 最大ファイルサイズ | 100MB |
| 対応言語 | 日本語, English (Whisper の対応言語) |
| API | `POST /v1/audio/transcriptions` (OpenAI Audio 互換、`json` / `text` / `verbose_json`) |
| GPU 対応 | Metal (macOS)、CUDA (Linux x86_64 は `--gpu`、その他はソースビルド) |

## モデルの変更

別のモデルに変更する場合は、既存モデルを削除してから再インストール:

```bash
# 既存モデル削除
rm -rf ~/.local/db/stt-model/whisper

# 新しいモデルをインストール
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_vite/main/scripts/install-transcribe.sh | bash -s -- small --lang ja
```

## 前提条件

- FFmpeg がインストールされていること（WAV 以外の形式の変換に使用。16 kHz mono の WAV は FFmpeg なしで処理）
- macOS: `brew install ffmpeg`
- Linux: `sudo apt install ffmpeg`
- Windows: `winget install Gyan.FFmpeg`
