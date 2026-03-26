# Linux サーバー ネットワーク接続ガイド

Ubuntu PC を他のデバイスからアクセスできるサーバーにする方法を説明します。

---

## 1. 直接接続（ルーターなし）

PC 同士を LAN ケーブルで直結する場合。ルーターや DHCP がないため、手動で IP を設定します。

```
┌──────────────┐    LAN ケーブル直結    ┌──────────────┐
│ クライアント PC │◄──────────────────►│  サーバー PC   │
│ 192.168.*.*  │                     │ 192.168.*.*  │
└──────────────┘                     └──────────────┘
※ 同じサブネット内で異なる IP を割り当てる
```

### サーバー側 (Ubuntu)

**1. インターフェース名を確認:**

```bash
ip link show
```

`eth0`, `enp0s3` 等の名前をメモします。

**2. 固定 IP を設定:**

```bash
sudo ip addr add 192.168.*.*/24 dev eth0
```

永続化する場合は netplan を使用:

```bash
sudo nano /etc/netplan/01-direct.yaml
```

```yaml
network:
  version: 2
  ethernets:
    eth0:  # インターフェース名に合わせる
      dhcp4: no
      addresses:
        - 192.168.*.*/24
```

```bash
sudo netplan apply
```

**3. ファイアウォールを開放:**

```bash
sudo ufw allow 3000/tcp
sudo ufw allow 8000/tcp
sudo ufw reload
```

### クライアント側

**Windows:**

1. 設定 → ネットワーク → イーサネット → IP 設定 → 編集
2. IP: `192.168.*.*`、サブネット: `255.255.255.0`

**macOS:**

1. システム設定 → ネットワーク → Ethernet → 詳細 → TCP/IP
2. 手動、IP: `192.168.*.*`、サブネット: `255.255.255.0`

**Linux:**

```bash
sudo ip addr add 192.168.*.*/24 dev eth0
```

### アクセス

```
http://192.168.*.*:8000
```

---

## 2. LAN 経由接続（ルーターあり）

ルーターや社内ネットワーク経由で接続する場合。DHCP が IP を自動割当します。

```
┌──────────────┐                    ┌──────────────┐
│ クライアント  │◄──── ルーター ────►│   サーバー    │
└──────────────┘     (DHCP)        └──────────────┘
```

### サーバー側 (Ubuntu)

**1. IP アドレスを確認:**

```bash
ip addr show | grep "inet " | grep -v 127.0.0.1
```

**2. 固定 IP を設定（推奨）:**

DHCP では IP が変わる可能性があるため、固定 IP を推奨します。

```bash
sudo nano /etc/netplan/01-netcfg.yaml
```

```yaml
network:
  version: 2
  ethernets:
    enp0s3:  # インターフェース名（ip link show で確認）
      dhcp4: no
      addresses:
        - 192.168.*.*/24
      routes:
        - to: default
          via: 192.168.*.*  # ルーターの IP
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
```

```bash
sudo netplan apply
```

**3. ファイアウォールを開放:**

```bash
sudo ufw allow 3000/tcp
sudo ufw allow 8000/tcp
sudo ufw reload
```

### アクセス

```
http://192.168.*.*:8000
```

---

## 3. ホスト名でアクセス

IP アドレスの代わりに名前（例: `http://lmlight`）でアクセスする方法。

### 方法 A: hosts ファイル（簡単）

各クライアント PC に設定します。

**Linux / macOS:**

```bash
sudo nano /etc/hosts
```

```
192.168.*.*  lmlight
```

**Windows:**

1. メモ帳を**管理者として実行**
2. `C:\Windows\System32\drivers\etc\hosts` を開く
3. `192.168.*.*  lmlight` を追加して保存

→ `http://lmlight:8000` でアクセス可能

### 方法 B: mDNS / Avahi（設定不要）

サーバー側に Avahi をインストールすると、`http://<ホスト名>.local` で自動的にアクセス可能になります。

```bash
sudo apt install -y avahi-daemon libnss-mdns
sudo systemctl enable avahi-daemon
sudo ufw allow 5353/udp
```

ホスト名を変更する場合:

```bash
sudo hostnamectl set-hostname lmlight
sudo systemctl restart avahi-daemon
```

→ `http://lmlight.local:8000` でアクセス可能

**注意:** Windows は mDNS サポートが限定的です（Bonjour がインストールされている場合のみ）。

### 方法 C: 社内 DNS

社内に DNS サーバーがある場合:

```
lmlight.company.local → 192.168.*.*
```

→ すべてのデバイスから `http://lmlight.company.local:8000` でアクセス可能

---

## 4. ポート番号なしでアクセス（Nginx）

`:8000` を省略して `http://lmlight` だけでアクセスしたい場合。

**1. Nginx をインストール:**

```bash
sudo apt install nginx
```

**2. 設定ファイルを作成:**

```bash
sudo nano /etc/nginx/sites-available/lmlight
```

```nginx
server {
    listen 80;
    server_name lmlight lmlight.local;

    location / {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_buffering off;
    }

    location /api {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**3. 有効化:**

```bash
sudo ln -s /etc/nginx/sites-available/lmlight /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
sudo ufw allow 80/tcp
```

→ `http://lmlight` でアクセス可能

---

## 5. セキュリティ

### ファイアウォールで IP 制限

```bash
sudo ufw default deny incoming
sudo ufw allow from 192.168.*.* to any port 8000 proto tcp
sudo ufw allow from 192.168.*.* to any port 8000 proto tcp
sudo ufw enable
```

### HTTPS（自己署名証明書）

```bash
sudo mkdir -p /etc/nginx/ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/server.key \
  -out /etc/nginx/ssl/server.crt \
  -subj "/CN=lmlight"
```

Nginx の `server` ブロックを HTTPS に変更:

```nginx
server {
    listen 443 ssl;
    server_name lmlight lmlight.local;

    ssl_certificate /etc/nginx/ssl/server.crt;
    ssl_certificate_key /etc/nginx/ssl/server.key;
    ssl_protocols TLSv1.2 TLSv1.3;

    # location ブロックは同じ
}
```

```bash
sudo nginx -t && sudo systemctl reload nginx
sudo ufw allow 443/tcp
```

**注意:** 自己署名証明書はブラウザで警告が出ます。

---

## トラブルシューティング

| 問題 | 原因 | 解決方法 |
|-----|------|---------|
| 接続できない | ファイアウォール | `sudo ufw status` で確認、ポート開放 |
| タイムアウト | 別ネットワーク | 同じサブネットか確認（`ping 192.168.*.*`） |
| IP が変わる | DHCP | 固定 IP を設定 |
| 直結で繋がらない | IP 未設定 | 両方の PC に手動で IP を設定 |
| .local が解決できない | mDNS 未設定 | Avahi をインストール、または hosts ファイルを使用 |
