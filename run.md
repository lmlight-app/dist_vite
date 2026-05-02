# DigitalBase CLI コマンド (Perpetual License)

## 使い方

```bash
db start   # 起動
db stop    # 停止
```

vLLM 版の場合は `db-vllm start` / `db-vllm stop` を使用してください。

インストール時に自動セットアップされます。

## 直接実行

CLI が使えない場合:

**macOS / Linux:**
```bash
~/.local/db/start.sh   # 起動
~/.local/db/stop.sh    # 停止
```

**Windows:**
```powershell
powershell -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\db\start.ps1"   # 起動
powershell -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\db\stop.ps1"    # 停止
```

## 手動セットアップ (参考)

インストーラーが失敗した場合のみ。

**macOS / Linux:**
```bash
sudo ln -sf ~/.local/db/db /usr/local/bin/db
```

**Windows:**
```powershell
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$env:LOCALAPPDATA\db", "User")
```
※ 新しいターミナルで有効
