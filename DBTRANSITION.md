# DBの移行方法

> デフォルトのDB名・ユーザー名・パスワードはすべて `digitalbase`。
> 旧バージョン (LM Light 系) からの移行で `lmlight` を使用していた場合は、適宜読み替えてください。

## 1. エクスポート（移行元）

```bash
pg_dump -U digitalbase -d digitalbase -F c -f digitalbase_backup.dump
```

## 2. ファイルを移行先へコピー

USB、ネットワーク共有、クラウドストレージ等で `digitalbase_backup.dump` を移行先へ

## 3. インポート（移行先）

```bash
# DB作成（初回のみ）
psql -U postgres -c "CREATE USER digitalbase WITH PASSWORD 'digitalbase';"
psql -U postgres -c "CREATE DATABASE digitalbase OWNER digitalbase;"
psql -U postgres -d digitalbase -c "CREATE EXTENSION IF NOT EXISTS vector;"

# リストア
pg_restore -U digitalbase -d digitalbase digitalbase_backup.dump
```

## 既存データがある場合

```bash
# 既存DBを削除してからリストア
psql -U postgres -c "DROP DATABASE digitalbase;"
psql -U postgres -c "CREATE DATABASE digitalbase OWNER digitalbase;"
psql -U postgres -d digitalbase -c "CREATE EXTENSION IF NOT EXISTS vector;"
pg_restore -U digitalbase -d digitalbase digitalbase_backup.dump
```

---

# BotとEmbeddingsのみ移行

同じDB構成が既にある前提で、BotデータとベクトルDBのみを移行する方法。

## 1. エクスポート（移行元）

```bash
pg_dump -U digitalbase -d digitalbase -t '"Bot"' -t 'pgvector.embeddings' --data-only -f bot_embeddings.sql
```

## 2. ファイルを移行先へコピー

`bot_embeddings.sql` を移行先へ

## 3. インポート（移行先）

```bash
# 既存データをクリアしてインポート
psql -U digitalbase -d digitalbase -c "DELETE FROM pgvector.embeddings;"
psql -U digitalbase -d digitalbase -c "DELETE FROM \"Bot\";"
psql -U digitalbase -d digitalbase -f bot_embeddings.sql
```

### 追記モード（既存データを残す場合）

```bash
psql -U digitalbase -d digitalbase -f bot_embeddings.sql
```

※ 同じIDのBotがあるとエラーになるので注意

---

# 別ユーザーへのBot移行

移行先の別ユーザーにBotを割り当てる場合。

## 1. エクスポート（移行元）

```bash
# INSERT形式でエクスポート
pg_dump -U digitalbase -d digitalbase -t '"Bot"' -t 'pgvector.embeddings' --data-only --inserts -f bot_export.sql
```

## 2. ユーザーIDを確認

```bash
# 移行元のユーザーID
psql -U digitalbase -d digitalbase -c "SELECT id, email FROM \"User\";"

# 移行先のユーザーID（移行先PCで実行）
psql -U digitalbase -d digitalbase -c "SELECT id, email FROM \"User\";"
```

## 3. ユーザーIDを置き換えてインポート

```bash
# OLD_USER_ID: 移行元のユーザーID
# NEW_USER_ID: 移行先のユーザーID

sed "s/'OLD_USER_ID'/'NEW_USER_ID'/g" bot_export.sql | psql -U digitalbase -d digitalbase
```

### 共有設定もリセットする場合

```bash
sed -e "s/'OLD_USER_ID'/'NEW_USER_ID'/g" \
    -e "s/'TAG'/'PRIVATE'/g" \
    bot_export.sql | psql -U digitalbase -d digitalbase
```

## 注意事項

- 移行先にユーザーが存在している必要がある（先にログインしてユーザー作成）
- 同じBot IDが既に存在するとエラー
- shareType=TAGの場合、移行先にタグがないとエラー → PRIVATEにリセット推奨

---

## 旧バージョン (lmlight) からの移行

旧 LM Light で `lmlight` ユーザー / `lmlight` データベースを使用していた場合:

```bash
# 旧環境でエクスポート
pg_dump -U lmlight -d lmlight -F c -f lmlight_backup.dump

# 新環境でリストア (DB名を digitalbase に変更)
psql -U postgres -c "CREATE USER digitalbase WITH PASSWORD 'digitalbase';"
psql -U postgres -c "CREATE DATABASE digitalbase OWNER digitalbase;"
psql -U postgres -d digitalbase -c "CREATE EXTENSION IF NOT EXISTS vector;"
pg_restore -U digitalbase -d digitalbase --no-owner --role=digitalbase lmlight_backup.dump
```
