# DigitalBase 競合比較表

**Competitive Comparison**

最終更新日: 2026年5月

---

## オンプレミスLLMプラットフォーム比較

| 項目 | **DigitalBase** | Open WebUI | Dify | AnythingLLM |
|------|:----------:|:----------:|:----:|:-----------:|
| **デプロイ** | ワンコマンド (Node.js不要) | Docker | Docker Compose | Docker / デスクトップ |
| **LLMエンジン** | Ollama / vLLM / クラウドLLM併用 | Ollama | 複数対応 | 複数対応 |
| **RAG (HNSW + Web検索)** | ✅ | ✅ | ✅ | ✅ |
| **ドキュメント生成 / Document Creator** | ✅ | - | - | - |
| **Pipeline (80+ オペレータ)** | ✅ | - | △ (限定) | - |
| **MCP サーバー (Claude Desktop / Cursor 連携)** | ✅ | - | - | - |
| **Helpdesk (社内問い合わせ)** | ✅ | - | - | - |
| **SQLエージェント** | ✅ | - | - | - |
| **承認フロー** | ✅ | - | - | - |
| **文字起こし (RTX 50対応)** | ✅ (Whisper) | ✅ | - | ✅ |
| **画像処理 / YOLO** | ✅ | - | - | - |
| **DXF処理** | ✅ | - | - | - |
| **ユーザー管理** | 3段階ロール + runAs + タグACL | 基本的 | 基本的 | 基本的 |
| **AD / LDAP** | ✅ | ✅ | ✅ | - |
| **Azure AD (OIDC)** | ✅ | ✅ | ✅ | - |
| **ブランディング** | ✅ | - | ✅ | - |
| **対応OS** | macOS/Linux/Windows | Docker | Docker | マルチ |
| **ライセンス** | 商用（買い切り可） | MIT | オープンコア | オープンコア |
| **日本語UI** | ✅ ネイティブ | ✅ | ✅ | 一部 |
| **商用サポート** | ✅ | コミュニティ | 有料プラン | 有料プラン |

---

## DigitalBase の差別化ポイント

### 1. Pipeline で 80+ オペレータの業務自動化

kintone / Salesforce / SharePoint / S3 / BigQuery / Snowflake / Slack / Teams / freee / MoneyForward / SmartHR 等、**国内業務システムを含む80以上のコネクタ** をノーコードで組み合わせた業務自動化エンジンを標準搭載。
他のオンプレ LLM プラットフォームでは「Webhook 連携で外部 iPaaS と接続」止まりですが、DigitalBase は **これ単体で iPaaS 兼AI基盤** として動作します。

### 2. MCP サーバーで Claude Desktop / Cursor から直接利用

Model Context Protocol (MCP) サーバーを内蔵。Claude Desktop / Cursor 等の MCP 対応クライアントから、DigitalBase の RAG・Pipeline・SQL を **追加開発なしに呼び出せます**。

### 3. ワンコマンドインストール (Node.js 不要)

他のソリューションは Docker 環境が前提ですが、DigitalBase は **Docker なし・Node.js なし** でもワンコマンドでインストール可能。API + フロントエンドが単一バイナリで動作するため、IT リソースが限られた環境やオフライン環境でも導入できます。

### 4. 業務特化機能の標準搭載

一般的なチャット・RAG に加え、SQL エージェント、Pipeline、承認フロー、Helpdesk、DXF 処理、物体検出、Document Creator など、**業務に直結する機能を標準搭載**しています。

### 5. エンタープライズ認証 + 細粒度 ACL

Active Directory / Azure AD (Microsoft Entra ID) との連携に標準対応。既存の ID 管理基盤をそのまま利用でき、ユーザーは初回ログイン時に自動でアカウントが作成されます。
共有 Bot には **runAs（実行ユーザーの委譲）** とタグベース ACL を組み合わせ、「誰がどの権限で何にアクセスできるか」を細かく制御できます。

### 6. 買い切りライセンス

サブスクリプションだけでなく、一度の支払いで永続利用できる **買い切りライセンス** を選択可能。Hardware UUID 紐付けでオフライン認証されるため、ネット非接続環境でも運用できます。

### 7. クラウドLLMとの併用も可能

完全オンプレ運用が原則ですが、`.env` で OpenAI / Anthropic / Gemini を有効化することで、機密度の低いタスクのみクラウド LLM に流すといった **ハイブリッド運用** も可能です。

### 8. 完全日本語対応・国内サポート

UI は日本語ネイティブ。国内企業（デジタルベース株式会社）による直接サポートが受けられます。

---

## お問い合わせ

**デジタルベース株式会社**
- メール: info@digital-base.co.jp
- ウェブサイト: https://digital-base.co.jp
- プロダクトサイト: https://lmlight.jp

---

Copyright (c) 2026 デジタルベース株式会社 All rights reserved.
