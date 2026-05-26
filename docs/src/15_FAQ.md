# DigitalBase よくある質問（FAQ）

**Frequently Asked Questions**

最終更新日: 2026年5月

---

## 製品全般

### Q. DigitalBase とは何ですか？
オンプレミス環境で動作する LLM チャット・RAG・業務自動化プラットフォームです。社内データを外部に出さずに AI を活用できます。
> 旧名 LM Light。配布バイナリには `lmlight-vite` の名称が引き続き使用されています。

### Q. クラウドにデータが送信されることはありますか？
**既定では送信されません。** すべてのデータ（チャット内容、アップロード文書、RAG データ等）はお客様の環境内に留まり、インターネット接続なしで動作可能です。
ただし、**OpenAI / Anthropic / Gemini 等のクラウド LLM** をオプションで併用するように `.env` で設定した場合は、その API への送信が発生します（明示的なオプトイン）。

### Q. 対応 OS は？
- **Ollama版**: macOS / Linux / Windows
- **vLLM版**: Linux のみ（NVIDIA GPU 必須、RTX 50 Blackwell 対応 CUDA ビルドあり）
- **Docker版**: Docker が動作するすべての環境

### Q. 既存の vLLM サーバーに接続できますか？
はい。`.env` で `VLLM_AUTO_START=false` にして、`VLLM_BASE_URL` を既存の vLLM サーバーに向ければ動きます。API は httpx で `/v1/chat/completions` 等の OpenAI 互換エンドポイントに直接リクエストを投げるため、自前で起動した vLLM でも外部の vLLM でも問題ありません。

### Q. OpenAI SDK を使っていますか？
いいえ。OpenAI SDK には依存しておらず、httpx（Python HTTP クライアント）で OpenAI 互換エンドポイントに直接リクエストしています。

### Q. アーキテクチャはどうなっていますか？
Vite Edition では、**FastAPI が REST API と Vite ビルドの SPA を同時に配信する単一プロセス・単一ポート 8000 構成** です。Node.js は不要です。

---

## ライセンス

### Q. ライセンス形態は？
**買い切り（Perpetual）** と **サブスクリプション（月額/年額）** の 2 種類があります。料金は別途お問い合わせください。

### Q. 1 ライセンスで複数台に入れられますか？
いいえ。1 ライセンス = 1 デバイスです。買い切りライセンスは Hardware UUID に紐付けられます。複数台で利用する場合は台数分のライセンスが必要です。

### Q. サブスクリプションを解約したらデータは消えますか？
データはお客様のデータベースに保存されているため、解約後もデータ自体は残ります。ただしソフトウェアの利用は停止する必要があります。

### Q. 買い切りライセンスのアップデートは？
購入後 1 年間はセキュリティパッチ・バグ修正・機能追加が無料です。2 年目以降は年間保守契約を締結いただくことで継続的にアップデートを受けられます。

---

## 機能

### Q. どんな機能がありますか？

| 機能 | 説明 |
|------|------|
| AI チャット | 複数 LLM モデルの切替・会話履歴管理 |
| RAG | 社内文書をアップロードして AI が回答（HNSW + IVFFlat、Web 検索 RAG 対応） |
| Document Creator | テンプレートからのドキュメント自動生成、PDF・画像からの抽出 |
| Pipeline | 80 以上のオペレータで業務フロー自動化（kintone, Slack, S3, BigQuery 等） |
| MCP サーバー | Claude Desktop / Cursor から RAG・Pipeline・SQL を直接呼び出し |
| Helpdesk | 社内問い合わせ管理・割当・ステータス管理 |
| SQL エージェント + Dashboard | 外部 DB に自然言語クエリ、結果を Canvas 式ダッシュボードに保存 |
| 承認フロー | 多段階承認プロセス |
| 文字起こし | 音声ファイルのテキスト変換（Whisper、RTX 50 Blackwell 対応 CUDA ビルド） |
| Vision / OCR | Vision LLM による画像理解（Qwen2.5-VL / Gemma 3 / DeepSeek-OCR 等）+ Tesseract OCR |
| ベンチマーク | LLM モデルの性能比較 |
| プロンプトライブラリ | プロンプトの保存・共有 |
| クラウド LLM 併用 | OpenAI / Anthropic / Gemini を任意有効化 |
| ファインチューニング | **受託サービス**（製品内に学習機能はなし） |

