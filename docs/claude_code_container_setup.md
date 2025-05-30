# Claude Code専用LXCコンテナ構築手順書

## 概要

VS CodeからSSH接続でClaude Codeを実行するための専用LXCコンテナ環境を構築します。

## 現在のシステム環境

### ホストサーバー詳細
- **OS**: Ubuntu 24.04.2 LTS (Noble Numbat)
- **カーネル**: 6.8.0-59-generic
- **CPU**: 4コア
- **メモリ**: 31GB (利用可能: 15GB)
- **ストレージ**: 1007GB (使用済み: 322GB, 利用可能: 634GB)

### LXD/LXC環境
- **LXD バージョン**: 5.0.4 (Client/Server)
- **ネットワーク**: lxdbr0 (10.x.x.1/24)
- **ストレージプール**: default (dirドライバー)

## 自動セットアップスクリプト

### クイックスタート（推奨）

自動セットアップスクリプトを使用して、セクション2までの手順を一括実行できます：

```bash
# デフォルト設定でセットアップ
./scripts/auto-setup-claude-container.sh

# カスタム名でセットアップ
./scripts/auto-setup-claude-container.sh my-container claude-code-dev

# 外部アクセス対応でセットアップ（自動ポート割り当て）
./scripts/auto-setup-claude-container.sh my-container claude-code-dev --external

# 外部アクセス対応でセットアップ（指定ポート）
./scripts/auto-setup-claude-container.sh my-container claude-code-dev --external 2223

# ヘルプ表示
./scripts/auto-setup-claude-container.sh --help
```

**自動セットアップに含まれる内容：**
- プロファイルの確認
- コンテナの作成
- claude_codeユーザーの作成
- SSH鍵認証の設定
- 追加ツールスクリプトの配置
- claude-configファイルのコピー
- （オプション）外部アクセス設定
  - 動的ポート割り当て（範囲: 2222-2299）
  - ポート競合の自動回避
  - LXD Proxy Deviceの設定
  - fail2ban/ufwのインストールと設定

### 手動セットアップ

詳細な制御が必要な場合は、以下の手動手順を実行してください：

## 1. Claude Code専用プロファイルの作成

### プロファイル作成と設定

```bash
# Claude Code専用プロファイル作成
lxc profile create claude-code-dev

# プロファイル設定
lxc profile edit claude-code-dev << 'EOF'
config:
  limits.cpu: "4"
  limits.memory: 16GB
  limits.memory.swap: "false"
  security.nesting: "true"
  user.user-data: |
    #cloud-config
    package_update: false
    package_upgrade: false
    packages:
      # 基本開発ツール
      - curl
      - wget
      - git
      - vim
      - nano
      - htop
      - tree
      - jq
      - unzip
      - zip
      - build-essential
      - software-properties-common
      
      # mDNS対応
      - avahi-daemon
      - libnss-mdns
      
      # SSH/リモート接続
      - openssh-server
      - openssh-client
      
      # Python開発環境
      - python3
      - python3-pip
      - python3-venv
      - python3-dev
      
      # Rust開発環境 (事前パッケージ)
      - rustc
      - cargo
      
      # システム管理
      - sudo
      - systemd
      
      # Docker (オプション)
      - docker.io
      - docker-compose
      
    runcmd:
      # 基本サービス設定
      - systemctl enable ssh avahi-daemon docker
      - systemctl start ssh avahi-daemon docker
      # claude_codeユーザーの作成
      - useradd -m -s /bin/bash claude_code
      - usermod -aG sudo claude_code
      - echo "claude_code ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/claude_code
      - mkdir -p /home/claude_code/.ssh
      - chmod 700 /home/claude_code/.ssh
      - chown claude_code:claude_code /home/claude_code/.ssh
      - usermod -aG docker claude_code
      
description: Claude Code development environment with SSH access
devices:
  eth0:
    name: eth0
    network: lxdbr0
    type: nic
  root:
    path: /
    pool: default
    size: 80GB
    type: disk
name: claude-code-dev
EOF
```

## 2. Claude Code開発コンテナの作成

### コンテナ作成と初期設定

