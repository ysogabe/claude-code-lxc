# 外部SSH接続対応設計書

## 🎯 要件定義

### 主要要件
1. **外部ネットワークからのSSH接続**: インターネット経由でのアクセス
2. **VS Code Remote-SSH対応**: VS Codeの拡張機能での開発
3. **セキュアな接続**: 適切な認証とファイアウォール設定
4. **開発環境の完全性**: コンテナ内でのフル開発機能

### 技術要件
- SSH公開鍵認証（推奨）
- パスワード認証（バックアップ）
- ポートフォワーディング対応
- ホストネットワーク経由のアクセス

## 🏗️ アーキテクチャ設計

### ネットワーク構成
```
外部クライアント → ホストサーバー → LXCコンテナ
     ↓                    ↓              ↓
  VS Code        Proxy Device      SSH Server
  SSH Client    (Port 2222→22)    (Port 22)
```

### 採用方式: LXD Proxy Device

```yaml
devices:
  ssh-proxy:
    type: proxy
    listen: tcp:0.0.0.0:2222
    connect: tcp:127.0.0.1:22
```

この方式により、コンテナの内部ネットワークを保護しながら、特定のポートのみを外部に公開できます。

## 🔒 セキュリティ設計

### SSH認証強化
1. **公開鍵認証の推奨**
2. **パスワード認証**（バックアップ用）
3. **fail2ban導入**（ブルートフォース対策）
4. **SSH設定強化**（最大試行回数、セッション制限）

### ファイアウォール設定
```bash
# コンテナ側UFW設定
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow from 10.119.132.0/24  # LXD bridgeからのアクセス
```

### fail2ban設定
```
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
```

## 🛠️ 実装構成

### ネットワーク設定
- **接続方式**: LXD Proxy Device
- **外部ポート**: 2222
- **内部ポート**: 22（SSH標準）
- **ネットワーク**: lxdbr0（内部ブリッジ）

### SSH設定
- **認証方式**: 公開鍵認証（推奨） + パスワード認証（バックアップ）
- **許可ユーザー**: ubuntuのみ
- **rootログイン**: 無効
- **X11転送**: 有効（VS Code用）

## 📋 接続情報

### SSH設定例（~/.ssh/config）
```
Host claude-container
    HostName [ホストの外部IP]
    Port 2222
    User ubuntu
    IdentityFile ~/.ssh/id_rsa_claude_container
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ServerAliveInterval 60
    ServerAliveCountMax 3
    ForwardAgent yes
```

### VS Code Remote-SSH設定
1. Remote-SSH拡張機能をインストール
2. 上記SSH設定を追加
3. `Ctrl+Shift+P` → "Remote-SSH: Connect to Host..."
4. "claude-container"を選択

## 🚨 セキュリティ注意事項

### 推奨事項
1. **定期的な鍵の更新**: 3-6ヶ月ごと
2. **ログの監視**: /var/log/auth.logの定期確認
3. **システム更新**: セキュリティパッチの適用
4. **バックアップ**: コンテナスナップショットの定期作成

### 運用時の注意
- fail2banのBANリストの定期確認
- 不審なアクセスパターンの監視
- 使用しない時はコンテナの停止も検討