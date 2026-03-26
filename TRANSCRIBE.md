# 文字起こし機能 (オプション)

音声ファイルをテキストに変換する機能です。Whisperモデルを別途インストールすることで利用可能になります。

## モデル比較表

| モデル | サイズ | 30分音声の処理時間 (CPU) | 30分音声の処理時間 (GPU) | 精度 | 想定用途 |
|--------|--------|--------------------------|--------------------------|------|----------|
| tiny | 74MB | 約3分 | 約30秒 | ★★☆☆☆ | 高速プレビュー、メモ程度 |
| base | 142MB | 約5分 | 約45秒 | ★★★☆☆ | 日常会話、簡易議事録 |
| small | 466MB | 約15分 | 約1.5分 | ★★★★☆ | ビジネス文書、インタビュー |
| medium | 1.5GB | 約40分 | 約3分 | ★★★★☆ | 専門用語含む録音 |
| large | 2.9GB | 約90分 | 約5分 | ★★★★★ | 高精度が必須の文書化 |

※ 処理時間は目安です。実際の時間はCPU/GPU性能、音声品質により変動します。
※ GPU未使用時はCPUのみで処理されます。

## GPU対応状況

| GPU | macOS | Linux | Windows |
|-----|-------|-------|---------|
| Apple Silicon (M1/M2/M3/M4) | ✅ Metal | - | - |
| NVIDIA RTX 20/30/40シリーズ | - | ✅ CUDA | ✅ CUDA |
| NVIDIA RTX 50シリーズ | - | ⚠️ | ⚠️ |

⚠️ RTX 50シリーズ (Blackwell) は現在pywhispercppがプリビルドバイナリ未対応のため、CPU処理にフォールバックします。

### RTX 50シリーズでGPUを使う方法

pywhispercppをソースからビルドすることでGPUを有効化できます。

**前提条件:**
- CUDA Toolkit 12.8以上
- Visual Studio 2022 (C++ビルドツール)

**Windowsでのビルド:**
```powershell
# 1. pywhispercppをCUDA有効でインストール
$env:GGML_CUDA = "1"
$env:CMAKE_CUDA_ARCHITECTURES = "120"  # Blackwell
pip install git+https://github.com/absadiki/pywhispercpp --force-reinstall --no-cache-dir
```

**Linux/macOSでのビルド:**
```bash
GGML_CUDA=1 CMAKE_CUDA_ARCHITECTURES=120 pip install git+https://github.com/absadiki/pywhispercpp --force-reinstall --no-cache-dir
```

※ ビルドに失敗する場合は `CMAKE_CUDA_ARCHITECTURES=90` を試してください

## モデルのインストール

### macOS / Linux

```bash
# デフォルト (tiny)
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.sh | bash

# モデル指定
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.sh | bash -s -- tiny
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.sh | bash -s -- base
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.sh | bash -s -- small
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.sh | bash -s -- medium
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.sh | bash -s -- large
```

### Windows

```powershell
# デフォルト (tiny)
irm https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.ps1 | iex

# モデル指定
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.ps1))) -ModelName tiny
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.ps1))) -ModelName base
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.ps1))) -ModelName small
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.ps1))) -ModelName medium
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.ps1))) -ModelName large
```

インストール後、LM Lightを再起動するとサイドバーに「文字起こし」が表示されます。

## 仕様

| 項目 | 内容 |
|------|------|
| 対応形式 | WAV, MP3, M4A, MP4, WebM, OGG, FLAC, AAC |
| 最大ファイルサイズ | 100MB |
| 対応言語 | 日本語, English |
| GPU対応 | Metal (macOS), CUDA (Linux/Windows) |

## モデルの変更

別のモデルに変更する場合は、既存モデルを削除してから再インストール:

```bash
# 既存モデル削除
rm -rf ~/.local/lmlight/models/whisper

# 新しいモデルをインストール
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.sh | bash -s -- small
```

## 前提条件

- FFmpeg がインストールされていること（音声変換に使用）
- macOS: `brew install ffmpeg`
- Linux: `sudo apt install ffmpeg`
- Windows: `winget install Gyan.FFmpeg`