```bash
# Claude Code開発用コンテナ作成
lxc launch ubuntu:22.04 claude-code-container --profile claude-code-dev

# 起動完了待ち
echo "Waiting for container to start..."
sleep 30

# cloud-init完了待ち
echo "Waiting for cloud-init to complete..."
lxc exec claude-code-container -- cloud-init status --wait

# 基本パッケージのインストール確認
echo "Verifying basic packages..."
lxc exec claude-code-container -- bash -c 'which ssh && which git && which python3' || {
  echo "Basic packages not ready. Waiting additional 10 seconds..."
  sleep 10
}

echo "Container claude-code-container created successfully!"
```

### 追加ツールのセットアップ（手動実行）

基本コンテナ作成後、以下のスクリプトで追加ツールをインストールします：

```bash
# 追加ツールインストールスクリプト
lxc exec claude-code-container -- bash << 'EOF'
echo "=== Additional Tools Installation ==="

# Node.js環境セットアップ（NodeSourceから最新LTS）
echo "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
apt-get install -y nodejs
npm install -g yarn pnpm

# Python環境セットアップ
echo "Setting up Python environment..."
pip3 install --upgrade pip
pip3 install pipenv poetry virtualenv

# Rust環境セットアップ (ubuntuユーザー)
echo "Setting up Rust environment..."
sudo -u claude_code bash -c 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y'
sudo -u claude_code bash -c 'echo "source ~/.cargo/env" >> ~/.bashrc'

# GitHub CLIの設定
echo "Installing GitHub CLI..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh -y

# Claude Code インストール
echo "Installing Claude Code..."
sudo -u claude_code bash -c 'npm install -g @anthropic-ai/claude-code'

# 開発用ディレクトリ作成
echo "Creating development directories..."
sudo -u claude_code mkdir -p /home/claude_code/workspace/{python,rust,nodejs,docker}
sudo -u claude_code mkdir -p /home/claude_code/projects
chown -R claude_code:claude_code /home/claude_code/workspace /home/claude_code/projects

# claude-configディレクトリの配置
echo "Setting up claude-config..."
sudo -u claude_code mkdir -p /home/claude_code/claude-config
# TODO: claude-configファイルのコピーはこの時点で実行

# mDNS設定
echo "Configuring mDNS..."
if ! grep -q "mdns" /etc/nsswitch.conf; then
  sed -i 's/hosts:.*/hosts:          files mdns4_minimal [NOTFOUND=return] dns mdns4/' /etc/nsswitch.conf
fi

echo "=== Additional Tools Installation Completed ==="
EOF
```

## 🌐 外部SSH接続対応

### 外部ネットワークからのアクセス要件

外部（インターネット）からSSH接続してVS Code Remote-SSHで開発する場合、以下の設定が必要です：

#### ネットワーク設定
```bash
# 外部接続対応プロファイルの使用
lxc profile create claude-code-external
lxc profile edit claude-code-external < profiles/claude-code-external.yaml

# bridgedネットワークでホストと同じネットワークに配置
# プロファイル内でbond0（ホストのメインインターフェース）にbridged接続
```

#### SSH公開鍵認証の設定（強く推奨）
```bash
# ホストマシンで公開鍵を生成（まだない場合）
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_claude_container -C "claude-container-access"

# 公開鍵をコンテナに配置
lxc file push ~/.ssh/id_rsa_claude_container.pub claude-code-container/home/claude_code/.ssh/authorized_keys

# 権限設定
lxc exec claude-code-container -- bash << 'EOF'
chmod 600 /home/claude_code/.ssh/authorized_keys
chown claude_code:claude_code /home/claude_code/.ssh/authorized_keys
systemctl restart ssh
EOF
```

#### セキュリティ強化
外部接続対応プロファイルには以下のセキュリティ機能が含まれています：
- **fail2ban**: ブルートフォース攻撃対策
- **UFW firewall**: 基本的なファイアウォール
- **SSH設定強化**: 最大試行回数制限、セッション制限
- **ユーザー制限**: claude_codeユーザーのみアクセス許可


### SSH接続用の設定

#### 方法1: SSHキー認証（推奨）

```bash
# SSHキー設定（ホストで実行）
# 既存のSSHキーがない場合は作成
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
fi

# 公開キーをコンテナに配置
lxc file push ~/.ssh/id_rsa.pub claude-code-container/home/claude_code/.ssh/authorized_keys

# SSH設定
lxc exec claude-code-container -- bash << 'EOF'
# authorized_keysの権限設定
chmod 600 /home/claude_code/.ssh/authorized_keys
chown claude_code:claude_code /home/claude_code/.ssh/authorized_keys

# SSH設定の調整（キー認証のみ許可）
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# SSH再起動
systemctl restart ssh
EOF

echo "SSH key authentication configured!"
```