### Q. RAG で対応しているファイル形式は？
PDF, Word, Excel, PowerPoint, テキスト, Markdown, CSV, JSON, 画像

### Q. Pipeline はどんなことができますか？
80 以上のオペレータをノーコードで組み合わせて業務を自動化できます。例:
- 「kintone のレコード更新を契機に、関連ドキュメントを RAG ロード → Slack に通知」
- 「Salesforce の取引先リストを毎朝取得 → LLM で分類 → BigQuery に保存」
- 「SharePoint の新規ファイルを監視 → OCR → 承認フロー起票」

スケジュール実行・Webhook 起動・手動実行に対応します。

### Q. Claude Desktop や Cursor から DigitalBase を使えますか？
はい。MCP (Model Context Protocol) サーバーを内蔵しているため、Claude Desktop / Cursor / その他 MCP 対応クライアントから DigitalBase の RAG・Pipeline・SQL を呼び出せます。`/api/mcp` JSON-RPC エンドポイントで提供します。

### Q. Helpdesk 機能はありますか？
はい。社内問い合わせの起票・割当・ステータス管理ができ、RAG / Bot と連携した一次回答自動化も可能です。

### Q. Web 検索 RAG とは何ですか？
DuckDuckGo / SearXNG を用いた Web 検索結果を RAG コンテキストに加える機能です。`.env` の `WEB_SEARCH_ENABLED` とユーザー設定の二段階トグルで有効化します。

### Q. クラウド LLM はどのサービスに対応していますか？
OpenAI、Anthropic、Google Gemini に対応しています。`.env` で各サービスの API キーを設定すれば、チャット画面や Pipeline で用途に応じて切り替えられます。

### Q. ファインチューニングは製品内でできますか？
いいえ。ファインチューニングは **受託サービス** として提供しています。CSV テンプレートに学習データをご用意いただき、当社で専用モデルを作成します。

### Q. 文字起こし機能の対応形式は？
WAV, MP3, M4A, MP4, WebM, OGG, FLAC, AAC（最大 100MB）。RTX 50 (Blackwell) 対応の CUDA ビルドも提供しています。

### Q. SQL Dashboard ではどんな chart が作れますか？
棒 / 折れ線 / 円 / ピボット / 散布の 5 種類に切替可能で、X 軸・Y 軸（多系列）・集計（合計/平均/件数/最小/最大）・値表示・基準線・積み上げ・面塗りまで UI から設定できます。配置は drag/resize で自由、設定は dashboard ごとに永続化されます。

### Q. 画像内容の理解は何ができますか？
**Vision LLM**（Qwen2.5-VL / Gemma 3 / DeepSeek-OCR / Granite Vision など）により、物体認識・表抽出・図面の記述・手書き OCR を **1 つの LLM で対応** できます。プレーンな文字認識のみであれば Tesseract OCR にフォールバックできます。

> v2.5.0 で個別 YOLO パイプラインと DXF 処理機能は廃止されました。Vision LLM が個別タスクをカバーするためです。

---

## 認証・ユーザー管理

### Q. Active Directory と連携できますか？
はい。LDAP 認証（python-ldap3）に対応しており、Active Directory / OpenLDAP と連携可能です。ユーザーは初回ログイン時に自動作成されます。`.env` で `AUTH_MODE=ldap` と設定し、LDAP 関連の環境変数を設定してください。LDAP 属性 30+ を `User.ldapAttributes` に保持します。

### Q. Azure AD（Microsoft Entra ID）と連携できますか？
はい。OIDC 認証（python-jose）に対応しています。`.env` で `AUTH_MODE=oidc` と設定し、OIDC_CLIENT_ID / OIDC_CLIENT_SECRET / OIDC_TENANT_ID を設定してください。

