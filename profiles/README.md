# LXC Profiles

このディレクトリには、Claude Code開発環境用のLXCプロファイル定義が含まれています。

## プロファイル一覧

### claude-code-dev.yaml
Claude Code開発環境用の標準プロファイル。以下の特徴を持ちます：

- **リソース制限**: 4 CPU、16GB RAM、80GB ストレージ
- **ネットワーク**: lxdbr0ブリッジ接続
- **セキュリティ**: ネスティング有効（Docker実行用）
- **ユーザー**: claude_codeユーザーを自動作成
- **自動セットアップ**: cloud-initによる初期設定
- **SSH**: 公開鍵認証対応

### claude-code-minimal.yaml
最小構成のプロファイル：

- **リソース制限**: 2 CPU、8GB RAM、40GB ストレージ
- **パッケージ**: 最小限の開発ツールのみ
- **用途**: リソースが限られた環境向け

### sample/
その他のサンプルプロファイルが保存されています：

- **claude-code-dev-auto.yaml**: 自動化検証用
- **claude-code-dev-verified.yaml**: 検証済み設定
- **claude-code-external.yaml**: 外部接続対応版
- **claude-code-external-fixed.yaml**: 外部接続固定設定版

## 使用方法

### プロファイルの適用

```bash
# プロファイルの作成
lxc profile create claude-code-dev

# YAMLファイルからプロファイルを読み込む
lxc profile edit claude-code-dev < profiles/claude-code-dev.yaml

# または、パイプを使用
cat profiles/claude-code-dev.yaml | lxc profile edit claude-code-dev
```

### コンテナの作成

```bash
# プロファイルを使用してコンテナを作成
lxc launch ubuntu:22.04 my-claude-container --profile claude-code-dev
```

### 既存コンテナへの適用

```bash
# 既存のコンテナにプロファイルを適用
lxc profile add my-existing-container claude-code-dev
```

## プロファイルのカスタマイズ

プロファイルを環境に合わせてカスタマイズする場合：

1. YAMLファイルをコピー
   ```bash
   cp claude-code-dev.yaml claude-code-custom.yaml
   ```

2. 必要に応じて編集
   - `limits.cpu`: CPU数の変更
   - `limits.memory`: メモリサイズの変更
   - `packages`: インストールパッケージの追加/削除
   - `runcmd`: 初期化コマンドの変更

3. カスタムプロファイルの作成
   ```bash
   lxc profile create claude-code-custom
   lxc profile edit claude-code-custom < claude-code-custom.yaml
   ```

## プロファイルの内容

### リソース設定
- **CPU**: 4コア
- **メモリ**: 16GB
- **スワップ**: 無効
- **ストレージ**: 80GB

### 自動インストールされるパッケージ
- 基本開発ツール（git、vim、curl、htop、tree、jq等）
- Python開発環境（python3、pip、venv、dev tools）
- Rust開発環境（rustc、cargo）
- Docker/Docker Compose
- SSH サーバー・クライアント
- mDNS対応（avahi-daemon、libnss-mdns）
- ビルドツール（build-essential）

### 自動実行される設定
- claude_codeユーザーの作成とsudo権限付与
- SSHディレクトリの設定（/home/claude_code/.ssh）
- Docker、SSH、avahi-daemonサービスの有効化
- claude_codeユーザーをdockerグループに追加

### 追加でインストールされるツール（setup-additional-tools.sh実行後）
- Node.js v22.x（最新LTS）+ npm、yarn、pnpm
- Claude Code CLI（npm経由）
- GitHub CLI（gh）
- Python追加ツール（pipenv、poetry、virtualenv）
- Rust最新版（rustup経由）

## プロファイルの修正と更新

### 既存プロファイルの編集

```bash
# 直接編集
lxc profile edit claude-code-dev

# YAMLファイルから更新
lxc profile edit claude-code-dev < claude-code-dev.yaml

# 特定の値のみ変更
lxc profile set claude-code-dev limits.cpu 8
lxc profile set claude-code-dev limits.memory 32GB
```

### プロファイルのバージョン管理

```bash
# 変更前にバックアップ
lxc profile show claude-code-dev > claude-code-dev-backup-$(date +%Y%m%d).yaml

# 変更履歴の管理（Gitを使用）
git add profiles/
git commit -m "Update claude-code-dev profile: Add GitHub CLI and mDNS support"
```

### 既存コンテナへの変更適用

**重要**: cloud-init設定（packagesやruncmd）は新規コンテナ作成時のみ実行されます。既存コンテナに新しいパッケージを追加する場合は、手動でインストールする必要があります。

```bash
# 例：GitHub CLIを既存コンテナに追加
lxc exec my-container -- bash << 'EOF'
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install -y gh
EOF
```

## トラブルシューティング

### プロファイルが適用されない場合
```bash
# プロファイルの確認
lxc profile show claude-code-dev

# コンテナに適用されているプロファイルの確認
lxc config show my-container
```

### cloud-initの実行状況確認
```bash
# cloud-initのステータス確認
lxc exec my-container -- cloud-init status

# cloud-initのログ確認
lxc exec my-container -- cat /var/log/cloud-init.log
```