#### 方法2: パスワード認証（authorized_keysなし）

セキュリティは低下しますが、より簡単な設定方法です：

```bash
# SSH設定（パスワード認証を有効化）
lxc exec claude-code-container -- bash << 'EOF'
# claude_codeユーザーのパスワード設定
# セキュアなパスワードを生成
SECURE_PASSWORD=$(openssl rand -base64 16)
echo "claude_code:$SECURE_PASSWORD" | chpasswd
echo "Password for claude_code user has been set to: $SECURE_PASSWORD"
echo "Please save this password securely!"

# SSH設定の調整（パスワード認証を許可）
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# SSH再起動
systemctl restart ssh
EOF

echo "SSH password authentication configured!"
echo "Warning: Password authentication is less secure than key-based authentication."
```

#### 方法3: ハイブリッド認証（キーとパスワード両方）

開発環境で柔軟性が必要な場合：

```bash
# SSHキーがある場合は設定
if [ -f ~/.ssh/id_rsa.pub ]; then
    lxc file push ~/.ssh/id_rsa.pub claude-code-container/home/claude_code/.ssh/authorized_keys
    lxc exec claude-code-container -- chmod 600 /home/claude_code/.ssh/authorized_keys
    lxc exec claude-code-container -- chown claude_code:claude_code /home/claude_code/.ssh/authorized_keys
fi

# SSH設定（両方の認証方法を許可）
lxc exec claude-code-container -- bash << 'EOF'
# パスワードも設定
# セキュアなパスワードを生成
SECURE_PASSWORD=$(openssl rand -base64 16)
echo "claude_code:$SECURE_PASSWORD" | chpasswd
echo "Password for claude_code user has been set to: $SECURE_PASSWORD"
echo "Please save this password securely!"

# SSH設定の調整
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# SSH再起動
systemctl restart ssh
EOF

echo "SSH hybrid authentication configured!"
```

## 3. コンテナのIPアドレス確認とSSH接続テスト

```bash
# コンテナのIPアドレス確認
CONTAINER_IP=$(lxc list claude-code-container --format json | jq -r '.[0].state.network.eth0.addresses[] | select(.family=="inet") | .address')
echo "Container IP: $CONTAINER_IP"

# SSH接続テスト
echo "Testing SSH connection..."
ssh -o StrictHostKeyChecking=no claude_code@$CONTAINER_IP "echo 'SSH connection successful!'"

# VS Code用SSH設定をホストの~/.ssh/configに追加
# SSHキー認証を使用する場合
if [ -f ~/.ssh/id_rsa ]; then
    cat >> ~/.ssh/config << EOF

# Claude Code Container (Key Authentication)
Host claude-code-dev
    HostName $CONTAINER_IP
    User claude_code
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF
else
    # パスワード認証を使用する場合
    cat >> ~/.ssh/config << EOF

# Claude Code Container (Password Authentication)
Host claude-code-dev
    HostName $CONTAINER_IP
    User claude_code
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    PreferredAuthentications password
EOF
fi

echo "SSH config added. You can now connect with: ssh claude-code-dev"
echo "Note: If using password authentication, you'll be prompted for the password."
```

## 4. Claude Code環境の設定

### 開発用ディレクトリ構造

コンテナ作成時に以下のディレクトリが自動的に作成されます：

```
/home/claude_code/
├── claude-config/  # Claude Code設定ファイル
├── workspace/      # 一時的な作業やテスト用
│   ├── python/     # Python プロジェクト
│   ├── rust/       # Rust プロジェクト
│   ├── nodejs/     # Node.js プロジェクト
│   └── docker/     # Docker 関連ファイル
└── projects/       # 本格的なプロジェクト用
```

**用途説明**：
- `workspace/`: 実験的なコード、学習用プロジェクト、一時的な作業
- `projects/`: 本番プロジェクト、長期的な開発

これらのディレクトリは、LXCプロファイルの`runcmd`セクションで自動作成され、`claude_code`ユーザーが所有者として設定されます。

### コンテナ内でのClaude Code設定

