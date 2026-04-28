# Linux サーバー ネットワーク接続ガイド

Ubuntu PC を他のデバイスからアクセスできるサーバーにする方法です。

---

## 0. サーバー初期設定 (Avahiでホスト名を振る)

直繋ぎ・LAN経由どちらでも共通の最初の一手。**`digitalbase.local` でアクセス可能**になります。

```bash
sudo apt install -y avahi-daemon libnss-mdns
sudo hostnamectl set-hostname digitalbase
sudo systemctl enable --now avahi-daemon
sudo ufw allow 8000/tcp
sudo ufw allow 5353/udp
```

> macOS / iOS / Android / Windows 10 (1803以降) は `.local` に標準対応。Avahi は link-local (169.254.x.x) でもアドバタイズするため、**直繋ぎでも同じ URL が使えます**。

ホスト名を変える場合: `sudo hostnamectl set-hostname <名前>` → `sudo systemctl restart avahi-daemon`

---

## 1. 直繋ぎ (LANケーブル1本でPC↔PC)

ルーター無しで2台を直結する場合。

### 方法A: ゼロコンフィグ (推奨)

両側を**Ethernet自動取得 (DHCP)** のままにしておきます。DHCPサーバーが居ないので両側が link-local (169.254.x.x) を取得し、Avahi が名前解決してくれます。

```
LANケーブルを挿す → 1〜2分待つ → http://digitalbase.local:8000
```

#### 各OSの「自動取得」状態

| OS | 既定 | 確認/戻し方 |
|----|------|-----------|
| **Windows** | DHCP (デフォルト) | 設定 → ネットワーク → イーサネット → IP設定が「自動 (DHCP)」ならOK |
| **macOS** | DHCP (デフォルト) | システム設定 → ネットワーク → Ethernet → 詳細 → TCP/IP → 「IPv4を構成: DHCPサーバを使用」 |
| **Linux** | NetworkManager の場合DHCP既定 | `nmcli device show` で `ipv4.method: auto` を確認 |

**過去に手動IPを設定したことがあるPCは、必ず自動取得に戻してください**。手動のままだとサーバーと別サブネットになって繋がりません。

#### 動作確認

クライアント側で:
```bash
ping digitalbase.local
```
→ 応答が返れば成功。返らない場合はクライアントのIPを確認 (`ipconfig` / `ip addr`) し、`169.254.x.x` になっていなければ自動取得設定を見直す。

### 方法B: 手動IP (確実)

方法AがダメならIPを固定:

**サーバー側:**
```bash
sudo ip addr add 192.168.10.1/24 dev eth0   # eth0 は ip link show で確認
```

**クライアント側** (サーバーと**異なるIP**・同じサブネット):
- **Windows:** 設定 → ネットワーク → イーサネット → IP 設定 → 編集 → 手動 → IP `192.168.10.2` / サブネット `255.255.255.0`
- **macOS:** システム設定 → ネットワーク → Ethernet → 詳細 → TCP/IP → 手動
- **Linux:** `sudo ip addr add 192.168.10.2/24 dev eth0`

アクセス: `http://digitalbase.local:8000` または `http://192.168.10.1:8000`

### 直繋ぎが不安定な場合 (物理層対策)

直繋ぎはスイッチが間に居ないため、NIC同士のリンクネゴシエーションが乱れがち。効果が大きい順に:

1. **千円程度のGbEスイッチを挟む** ← 一番効く・一発解決
2. **NICのEEE/省電力を無効化**
   - Windows: デバイスマネージャー → NIC → 詳細設定 → 「Energy Efficient Ethernet」無効、電源管理オフ
   - Linux: `sudo ethtool --set-eee eth0 eee off`
3. **Cat6以上の短いケーブル** (1m程度推奨)
4. **USB-Ethernetアダプタを避ける** (内蔵NICの方が安定)

---

## 2. LAN経由 (既存のルーター/社内ネットワーク)

ルーターのDHCPでIPが自動割当されます。**サーバー初期設定 (セクション0) だけでOK**。

```
http://digitalbase.local:8000
```

### IPを固定したい場合

**ルーターの管理画面で「DHCP予約」** を設定するのが一番簡単 (サーバーのMACアドレスに特定IPを紐付け)。

netplan で固定する場合は `/etc/netplan/01-netcfg.yaml`:

```yaml
network:
  version: 2
  ethernets:
    enp0s3:    # ip link show で確認
      dhcp4: no
      addresses: [192.168.1.100/24]
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
```

```bash
sudo netplan apply
```

---

## 3. クラウド構築の場合

VPS / AWS EC2 / GCP / Azure 等のクラウドにデプロイする場合。**mDNS (`.local`) は使えない** ので、固定IPかDNSで名前解決します。

### 3-1. 固定IP (Elastic IP / 静的IP) を割り当て

クラウドの管理画面で:
- AWS: Elastic IP を確保 → インスタンスにアタッチ
- GCP: 静的外部IPアドレスを予約
- Azure: パブリックIPアドレスを「静的」に変更

### 3-2. ファイアウォール / セキュリティグループ

**インスタンスのファイアウォール (ufw) と、クラウド側のセキュリティグループの両方** を許可:

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

クラウド側:
- AWS: Security Group のインバウンドで 80/443 を `0.0.0.0/0` または許可IPレンジ
- GCP: VPC ファイアウォールルールで同様
- Azure: NSG (Network Security Group)

### 3-3. ドメイン + DNS

固定IPだけでも動きますが、HTTPS化のためドメイン推奨:
1. ドメインを取得 (Cloudflare、お名前.com、Route53等)
2. **A レコード**で固定IPを指す: `digitalbase.example.com → 203.0.113.10`
3. 反映確認: `dig digitalbase.example.com`

### 3-4. HTTPS 化 (Let's Encrypt)

セクション4のNginxを設定後:

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d digitalbase.example.com
```

→ 90日ごとに自動更新。`http://digitalbase.example.com` から自動で HTTPS にリダイレクトされます。

---

## 4. Nginxでアドレス固定 (ポート省略・URL統一)

`http://digitalbase.local:8000` の `:8000` を省略して `http://digitalbase` だけでアクセスしたい場合。クラウド構築でも同じ手順。

### 4-1. インストールと設定

```bash
sudo apt install -y nginx
sudo nano /etc/nginx/sites-available/digitalbase
```

```nginx
server {
    listen 80;
    server_name digitalbase digitalbase.local digitalbase.example.com;   # 環境に合わせて

    client_max_body_size 100M;   # 大きなファイルアップロード用

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
        proxy_read_timeout 300s;     # LLMの長時間レスポンス対応
    }
}
```

### 4-2. 有効化

```bash
sudo ln -s /etc/nginx/sites-available/digitalbase /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
sudo ufw allow 80/tcp
```

→ `http://digitalbase` (LAN内) または `http://digitalbase.example.com` (クラウド) でアクセス可能。

### 4-3. メリット

- **ポート省略**: `:8000` 不要 → 一般ユーザーが覚えやすいURL
- **URL統一**: バックエンドのポート変更があっても外向きURLは固定
- **HTTPS化が容易**: certbot が Nginx 設定を自動更新
- **将来の拡張**: ロードバランス・キャッシュ・アクセスログを Nginx で集約

---

## 5. セキュリティ (LAN内のみ許可)

クラウドではなく社内/家庭内サーバーの場合:

```bash
sudo ufw default deny incoming
sudo ufw allow from 192.168.0.0/16 to any port 80 proto tcp
sudo ufw allow from 169.254.0.0/16 to any port 80 proto tcp   # 直繋ぎ用
sudo ufw allow 5353/udp                                        # mDNS
sudo ufw enable
```

---

## トラブルシューティング

| 症状 | 確認 | 対処 |
|-----|------|------|
| `.local` が効かない | `systemctl status avahi-daemon` | Avahi 起動、UDP 5353 開放 |
| 直繋ぎで繋がらない (初回) | クライアント側のIP | 1〜2分待つ (link-local 取得に時間がかかる) |
| 直繋ぎで繋がらない (待っても) | 両側のIP種別 | 両側を揃える (両DHCP or 両手動) |
| 直繋ぎで途中で切れる | NICの省電力設定 | EEE無効化、GbEスイッチを挟む |
| DHCPでIPが変わる | ルーター設定 | DHCP予約 |
| Windowsで `.local` 不可 | Windowsバージョン | Win10 1803以降は標準対応。古い場合は hosts ファイル |
| クラウドで繋がらない | セキュリティグループ | クラウド側のFWでもポート開放が必要 |
| HTTPS証明書エラー | DNS 反映 | `dig` でAレコード確認、反映に時間がかかる |
