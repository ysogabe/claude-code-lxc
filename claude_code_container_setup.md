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
- **ネットワーク**: lxdbr0 (10.119.132.1/24)
- **ストレージプール**: default (dirドライバー)

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
    package_update: true
    package_upgrade: true
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
      
      # SSH/リモート接続
      - openssh-server
      - openssh-client
      
      # Claude Code実行環境
      - nodejs
      - npm
      
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
      # SSH設定
      - systemctl enable ssh
      - systemctl start ssh
      - mkdir -p /home/ubuntu/.ssh
      - chmod 700 /home/ubuntu/.ssh
      - chown ubuntu:ubuntu /home/ubuntu/.ssh
      
      # sudoers設定
      - echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/ubuntu
      
      # Node.js環境セットアップ
      - curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
      - apt-get install -y nodejs
      - npm install -g yarn pnpm
      
      # Python環境セットアップ
      - pip3 install --upgrade pip
      - pip3 install pipenv poetry virtualenv
      
      # Rust環境セットアップ (ubuntuユーザー)
      - sudo -u ubuntu bash -c 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y'
      - sudo -u ubuntu bash -c 'echo "source ~/.cargo/env" >> ~/.bashrc'
      
      # Docker設定
      - systemctl enable docker
      - systemctl start docker
      - usermod -aG docker ubuntu
      
      # Claude Code インストール
      - sudo -u ubuntu bash -c 'curl -fsSL https://console.anthropic.com/install.sh | sh'
      
      # 開発用ディレクトリ作成
      - sudo -u ubuntu mkdir -p /home/ubuntu/workspace
      - sudo -u ubuntu mkdir -p /home/ubuntu/projects
      - chown -R ubuntu:ubuntu /home/ubuntu/workspace
      - chown -R ubuntu:ubuntu /home/ubuntu/projects
      
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

echo "Container claude-code-container created successfully!"
```

### SSH接続用の設定

```bash
# SSHキー設定（ホストで実行）
# 既存のSSHキーがない場合は作成
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
fi

# 公開キーをコンテナに配置
lxc file push ~/.ssh/id_rsa.pub claude-code-container/home/ubuntu/.ssh/authorized_keys

# SSH設定
lxc exec claude-code-container -- bash << 'EOF'
# authorized_keysの権限設定
chmod 600 /home/ubuntu/.ssh/authorized_keys
chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys

# SSH設定の調整
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# SSH再起動
systemctl restart ssh

# ubuntuユーザーのパスワード設定（オプション、SSH鍵認証推奨）
# echo "ubuntu:your-secure-password" | chpasswd
EOF

echo "SSH configuration completed!"
```

## 3. コンテナのIPアドレス確認とSSH接続テスト

```bash
# コンテナのIPアドレス確認
CONTAINER_IP=$(lxc list claude-code-container --format json | jq -r '.[0].state.network.eth0.addresses[] | select(.family=="inet") | .address')
echo "Container IP: $CONTAINER_IP"

# SSH接続テスト
echo "Testing SSH connection..."
ssh -o StrictHostKeyChecking=no ubuntu@$CONTAINER_IP "echo 'SSH connection successful!'"

# VS Code用SSH設定をホストの~/.ssh/configに追加
cat >> ~/.ssh/config << EOF

# Claude Code Container
Host claude-code-dev
    HostName $CONTAINER_IP
    User ubuntu
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF

echo "SSH config added. You can now connect with: ssh claude-code-dev"
```

## 4. Claude Code環境の設定

### コンテナ内でのClaude Code設定

```bash
# コンテナに接続
lxc exec claude-code-container -- sudo -u ubuntu bash

# 以下はコンテナ内で実行
cd /home/ubuntu

# Claude Codeの設定確認
claude --version

# 開発環境の準備
mkdir -p ~/workspace/{python,rust,nodejs,docker}
mkdir -p ~/projects
mkdir -p ~/.config

# 環境変数設定
cat >> ~/.bashrc << 'EOF'
# Claude Code環境変数
export CLAUDE_CODE_WORKSPACE="/home/ubuntu/workspace"
export CLAUDE_CODE_PROJECTS="/home/ubuntu/projects"

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

3. **ワークスペースの設定**
   ```
   接続後、File > Open Folder > /home/ubuntu/workspace
   ```

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

## 8. コンテナの管理とメンテナンス

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

## 9. トラブルシューティング

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

### Claude Code関連の問題

```bash
# Claude Codeの再インストール
lxc exec claude-code-container -- sudo -u ubuntu bash -c '
  rm -rf ~/.claude
  curl -fsSL https://console.anthropic.com/install.sh | sh
'

# 設定の確認
lxc exec claude-code-container -- sudo -u ubuntu claude config show

# ログの確認
lxc exec claude-code-container -- sudo -u ubuntu tail -f ~/.claude/logs/claude.log
```

### VS Code接続の問題

```bash
# VS Code Server のリセット
lxc exec claude-code-container -- sudo -u ubuntu rm -rf ~/.vscode-server

# SSH設定の確認
cat ~/.ssh/config | grep -A 10 "claude-code-dev"

# SSH接続テスト
ssh -v ubuntu@$(lxc list claude-code-container --format json | jq -r '.[0].state.network.eth0.addresses[] | select(.family=="inet") | .address')
```

## 10. セキュリティ設定

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
AllowUsers ubuntu
SSH_CONFIG

systemctl restart ssh
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
ufw allow from 10.119.132.0/24 to any port 22
ufw status verbose
EOF
```

## 11. Claude Code設定ファイルのセットアップ

### MCP設定（~/.claude.json）

```bash
# コンテナ内でMCP設定ファイルを作成
lxc exec claude-code-container -- sudo -u ubuntu bash << 'EOF'
cat > ~/.claude.json << 'MCP_CONFIG'
{
  "mcpServers": {
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/home/ubuntu/microservices",
        "/home/ubuntu/docker-configs",
        "/home/ubuntu/k8s-manifests"
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

echo "Claude Code configuration files created successfully!"
EOF
```

### 環境変数の追加設定

```bash
# コンテナ内で環境変数を追加
lxc exec claude-code-container -- sudo -u ubuntu bash << 'EOF'
cat >> ~/.bashrc << 'ENV_VARS'

# MCP関連環境変数
export GITHUB_PERSONAL_ACCESS_TOKEN="your-github-token"
export DATABASE_URL="postgresql://user:pass@localhost:5432/microservices_db"
export REDIS_URL="redis://localhost:6379"

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

## 12. 使用例とワークフロー

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