```bash
# コンテナに接続
lxc exec claude-code-container -- sudo -u claude_code bash

# 以下はコンテナ内で実行
cd /home/claude_code

# Claude Codeの設定確認
claude --version

# 開発環境の準備
mkdir -p ~/workspace/{python,rust,nodejs,docker}
mkdir -p ~/projects
mkdir -p ~/.config

# 環境変数設定
cat >> ~/.bashrc << 'EOF'
# Claude Code環境変数
export CLAUDE_CODE_WORKSPACE="/home/claude_code/workspace"
export CLAUDE_CODE_PROJECTS="/home/claude_code/projects"

# Python環境
export PATH="$HOME/.local/bin:$PATH"

# Rust環境
source ~/.cargo/env

# Node.js環境
export PATH="$HOME/.npm-global/bin:$PATH"

# 便利なエイリアス
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias workspace='cd $CLAUDE_CODE_WORKSPACE'
alias projects='cd $CLAUDE_CODE_PROJECTS'
EOF

# .bashrcの読み込み
source ~/.bashrc

# 開発ツールの確認
echo "=== Development Environment Check ==="
echo "Python: $(python3 --version)"
echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"
echo "Rust: $(rustc --version 2>/dev/null || echo 'Not found')"
echo "Docker: $(docker --version)"
echo "Git: $(git --version)"
echo "Claude: $(claude --version)"
```

## 5. VS Code Remote-SSH拡張機能での接続

### VS Codeでの設定手順

1. **Remote-SSH拡張機能のインストール**
   ```
   VS Code > Extensions > "Remote - SSH" をインストール
   ```

2. **SSH接続の設定**
   ```
   Ctrl+Shift+P > "Remote-SSH: Connect to Host..."
   > "claude-code-dev" を選択
   ```
   
   **パスワード認証の場合**：
   - 接続時にパスワード入力プロンプトが表示されます
   - VS Codeにパスワードを保存させたくない場合は、毎回入力が必要です
   - より便利に使うには、SSHキー認証への移行を推奨します

3. **ワークスペースの設定**
   ```
   接続後、File > Open Folder > /home/claude_code/workspace
   ```

### VS Code Remote-SSH設定（外部接続）

#### SSH config設定ファイル
```bash
# ~/.ssh/config に以下を追加
Host claude-container
    HostName [コンテナのIPアドレス]
    User claude_code
    IdentityFile ~/.ssh/id_rsa_claude_container
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ServerAliveInterval 60
    ServerAliveCountMax 3
    ForwardAgent yes
    
# 企業環境等でプロキシが必要な場合
# ProxyCommand nc -X connect -x proxy.company.com:8080 %h %p
```

#### VS Code拡張機能のインストール
1. **Remote - SSH**: `ms-vscode-remote.remote-ssh`
2. **Remote - SSH: Editing Configuration Files**: `ms-vscode-remote.remote-ssh-edit`

#### 接続手順
1. VS Codeを開く
2. `Ctrl+Shift+P` → "Remote-SSH: Connect to Host..."
3. "claude-container" を選択
4. 新しいVS Codeウィンドウが開く
5. ファイル → フォルダを開く → `/home/claude_code/workspace`

### VS Code推奨拡張機能

コンテナ内で以下の拡張機能をインストールすることを推奨：

```json
{
  "recommendations": [
    "ms-python.python",
    "rust-lang.rust-analyzer",
    "ms-vscode.vscode-typescript-next",
    "ms-vscode.vscode-json",
    "redhat.vscode-yaml",
    "ms-vscode.vscode-docker",
    "github.copilot",
    "github.copilot-chat",
    "anthropic.claude-dev"
  ]
}
```

## 6. Claude Code使用例

### プロジェクト作成例

```bash
# SSH接続後、コンテナ内で実行
cd ~/workspace

# Pythonプロジェクト
mkdir python-project && cd python-project
python3 -m venv venv
source venv/bin/activate
pip install requests flask

# Node.jsプロジェクト
mkdir nodejs-project && cd ../nodejs-project
npm init -y
npm install express axios

# Rustプロジェクト
cd ../rust
cargo new hello-rust
cd hello-rust

# Claude Codeでプロジェクトを開く
claude code .
```

### Claude Code基本コマンド

```bash
# Claude Code CLI使用例
claude --help
claude chat "Hello, help me with Python development"
claude code --file main.py "Add error handling to this function"
claude explain --file README.md
```

## 7. 開発環境のカスタマイズ

### 追加開発ツールのインストール

