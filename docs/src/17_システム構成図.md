# LM Light システム構成図

**System Architecture**

最終更新日: 2026年3月

---

## システム概要

LM Light は以下のコンポーネントで構成されるオンプレミスAIプラットフォームです。

```mermaid
graph TB
    subgraph "お客様の環境"
        User["ユーザー<br/>ブラウザ"]

        subgraph "LM Light"
            Web["Web UI<br/>Next.js 15<br/>:3000"]
            API["API Server<br/>FastAPI (Python)<br/>:8000"]
            DB["PostgreSQL 17<br/>+ pgvector<br/>:5432"]
        end

        subgraph "LLMエンジン（選択）"
            Ollama["Ollama<br/>:11434"]
            vLLM["vLLM<br/>Chat :8080<br/>Embed :8081"]
        end

        subgraph "オプション"
            Whisper["文字起こし<br/>Whisper"]
            YOLO["物体検出<br/>YOLOv8"]
        end

        subgraph "認証（選択）"
            Local["ローカル認証"]
            AD["Active Directory<br/>LDAP"]
            Azure["Azure AD<br/>OIDC"]
        end

        User -->|HTTPS| Web
        Web -->|REST API| API
        API --> DB
        API -->|推論| Ollama
        API -->|推論| vLLM
        API --> Whisper
        API --> YOLO
        Web --> Local
        Web --> AD
        Web --> Azure
    end
```

---

## コンポーネント詳細

### フロントエンド

| 項目 | 内容 |
|------|------|
| フレームワーク | Next.js 15 + React 19 |
| ORM | Prisma 7 + @prisma/adapter-pg |
| 認証 | NextAuth v5 (next-auth 5.0) |
| LDAP | ldapts |
| パスワード | bcryptjs (12ラウンド) |
| ポート | 3000 |

### APIサーバー

| 項目 | 内容 |
|------|------|
| フレームワーク | FastAPI (Python) + uvicorn |
| ORM | SQLAlchemy 2.0+ |
| ベクトル検索 | pgvector |
| 文字起こし | pywhispercpp |
| 物体検出 | ultralytics (YOLOv8) |
| DXF処理 | ezdxf + opencv-python + pymupdf |
| ポート | 8000 |

### データベース

| 項目 | 内容 |
|------|------|
| DBMS | PostgreSQL 17 |
| 拡張 | pgvector（ベクトル類似検索） |
| ポート | 5432 |

### LLMエンジン

| エンジン | ポート | 対応OS | GPU要件 |
|---------|--------|--------|---------|
| Ollama | 11434 | macOS / Linux / Windows | 任意（CPU可） |
| vLLM (Chat) | 8080 | Linux | NVIDIA GPU 必須 |
| vLLM (Embed) | 8081 | Linux | NVIDIA GPU 必須 |

**LLM通信方式:**
- APIサーバーは **httpx（Python HTTPクライアント）** でLLMエンジンと通信
- OpenAI SDK は使用せず、`/v1/chat/completions` 等のOpenAI互換エンドポイントに直接HTTPリクエスト
- Ollama / vLLM いずれもOpenAI互換APIを提供するため、同じコードパスで動作
- `VLLM_AUTO_START=false` に設定することで、外部で起動済みのvLLMサーバーにも接続可能

---

## 認証フロー

### ローカル認証（デフォルト）

```mermaid
sequenceDiagram
    participant U as ユーザー
    participant W as Web UI
    participant DB as PostgreSQL

    U->>W: ID/パスワード入力
    W->>DB: ユーザー検索
    DB-->>W: ユーザー情報 + ハッシュ
    W->>W: bcrypt 照合
    W-->>U: JWT発行 (Cookie)
```

### LDAP / Active Directory 認証

```mermaid
sequenceDiagram
    participant U as ユーザー
    participant W as Web UI
    participant AD as Active Directory
    participant DB as PostgreSQL

    U->>W: AD ID/パスワード入力
    W->>AD: LDAP Bind 認証
    AD-->>W: 認証成功 + 属性情報
    W->>DB: ユーザー存在確認
    alt 初回ログイン
        W->>DB: ユーザー自動作成
    end
    W-->>U: JWT発行 (Cookie)
```

### OIDC / Azure AD 認証

```mermaid
sequenceDiagram
    participant U as ユーザー
    participant W as Web UI
    participant AZ as Azure AD
    participant DB as PostgreSQL

    U->>W: 「Azure AD でログイン」
    W->>AZ: OAuth2 認証リクエスト
    AZ->>U: Microsoftログイン画面
    U->>AZ: 認証
    AZ-->>W: IDトークン
    W->>DB: ユーザー存在確認
    alt 初回サインイン
        W->>DB: ユーザー自動作成
    end
    W-->>U: JWT発行 (Cookie)
```

---

## データフロー

### RAG（検索拡張生成）

```mermaid
graph LR
    Upload["ドキュメント<br/>アップロード"]
    API["API Server"]
    Embed["埋め込みモデル<br/>(Ollama/vLLM)"]
    PG["PostgreSQL<br/>pgvector"]
    LLM["LLMモデル"]
    Response["AI回答"]

    Upload --> API
    API -->|テキスト抽出| API
    API -->|ベクトル化| Embed
    Embed -->|埋め込み保存| PG

    Query["ユーザー質問"] --> API
    API -->|類似検索| PG
    PG -->|関連文書| API
    API -->|質問+文書| LLM
    LLM --> Response
```

---

## ポート一覧

| サービス | ポート | プロトコル | 備考 |
|---------|--------|-----------|------|
| Web UI | 3000 | HTTP | フロントエンド |
| API Server | 8000 | HTTP | バックエンド |
| PostgreSQL | 5432 | TCP | データベース |
| Ollama | 11434 | HTTP | LLM（Ollama版） |
| vLLM Chat | 8080 | HTTP | LLM（vLLM版） |
| vLLM Embed | 8081 | HTTP | 埋め込み（vLLM版） |

---

## デプロイ構成パターン

### パターン1: シングルサーバー（推奨）

すべてのコンポーネントを1台のサーバーに配置。

```
1台のサーバー
├── Web UI (:3000)
├── API Server (:8000)
├── PostgreSQL (:5432)
└── Ollama / vLLM
```

### パターン2: Docker Compose

Docker Compose で全コンポーネントをコンテナ化。PostgreSQL も含まれるため個別インストール不要。

### パターン3: 分散配置

GPUサーバーにLLMエンジン、別サーバーにWeb/API/DBを配置。`.env` でURLを指定して接続。

---

## お問い合わせ

**デジタルベース株式会社**
- ウェブサイト: https://digital-base.co.jp
- プロダクトサイト: https://lmlight.jp

---

Copyright (c) 2026 デジタルベース株式会社 All rights reserved.
