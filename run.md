# LM Light CLI コマンド (Perpetual License)

## 使い方

```bash
lmlight start   # 起動
lmlight stop    # 停止
```

インストール時に自動セットアップされます。

## 直接実行

CLIが使えない場合:

**macOS / Linux:**
```bash
~/.local/lmlight/start.sh   # 起動
~/.local/lmlight/stop.sh    # 停止
```

**Windows:**
```powershell
powershell -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\lmlight\start.ps1"   # 起動
powershell -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\lmlight\stop.ps1"    # 停止
```

## 手動セットアップ (参考)

インストーラーが失敗した場合のみ。

**macOS / Linux:**
```bash
sudo ln -sf ~/.local/lmlight/lmlight /usr/local/bin/lmlight
```

**Windows:**
```powershell
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$env:LOCALAPPDATA\lmlight", "User")
```
※ 新しいターミナルで有効