```bash
# Go言語
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc

# Java (OpenJDK)
sudo apt install -y openjdk-17-jdk
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc

# PHP
sudo apt install -y php php-cli php-mbstring php-xml composer

# Ruby
sudo apt install -y ruby-full
gem install bundler

# .NET
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
sudo apt install -y dotnet-sdk-8.0
```

### データベース環境

```bash
# PostgreSQL
sudo apt install -y postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql

# MySQL
sudo apt install -y mysql-server
sudo systemctl start mysql
sudo systemctl enable mysql

# MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo apt update
sudo apt install -y mongodb-org

# Redis
sudo apt install -y redis-server
```

## 8. プロファイルの修正と更新

### 既存のプロファイルを修正する手順

LXCプロファイルは作成後も修正・更新が可能です。以下の方法で変更できます：

#### 方法1: プロファイルを直接編集

```bash
# プロファイルを直接編集（エディタが開く）
lxc profile edit claude-code-dev

# YAMLファイルから更新
lxc profile edit claude-code-dev < profiles/claude-code-dev.yaml
```

#### 方法2: 特定の設定のみ変更

```bash
# CPUリミットの変更
lxc profile set claude-code-dev limits.cpu 8

# メモリリミットの変更
lxc profile set claude-code-dev limits.memory 32GB

# ディスクサイズの変更
lxc profile device set claude-code-dev root size=100GB
```

#### 方法3: プロファイルのコピーと修正

```bash
# 既存プロファイルをコピー
lxc profile copy claude-code-dev claude-code-dev-enhanced

# コピーしたプロファイルを編集
lxc profile edit claude-code-dev-enhanced
```

### 既存コンテナへのプロファイル変更の適用

#### 新しいプロファイルの追加

```bash
# 既存のコンテナに新しいプロファイルを追加
lxc profile add claude-code-container claude-code-dev-enhanced
```

#### プロファイルの置き換え

```bash
# プロファイルを完全に置き換える
lxc profile remove claude-code-container claude-code-dev
lxc profile add claude-code-container claude-code-dev-enhanced

# または一度に置き換え
lxc profile assign claude-code-container claude-code-dev-enhanced
```

### 変更の確認と反映

```bash
# プロファイルの内容確認
lxc profile show claude-code-dev

# コンテナに適用されているプロファイルの確認
lxc config show claude-code-container | grep -A 5 profiles

# 変更を即座に反映（再起動が必要な場合）
lxc restart claude-code-container

# 一部の変更は再起動なしで反映される
# 例：CPUやメモリ制限の変更
```

### プロファイル修正の実例

#### GitHub CLIとmDNSを既存プロファイルに追加

```bash
# 1. 現在のプロファイルをファイルに保存
lxc profile show claude-code-dev > claude-code-dev-backup.yaml

# 2. プロファイルを編集してパッケージを追加
lxc profile edit claude-code-dev
# packagesセクションに以下を追加：
#   - gh
#   - avahi-daemon
#   - libnss-mdns

# 3. 既存のコンテナを更新（新規パッケージのインストール）
lxc exec claude-code-container -- bash << 'EOF'
# GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install -y gh

# mDNS
sudo apt install -y avahi-daemon libnss-mdns
sudo systemctl enable avahi-daemon
sudo systemctl start avahi-daemon
EOF
```

### プロファイルのバックアップとリストア

```bash
# プロファイルのバックアップ
lxc profile show claude-code-dev > profiles/claude-code-dev-$(date +%Y%m%d).yaml

# プロファイルのリストア
lxc profile edit claude-code-dev < profiles/claude-code-dev-20240115.yaml
```

### 注意事項

1. **cloud-init設定**: `user.user-data`の変更は新規コンテナ作成時のみ有効
2. **デバイス設定**: ネットワークやディスクの変更は再起動が必要な場合がある
3. **リソース制限**: CPU/メモリ制限は通常再起動なしで適用される
4. **破壊的変更**: ディスクサイズの縮小などは慎重に行う

## 9. コンテナの管理とメンテナンス

### 自動起動設定

```bash
# コンテナの自動起動を有効化
lxc config set claude-code-container boot.autostart true

# 起動優先度設定
lxc config set claude-code-container boot.autostart.priority 10
```

### バックアップとスナップショット

