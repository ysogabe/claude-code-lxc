# Claude Code Configuration Templates

このディレクトリには、Claude Code用の設定テンプレートと適用スクリプトが含まれています。

## 設定テンプレート

### microservices-full.json
マイクロサービス開発用のフル機能設定：
- **MCPサーバー**: filesystem, firecrawl, github, postgres, redis, docker, kubernetes, puppeteer
- **権限**: Docker, Kubernetes, Terraform等のDevOpsツール完全対応
- **カスタムコマンド**: デプロイ、ヘルスチェック機能
- **用途**: 本格的なマイクロサービス開発

### web-development.json
Web開発用の標準設定：
- **MCPサーバー**: filesystem, github, postgres, puppeteer
- **権限**: Node.js、フレームワーク、テストツール中心
- **カスタムコマンド**: コンポーネント作成、プロジェクトセットアップ
- **用途**: React/Vue/Angular等のWeb開発

### data-science.json
データサイエンス用設定：
- **MCPサーバー**: filesystem, postgres, github
- **権限**: Python、R、Julia、Jupyter対応
- **カスタムコマンド**: ノートブック作成、実験実行、データ分析
- **用途**: 機械学習、データ分析、科学計算

### minimal.json
最小構成：
- **MCPサーバー**: filesystemのみ
- **権限**: 基本的なコマンドのみ
- **カスタムコマンド**: なし
- **用途**: シンプルな開発環境、学習用

## 使用方法

### 基本的な使用

```bash
# 現在のユーザー環境に適用
./apply-config.sh web-development

# 特定のコンテナに適用
./apply-config.sh -c claude-code-container microservices-full

# ドライラン（実際には適用せず内容を確認）
./apply-config.sh -d minimal
```

### コンテナ構築時の自動適用

LXCプロファイルと組み合わせて使用する場合は、`profiles/`ディレクトリのプロファイルを修正して、cloud-initで自動適用できます。

```yaml
runcmd:
  # Claude Code設定の自動適用
  - git clone https://github.com/yourusername/claude_code_lxc.git /tmp/claude_code_lxc
  - cd /tmp/claude_code_lxc/claude-config && ./apply-config.sh microservices-full
```

## filesystem MCPサーバーについて

### 重要な注意事項

filesystem MCPサーバーの設定は、実際のプロジェクト構造が確定してから行うことを推奨します。

**理由**：
- プロジェクトの初期段階では、ディレクトリ構造が変更される可能性がある
- 不要なディレクトリへのアクセス権限を与えることはセキュリティ上好ましくない
- Claude Codeは現在の作業ディレクトリ内のファイルには、filesystem MCP なしでアクセス可能

**設定タイミング**：
1. 最初は filesystem MCP を設定しない（または最小限の設定）
2. プロジェクトが成長し、複数のディレクトリ間でファイルを参照する必要が出てきたら追加
3. 実際に必要なディレクトリのみを指定

**設定例**：
```json
// 最小限の設定
"filesystem": {
  "type": "stdio",
  "command": "npx",
  "args": [
    "-y",
    "@modelcontextprotocol/server-filesystem",
    "/home/ubuntu/workspace",
    "/home/ubuntu/projects"
  ]
}

// プロジェクト固有の設定（必要に応じて後から追加）
"filesystem": {
  "type": "stdio",
  "command": "npx",
  "args": [
    "-y",
    "@modelcontextprotocol/server-filesystem",
    "/home/ubuntu/my-app/backend",
    "/home/ubuntu/my-app/frontend",
    "/home/ubuntu/shared-configs",
    "/var/log/my-app"
  ]
}
```

## 設定の構造

各設定JSONファイルは以下の構造を持ちます：

```json
{
  "mcp": {
    "mcpServers": {
      // MCPサーバー設定
    }
  },
  
  "permissions": {
    "permissions": {
      "allow": [...],  // 許可するコマンド
      "deny": [...]    // 拒否するコマンド
    },
    "theme": "dark",
    "notifications": {
      "enabled": true
    }
  },
  
  "environment": {
    // 環境変数
  },
  
  "customCommands": [
    // カスタムコマンド定義
  ]
}
```

## カスタマイズ

### 新しい設定の作成

1. 既存の設定をコピー
   ```bash
   cp web-development.json my-custom.json
   ```

2. 必要に応じて編集
   - MCPサーバーの追加/削除
   - 権限の調整
   - 環境変数の設定
   - カスタムコマンドの追加

3. 適用
   ```bash
   ./apply-config.sh my-custom
   ```

### MCPサーバーの追加例

```json
"my-mcp-server": {
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-example"],
  "env": {
    "API_KEY": "${MY_API_KEY}"
  }
}
```

### カスタムコマンドの追加例

```json
{
  "name": "my-command",
  "description": "My custom command description",
  "content": "Command content with $ARGUMENTS placeholder"
}
```

## 環境変数の参照

設定ファイル内で `${VARIABLE_NAME}` の形式で環境変数を参照できます：
- `${GITHUB_PERSONAL_ACCESS_TOKEN}`
- `${DATABASE_URL}`
- `${REDIS_URL}`

これらは実行時の環境変数から値が取得されます。

## トラブルシューティング

### 設定が適用されない場合

1. jqがインストールされているか確認
   ```bash
   sudo apt install jq
   ```

2. 設定ファイルの構文確認
   ```bash
   jq '.' < microservices-full.json
   ```

3. 権限の確認
   ```bash
   ls -la ~/.claude/
   ```

### MCPサーバーが接続できない場合

1. Node.jsとnpmの確認
   ```bash
   node --version
   npm --version
   ```

2. MCPサーバーパッケージの手動インストール
   ```bash
   npm install -g @modelcontextprotocol/server-filesystem
   ```

## セキュリティ注意事項

- APIキーや認証情報は環境変数で管理してください
- `deny`リストで危険なコマンドをブロックしてください
- コンテナ環境では適切なネットワーク分離を行ってください