### Q. AD/OIDC 環境でも管理者はローカルログインできますか？
はい。admin@local アカウントは認証モードに関わらず常にローカル認証（ID/パスワード）でログイン可能です。

### Q. ユーザー権限はどうなっていますか？
3 段階のロールがあります。

| ロール | 権限 |
|--------|------|
| ADMIN | 全機能 + ユーザー管理 + ライセンス管理 + 全履歴閲覧 |
| SUPER | 全機能 + タグ管理 + ユーザーへのタグ付与 |
| USER | 基本機能の利用 |

### Q. Bot / Pipeline を別ユーザーの権限で実行できますか？
はい。共有 Bot / Pipeline に対し `runAs` を設定することで、「作成者の権限で実行（owner）」または「呼び出し者の権限で実行（caller）」を選択できます。さらに `shareType`（PRIVATE / TAG / PUBLIC）と LDAP グループ → タグの自動マッピングで細かく制御できます。

### Q. ユーザー数に上限はありますか？
ライセンスに基づくユーザー数制限があります。上限に達すると AD/OIDC 経由の新規ユーザー自動作成が制限されます。

---

## セキュリティ

### Q. パスワードはどのように保存されますか？
passlib bcrypt（12 ラウンド）でハッシュ化されて保存されます。平文での保存は一切ありません。

### Q. セッション管理の方式は？
JWT (HS256) + HTTP-only Cookie です。セッション有効期間は 365 日間（`.env` で変更可）です。

### Q. デフォルトのバインドアドレスは？
`0.0.0.0`（LAN 内アクセス可）です。同一サーバー内に閉じたい場合は `~/.local/db/.env` の `API_HOST` を `127.0.0.1` に変更してください（vLLM 版は `~/.local/db-vllm/.env`）。

### Q. HTTPS に対応していますか？
Nginx リバースプロキシを設定することで HTTPS 通信に対応可能です。設定手順はネットワークガイドを参照してください。

### Q. テレメトリ（利用データ）の送信はありますか？
ありません。本製品はテレメトリ・利用統計を一切外部送信しません（クラウド LLM 明示利用時の API 呼び出しを除く）。

---

## サポート

### Q. サポートプランの違いは？

| | スタンダード | プレミアム | エンタープライズ |
|---|---|---|---|
| 応答時間 | 2 営業日 | 1 営業日 | 4 時間 |
| 受付方法 | メール | メール・オンライン会議 | 電話・メール・オンライン会議 |
| リモート対応 | - | 月 2 回 | 無制限 |

### Q. サポート対象外の範囲は？
ハードウェア障害、OS・ネットワーク構築、カスタマイズ開発、データ復旧は対象外です。

---

## 導入・運用

### Q. インストールにどのくらい時間がかかりますか？
ワンコマンドインストールで、依存関係が準備されていれば数分で完了します。Vite Edition では Node.js 不要、API + フロントが単一プロセス・単一ポート 8000 で動作します。

### Q. インストール先と CLI は？
- インストール先: `~/.local/db`（vLLM 版は `~/.local/db-vllm`）
- CLI: `db start` / `db stop`（vLLM 版は `db-vllm start` / `db-vllm stop`）
- DB 名・ユーザー・パスワード: `digitalbase`

### Q. 初期ログイン情報は？
初期アカウントは `admin@local` / `admin123` です。初回ログイン後に必ずパスワードを変更してください。

### Q. アップデート方法は？
同じインストールコマンドを再実行するだけです。既存データは保持されます。

### Q. データベースの移行はできますか？
はい。`pg_dump` / `pg_restore` でデータベースの移行が可能です。詳細は DB 移行ガイドを参照してください。

---

## お問い合わせ

**デジタルベース株式会社**
- メール: info@digital-base.co.jp
- ウェブサイト: https://digital-base.co.jp
- プロダクトサイト: https://digital-base.co.jp/lmlight

---

Copyright (c) 2026 デジタルベース株式会社 All rights reserved.