```bash
# スナップショット作成
lxc snapshot claude-code-container claude-code-clean-install

# スナップショット一覧
lxc info claude-code-container

# スナップショットからの復元
lxc restore claude-code-container claude-code-clean-install

# コンテナのエクスポート
lxc export claude-code-container claude-code-backup.tar.gz
```

### リソース監視

```bash
# リソース使用状況の確認
lxc info claude-code-container

# 詳細なメトリクス
lxc exec claude-code-container -- htop
lxc exec claude-code-container -- df -h
lxc exec claude-code-container -- free -h
```

## 10. トラブルシューティング

### SSH接続の問題

```bash
# SSH接続ができない場合
lxc exec claude-code-container -- systemctl status ssh
lxc exec claude-code-container -- systemctl restart ssh

# ファイアウォールの確認
lxc exec claude-code-container -- ufw status

# ポート確認
lxc exec claude-code-container -- netstat -tlnp | grep :22
```

### パスワード認証が機能しない場合

```bash
# SSH設定の確認
lxc exec claude-code-container -- grep PasswordAuthentication /etc/ssh/sshd_config

# パスワード認証を明示的に有効化
lxc exec claude-code-container -- bash << 'EOF'
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart ssh
EOF

# パスワードの再設定
lxc exec claude-code-container -- passwd claude_code

# SSH接続テスト（詳細ログ付き）
ssh -v -o PreferredAuthentications=password claude_code@$CONTAINER_IP
```

### SSHキー認証に移行する方法

パスワード認証から後でSSHキー認証に変更する場合：

```bash
# 1. SSHキーを生成（まだない場合）
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# 2. 公開キーをコンテナにコピー
ssh-copy-id claude_code@$CONTAINER_IP
# または手動で
cat ~/.ssh/id_rsa.pub | ssh claude_code@$CONTAINER_IP "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# 3. キー認証が動作することを確認
ssh -i ~/.ssh/id_rsa claude_code@$CONTAINER_IP

# 4. パスワード認証を無効化（オプション）
lxc exec claude-code-container -- bash << 'EOF'
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart ssh
EOF
```

### Claude Code関連の問題

```bash
# Claude Codeの再インストール
lxc exec claude-code-container -- sudo -u claude_code bash -c '
  rm -rf ~/.claude
  curl -fsSL https://console.anthropic.com/install.sh | sh
'

# 設定の確認
lxc exec claude-code-container -- sudo -u claude_code claude config show

# ログの確認
lxc exec claude-code-container -- sudo -u claude_code tail -f ~/.claude/logs/claude.log
```

### VS Code接続の問題

```bash
# VS Code Server のリセット
lxc exec claude-code-container -- sudo -u claude_code rm -rf ~/.vscode-server

# SSH設定の確認
cat ~/.ssh/config | grep -A 10 "claude-code-dev"

# SSH接続テスト
ssh -v claude_code@$(lxc list claude-code-container --format json | jq -r '.[0].state.network.eth0.addresses[] | select(.family=="inet") | .address')
```

## 11. トラブルシューティング（追加）

### GitHub CLI関連の問題

```bash
# gh auth loginでブラウザが開けない場合
# SSHセッションではブラウザ認証ができないため、以下の方法を使用：

# 方法1: Personal Access Tokenを使用
# 1. https://github.com/settings/tokens でトークンを作成
# 2. 必要なスコープ: repo, read:org, workflow
# 3. gh auth loginでトークン認証を選択

# 方法2: 既存の認証情報をコピー
# ホストマシンで認証済みの場合
scp ~/.config/gh/hosts.yml claude_code@claude-dev.local:~/.config/gh/

# 認証のリセット
gh auth logout
gh auth login

# 認証情報の確認
gh auth status
gh api user
```

### mDNS接続の問題

```bash
# mDNSが機能しない場合の確認事項

# 1. avahi-daemonの状態確認
lxc exec claude-code-container -- systemctl status avahi-daemon

# 2. ホスト名の確認
lxc exec claude-code-container -- hostname
lxc exec claude-code-container -- cat /etc/hostname

# 3. avahi-browseでサービス確認（ホスト側）
avahi-browse -a

# 4. ファイアウォールの確認
# mDNSはポート5353/UDPを使用
lxc exec claude-code-container -- ufw allow 5353/udp

# 5. nss-mdnsの確認
lxc exec claude-code-container -- cat /etc/nsswitch.conf | grep hosts
```

## 12. セキュリティ設定

