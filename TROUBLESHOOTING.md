# トラブルシューティング

> インストール先: `~/.local/db` (Ollama版) / `~/.local/db-vllm` (vLLM版)
> デフォルトDB: `digitalbase` (ユーザー名・DB名・パスワード共通)
> 本ドキュメントでは `~/.local/db/.env` を例にしますが、vLLM版の場合は適宜 `~/.local/db-vllm/.env` に読み替えてください。

## データベース関連

### テーブル所有者エラー

**症状:**
```
ERROR: must be owner of table Bot
ERROR: must be owner of table Chat
ERROR: must be owner of table Message
```

**原因:**
既存のデータベースが別のユーザーで作成されており、現在のユーザーでは変更できない。

**解決策:**

まず `.env` で設定されているユーザー名・データベース名を確認:
```bash
grep DATABASE_URL ~/.local/db/.env
# 形式: postgresql://ユーザー名:パスワード@localhost:5432/データベース名
# デフォルト: postgresql://digitalbase:digitalbase@localhost:5432/digitalbase
```

方法1: テーブル所有者を変更（データ保持）
```bash
# DB_USER, DB_NAME は上記で確認した値に置き換え (デフォルトは digitalbase)
sudo -u postgres psql -d <DB_NAME> << 'EOF'
DO $$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        EXECUTE 'ALTER TABLE public.' || quote_ident(r.tablename) || ' OWNER TO <DB_USER>';
    END LOOP;
END $$;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO <DB_USER>;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO <DB_USER>;
GRANT ALL PRIVILEGES ON SCHEMA pgvector TO <DB_USER>;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA pgvector TO <DB_USER>;
EOF
```

方法2: データベースをリセット（全データ削除）
```bash
# 古いデータベース/ユーザーを削除して再作成
sudo -u postgres psql << 'EOF'
DROP DATABASE IF EXISTS <DB_NAME>;
DROP USER IF EXISTS <DB_USER>;
CREATE USER <DB_USER> WITH PASSWORD '<DB_PASS>';
CREATE DATABASE <DB_NAME> OWNER <DB_USER>;
ALTER USER <DB_USER> CREATEDB;
\c <DB_NAME>
CREATE EXTENSION IF NOT EXISTS vector;
EOF
```
その後、インストーラーを再実行。

---

### 権限エラー (WARNING: no privileges were granted)

**症状:**
```
WARNING: no privileges were granted for "Bot"
WARNING: no privileges were granted for "Chat"
WARNING: no privileges were granted for "User"
```

**原因:**
古いスキーマのテーブルが残っており、新しいユーザーに権限を付与できない。

**解決策:**
上記「テーブル所有者エラー」の解決策を実行。

---

### カラム不存在エラー

**症状:**
```
ERROR: column "hashedPassword" of relation "User" does not exist
```

**原因:**
古いスキーマの `User` テーブルに `hashedPassword` カラムがない。

**解決策:**

カラムを手動追加（.envの値に置き換え）:
```bash
PGPASSWORD=<DB_PASS> psql -U <DB_USER> -d <DB_NAME> -h localhost << 'EOF'
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "hashedPassword" TEXT;
EOF
```

または、データベースをリセットして再インストール。

---

### pgvector拡張エラー

**症状:**
```
ERROR: could not open extension control file "/usr/share/postgresql/17/extension/vector.control": No such file or directory
```

**原因:**
pgvector拡張がインストールされていない。

**解決策:**

macOS:
```bash
brew install pgvector
```

Linux (Ubuntu/Debian):
```bash
# PostgreSQLバージョンに合わせる (PG17推奨)
sudo apt install postgresql-17-pgvector
```

Windows:
インストーラーが自動でセットアップします。手動の場合は [pgvector Windows インストール手順](https://github.com/pgvector/pgvector#windows) を参照。

---

## Ollama関連

### Ollamaが起動しない

**症状:**
```
❌ Ollama not running
```

**解決策:**

手動起動:
```bash
ollama serve
```

バックグラウンドで起動:
```bash
ollama serve &>/dev/null &
```

インストール確認:
```bash
which ollama
ollama --version
```

---

### モデルが見つからない

**症状:**
UIでモデルが表示されない。

**解決策:**

モデルをダウンロード:
```bash
ollama pull gemma3:4b          # または任意のモデル
ollama pull nomic-embed-text   # RAG用（推奨）
```

モデル一覧確認:
```bash
ollama list
```

---

## PostgreSQL関連

### PostgreSQLが起動していない

**症状:**
```
❌ PostgreSQL not running
```

**解決策:**

macOS:
```bash
brew services start postgresql@17
```

Linux:
```bash
sudo systemctl start postgresql
sudo systemctl enable postgresql  # 自動起動
```

Windows:
サービスマネージャーで「postgresql-x64-17」を起動。

---

### 現在のユーザー・データベース確認

**ユーザー一覧:**
```bash
sudo -u postgres psql -c "\du"
```

**データベース一覧:**
```bash
sudo -u postgres psql -c "\l"
```

**テーブル所有者確認:**
```bash
sudo -u postgres psql -d <DB_NAME> -c "\dt"
```

**現在の.env設定確認:**
```bash
grep DATABASE_URL ~/.local/db/.env
```

※ パスワードはPostgreSQLに暗号化されて保存されているため直接確認できません。忘れた場合はリセットしてください。

---

### 接続できない

**症状:**
```
FATAL: password authentication failed for user "xxx"
```

**解決策:**

パスワードをリセット（.envの値に置き換え）:
```bash
sudo -u postgres psql -c "ALTER USER <DB_USER> WITH PASSWORD '<DB_PASS>';"
```

`.env` ファイルの `DATABASE_URL` を確認:
```bash
grep DATABASE_URL ~/.local/db/.env
# 形式: postgresql://ユーザー名:パスワード@localhost:5432/データベース名
```

---

## WSL固有の問題

### PostgreSQLサービスが起動しない

**症状:**
WSLでsystemctlが使えない。

**解決策:**

手動起動:
```bash
sudo service postgresql start
```

または:
```bash
sudo pg_ctlcluster 17 main start
```

---

### localhost接続エラー

**症状:**
WSLからlocalhostに接続できない。

**解決策:**

`pg_hba.conf` を編集:
```bash
sudo nano /etc/postgresql/17/main/pg_hba.conf
```

以下の行を追加/変更:
```
local   all   all                 trust
host    all   all   127.0.0.1/32  md5
```

PostgreSQLを再起動:
```bash
sudo service postgresql restart
```

---

## その他

### ポートが使用中

**症状:**
```
Error: listen EADDRINUSE: address already in use :::8000
```

**解決策:**

プロセスを終了:
```bash
# 使用中のプロセスを確認
lsof -i :8000

# プロセスを終了
kill -9 <PID>
```

または `db stop` を実行:
```bash
db stop
```

---

### ログの確認

問題が解決しない場合、ログを確認:
```bash
cat ~/.local/db/logs/api.log
```