### SSH セキュリティ強化

```bash
lxc exec claude-code-container -- bash << 'EOF'
# SSH設定の強化
cat >> /etc/ssh/sshd_config << 'SSH_CONFIG'

# セキュリティ強化設定
Protocol 2
MaxAuthTries 3
MaxSessions 2
ClientAliveInterval 300
ClientAliveCountMax 2
PermitEmptyPasswords no
X11Forwarding no
AllowUsers claude_code
SSH_CONFIG

systemctl restart ssh
EOF
```

### パスワード認証使用時の追加セキュリティ対策

パスワード認証を使用する場合は、以下の対策を推奨します：

```bash
# 強力なパスワードの設定
# パスワード生成の例
openssl rand -base64 16

# fail2banのインストール（ブルートフォース攻撃対策）
lxc exec claude-code-container -- bash << 'EOF'
apt install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban

# SSH用のfail2ban設定
cat > /etc/fail2ban/jail.local << 'F2B_CONFIG'
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
F2B_CONFIG

systemctl restart fail2ban
EOF

# パスワードポリシーの設定
lxc exec claude-code-container -- bash << 'EOF'
# libpam-pwqualityのインストール
apt install -y libpam-pwquality

# パスワード複雑性の設定
sed -i 's/# minlen = 8/minlen = 12/' /etc/security/pwquality.conf
sed -i 's/# dcredit = 0/dcredit = -1/' /etc/security/pwquality.conf
sed -i 's/# ucredit = 0/ucredit = -1/' /etc/security/pwquality.conf
sed -i 's/# lcredit = 0/lcredit = -1/' /etc/security/pwquality.conf
sed -i 's/# ocredit = 0/ocredit = -1/' /etc/security/pwquality.conf
EOF
```

### ファイアウォール設定

```bash
lxc exec claude-code-container -- bash << 'EOF'
# ufw設定
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow from 10.x.x.0/24 to any port 22
ufw status verbose
EOF
```

## 13. Claude Code設定ファイルのセットアップ

### MCP設定（~/.claude.json）

**注意**: 以下の設定例では、filesystem MCPサーバーに特定のディレクトリパスを指定していますが、実際の使用開始時にプロジェクト構造に合わせて調整することをお勧めします。

#### filesystem MCPサーバーの設定について

filesystem MCPサーバーは、Claude Codeが現在の作業ディレクトリ以外のファイルにアクセスする際に必要です。

**初期段階では**：
- filesystem MCPの設定は省略可能です
- 必要になったタイミングで追加することを推奨
- プロジェクトの実際のディレクトリ構造に合わせて設定

**設定が必要になる場合**：
- 複数のプロジェクト間でファイルを参照する必要がある
- システムの設定ファイルやログファイルにアクセスする必要がある
- 共有ライブラリやテンプレートを使用する

### 基本的なMCP設定例

```bash
# コンテナ内でMCP設定ファイルを作成
lxc exec claude-code-container -- sudo -u claude_code bash << 'EOF'
cat > ~/.claude.json << 'MCP_CONFIG'
{
  "mcpServers": {
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/home/claude_code/workspace/projects"
      ]
    },
    
    "github": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
      }
    },
    
    "postgres": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "POSTGRES_CONNECTION_STRING": "postgresql://user:pass@localhost:5432/microservices_db"
      }
    },
    
    "docker": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-docker"]
    }
  }
}
MCP_CONFIG

# パーミッション設定ファイルを作成
mkdir -p ~/.claude
cat > ~/.claude/settings.json << 'PERMISSIONS'
{
  "permissions": {
    "allow": [
      "Edit",
      "Read",
      "WebFetch",
      "Bash(git:*)",
      "Bash(gh:*)",
      "Bash(npm:*)",
      "Bash(npx:*)",
      "Bash(yarn:*)",
      "Bash(node:*)",
      "Bash(docker:*)",
      "Bash(docker-compose:*)",
      "Bash(kubectl:*)",
      "Bash(curl:*)",
      "Bash(jq:*)",
      "Bash(ls:*)",
      "Bash(cat:*)",
      "Bash(grep:*)",
      "Bash(ps:*)",
      "Bash(htop:*)"
    ],
    "deny": [
      "Bash(rm -rf /*)",
      "Bash(sudo rm:*)",
      "Bash(chmod 777:*)"
    ]
  },
  "theme": "dark",
  "notifications": {
    "enabled": true
  }
}
PERMISSIONS

# カスタムコマンドディレクトリの作成
mkdir -p ~/.claude/commands
mkdir -p ~/projects/.claude/commands

# claude-configファイルのコピー (コンテナ作成後に実行)
# cp -r /path/to/claude-config/* ~/claude-config/

echo "Claude Code configuration files created successfully!"
EOF
```

### 環境変数の追加設定

```bash
# コンテナ内で環境変数を追加
lxc exec claude-code-container -- sudo -u claude_code bash << 'EOF'
cat >> ~/.bashrc << 'ENV_VARS'

# MCP関連環境変数
export GITHUB_PERSONAL_ACCESS_TOKEN="your-github-token"
export DATABASE_URL="postgresql://user:pass@localhost:5432/microservices_db"
export REDIS_URL="redis://localhost:6379"

# GitHub CLI用トークン（gh auth loginで設定した場合は不要）
# export GH_TOKEN="your-github-token"

# Docker環境変数
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Node.js環境変数
export NODE_ENV=development

# デバッグ設定
export DEBUG="microservices:*"
export LOG_LEVEL="debug"
ENV_VARS

source ~/.bashrc
echo "Environment variables added successfully!"
EOF
```

## 14. GitHub CLIとmDNSの活用

### GitHub CLI (gh) の使用例

#### 初回認証設定

```bash
# GitHub認証（初回のみ）
gh auth login

# 以下の選択肢が表示されます：
# ? What account do you want to log into? GitHub.com
# ? What is your preferred protocol for Git operations? HTTPS
# ? Authenticate Git with your GitHub credentials? Yes
# ? How would you like to authenticate GitHub CLI? Login with a web browser

# ブラウザ認証の場合：
# ! First copy your one-time code: XXXX-XXXX
# Press Enter to open github.com in your browser...

# SSH経由でコンテナ接続している場合は、Personal Access Tokenを使用：
# ? How would you like to authenticate GitHub CLI? Paste an authentication token
# Tip: you can generate a Personal Access Token here https://github.com/settings/tokens
# The minimum required scopes are 'repo', 'read:org', 'workflow'.
# ? Paste your authentication token: ****************************************

# 認証状態の確認
gh auth status
```

#### よく使うghコマンド

```bash
# リポジトリのクローン
gh repo clone owner/repo

# 現在のリポジトリの情報表示
gh repo view

# プルリクエストの作成
gh pr create --title "Add new feature" --body "Description"

# プルリクエストをブラウザで開く
gh pr view --web

# イシューの作成
gh issue create --title "Bug report" --body "Description"

# プルリクエストの一覧
gh pr list

# 自分のプルリクエストのみ表示
gh pr list --author @me

# リポジトリの作成
gh repo create my-new-repo --public --clone

# ワークフローの実行状況確認
gh run list
gh run view

# gistの作成
gh gist create file.txt --public
```

### mDNS（マルチキャストDNS）の活用

mDNSを有効にすることで、コンテナに`.local`ドメインでアクセスできます：

```bash
# コンテナのホスト名を設定
lxc exec claude-code-container -- hostnamectl set-hostname claude-dev

# mDNSでアクセス（ホストから）
ssh claude_code@claude-dev.local
ping claude-dev.local

# VS Code Remote-SSHの設定を更新
# ~/.ssh/config
Host claude-code-dev
    HostName claude-dev.local
    User claude_code
    IdentityFile ~/.ssh/id_rsa
```

## 15. 使用例とワークフロー

### 典型的な開発ワークフロー

```bash
# 1. VS CodeでSSH接続
# 2. ターミナルでプロジェクト作成
cd ~/workspace
mkdir my-new-project && cd my-new-project

# 3. Git初期化
git init
git remote add origin https://github.com/user/repo.git

# 4. Claude Codeでファイル編集
claude code README.md "Create a comprehensive README for this project"

# 5. 開発開始
code .  # VS Codeでプロジェクトを開く
```

### Claude Codeとの連携例

```bash
# コード生成
claude generate --language python --type "web scraper" --output scraper.py

# コードレビュー
claude review --file app.py

# ドキュメント生成
claude docs --project . --output docs/

# テストコード生成
claude test --file main.py --framework pytest
```

この構築手順により、VS CodeからSSH接続でClaude Codeを快適に利用できる開発環境が完成します。