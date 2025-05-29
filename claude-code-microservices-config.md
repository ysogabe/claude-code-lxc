# Claude Code マイクロサービス開発設定ガイド

## 概要

このガイドでは、Webマイクロサービス開発に特化したClaude Codeの設定方法について説明します。コンテナ化、オーケストレーション、API開発、テスト、デプロイ、監視まで包括的にカバーしています。

## 1. 設定ファイル構造

**重要**: このガイドのJSON例では説明のためにコメント（//）を使用していますが、実際のJSONファイルではコメントは使用できません。実際の設定ファイルではコメントを削除してください。

### 設定ファイルの階層（優先順位順）
1. **Enterprise Policy Settings** (最高優先度)
   - macOS: `/Library/Application Support/ClaudeCode/policies.json`
   - Linux: `/etc/claude-code/policies.json`

2. **User Settings** (ユーザーグローバル設定)
   - `~/.claude/settings.json`

3. **Project Settings** (プロジェクト共有設定)
   - `.claude/settings.json`

4. **Local Project Settings** (個人設定)
   - `.claude/settings.local.json`

5. **MCP設定**
   - `~/.claude.json` (グローバル)
   - `.claude.json` (プロジェクト固有)

## 2. 権限設定（Permissions）

### ~/.claude/settings.json
```json
{
  "permissions": {
    "allow": [
      "Edit",
      "Read",
      "WebFetch",
      
      // Git操作
      "Bash(git:*)",
      
      // Node.js/JavaScript
      "Bash(npm:*)",
      "Bash(npx:*)",
      "Bash(yarn:*)",
      "Bash(pnpm:*)",
      "Bash(node:*)",
      "Bash(nvm:*)",
      
      // フレームワーク・ビルドツール
      "Bash(next:*)",
      "Bash(vite:*)",
      "Bash(webpack:*)",
      "Bash(turbo:*)",
      "Bash(lerna:*)",
      "Bash(nx:*)",
      
      // コンテナ・オーケストレーション
      "Bash(docker:*)",
      "Bash(docker-compose:*)",
      "Bash(podman:*)",
      "Bash(kubectl:*)",
      "Bash(helm:*)",
      "Bash(k9s:*)",
      "Bash(skaffold:*)",
      
      // API・テスト
      "Bash(curl:*)",
      "Bash(wget:*)",
      "Bash(jq:*)",
      "Bash(newman:*)",
      "Bash(jest:*)",
      "Bash(cypress:*)",
      "Bash(playwright:*)",
      "Bash(k6:*)",
      
      // マイクロサービス特有ツール
      "Bash(istioctl:*)",
      "Bash(linkerd:*)",
      "Bash(consul:*)",
      "Bash(vault:*)",
      "Bash(envoy:*)",
      
      // 監視・ロギング
      "Bash(prometheus:*)",
      "Bash(grafana-cli:*)",
      "Bash(jaeger:*)",
      "Bash(zipkin:*)",
      
      // クラウドCLI
      "Bash(aws:*)",
      "Bash(gcloud:*)",
      "Bash(az:*)",
      "Bash(terraform:*)",
      "Bash(pulumi:*)",
      
      // データベース
      "Bash(psql:*)",
      "Bash(mysql:*)",
      "Bash(redis-cli:*)",
      "Bash(mongo:*)",
      "Bash(prisma:*)",
      "Bash(sequelize:*)",
      
      // 開発ツール
      "Bash(eslint:*)",
      "Bash(prettier:*)",
      "Bash(tsc:*)",
      "Bash(swc:*)",
      "Bash(esbuild:*)",
      
      // プロセス管理
      "Bash(pm2:*)",
      "Bash(nodemon:*)",
      "Bash(supervisor:*)",
      
      // ネットワーキング
      "Bash(netstat:*)",
      "Bash(lsof:*)",
      "Bash(ss:*)",
      "Bash(nmap:*)",
      "Bash(ping:*)",
      "Bash(traceroute:*)",
      
      // ファイル操作
      "Bash(ls:*)",
      "Bash(cat:*)",
      "Bash(grep:*)",
      "Bash(find:*)",
      "Bash(tail:*)",
      "Bash(head:*)",
      "Bash(less:*)",
      "Bash(tree:*)",
      
      // システム監視
      "Bash(htop:*)",
      "Bash(ps:*)",
      "Bash(df:*)",
      "Bash(du:*)",
      "Bash(free:*)"
    ],
    "deny": [
      "Bash(rm -rf /*)",
      "Bash(sudo rm:*)",
      "Bash(chmod 777:*)",
      "Bash(chown root:*)"
    ]
  },
  "theme": "dark",
  "notifications": {
    "enabled": true
  }
}
```

## 3. MCP設定（Model Context Protocol）

### ~/.claude.json
```json
{
  "mcpServers": {
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/home/claude/workspace/projects"
      ]
    },
    
    "firecrawl-mcp": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "firecrawl-mcp"],
      "env": {
        "FIRECRAWL_API_URL": "http://localhost:3002",
        "FIRECRAWL_API_KEY": "your-firecrawl-api-key",
        "FIRECRAWL_RETRY_MAX_ATTEMPTS": "5",
        "FIRECRAWL_RETRY_INITIAL_DELAY": "2000",
        "FIRECRAWL_RETRY_MAX_DELAY": "30000",
        "FIRECRAWL_RETRY_BACKOFF_FACTOR": "3",
        "FIRECRAWL_CREDIT_WARNING_THRESHOLD": "2000",
        "FIRECRAWL_CREDIT_CRITICAL_THRESHOLD": "500"
      }
    },
    
    "github": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "your-github-token"
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
    
    "redis": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-redis"],
      "env": {
        "REDIS_URL": "redis://localhost:6379"
      }
    },
    
    "docker": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-docker"]
    },
    
    "kubernetes": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-kubernetes"],
      "env": {
        "KUBECONFIG": "/home/ubuntu/.kube/config"
      }
    },
    
    "puppeteer": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-puppeteer"],
      "env": {
        "PUPPETEER_HEADLESS": "true",
        "PUPPETEER_NO_SANDBOX": "true",
        "PUPPETEER_DISABLE_DEV_SHM_USAGE": "true"
      }
    },
    
    "playwright": {
      "type": "stdio", 
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-playwright"],
      "env": {
        "PLAYWRIGHT_HEADLESS": "true",
        "PLAYWRIGHT_BROWSERS_PATH": "/ms-playwright"
      }
    }
  }
}
```

## 4. カスタムコマンド設定

### .claude/commands/microservice-deploy.md
```markdown
Deploy microservice to Kubernetes: $ARGUMENTS

Follow these steps:
1. Validate the service configuration and dependencies
2. Build the Docker image with proper tagging
3. Push the image to the container registry
4. Update Kubernetes manifests with new image version
5. Apply the deployment using kubectl
6. Verify the deployment status and health checks
7. Update service mesh configuration if needed
8. Run smoke tests to ensure the service is working
```

### .claude/commands/service-health-check.md
```markdown
Perform comprehensive health check for microservice: $ARGUMENTS

Steps to execute:
1. Check service status in Kubernetes cluster
2. Verify database connections and migrations
3. Test API endpoints with curl/httpie
4. Check service logs for errors
5. Validate service mesh routing
6. Monitor resource usage (CPU, memory)
7. Test inter-service communication
8. Verify circuit breaker and retry mechanisms
```

### .claude/commands/api-test-suite.md
```markdown
Run comprehensive API test suite for: $ARGUMENTS

Test execution plan:
1. Run unit tests with Jest/Vitest
2. Execute integration tests with database
3. Perform API contract testing
4. Run end-to-end tests with Playwright/Cypress
5. Load testing with k6 or Artillery
6. Security testing for common vulnerabilities
7. Generate test coverage report
8. Update API documentation if tests reveal changes
```

### .claude/commands/troubleshoot-service.md
```markdown
Troubleshoot microservice issues: $ARGUMENTS

Diagnostic steps:
1. Check service logs across all instances
2. Verify database connectivity and performance
3. Analyze service mesh traffic and latency
4. Check resource limits and usage
5. Validate environment variables and secrets
6. Test upstream and downstream service dependencies
7. Review recent deployments and configuration changes
8. Generate diagnostic report with recommendations
```

### .claude/commands/setup-new-service.md
```markdown
Setup new microservice: $ARGUMENTS

Service bootstrapping:
1. Create service directory structure
2. Initialize package.json with standard dependencies
3. Setup TypeScript/JavaScript configuration
4. Create Dockerfile with multi-stage build
5. Generate Kubernetes manifests (deployment, service, ingress)
6. Setup CI/CD pipeline configuration
7. Create API documentation template
8. Initialize monitoring and logging configuration
9. Setup database schema and migrations
10. Create comprehensive README with setup instructions
```

### .claude/commands/service-monitoring.md
```markdown
Setup monitoring for microservice: $ARGUMENTS

Monitoring setup:
1. Configure Prometheus metrics collection
2. Setup Grafana dashboards for service metrics
3. Implement health check endpoints
4. Configure distributed tracing with Jaeger
5. Setup log aggregation and alerting
6. Create SLA/SLO definitions
7. Implement circuit breaker patterns
8. Setup automated incident response
```

## 5. プロジェクト固有設定

### .claude/settings.json（プロジェクト用）
```json
{
  "permissions": {
    "allow": [
      "Edit",
      "Read",
      "WebFetch",
      "Bash(npm run:*)",
      "Bash(docker:*)",
      "Bash(kubectl:*)",
      "Bash(helm:*)",
      "Bash(terraform:*)",
      "Bash(curl:*)",
      "Bash(jq:*)"
    ]
  },
  "ignorePatterns": [
    "node_modules/**",
    "dist/**",
    "build/**",
    ".git/**",
    "coverage/**",
    "*.log",
    ".next/**",
    ".nuxt/**"
  ],
  "enableArchitectTool": true
}
```

## 6. 環境変数設定

### ~/.bashrc または ~/.zshrc に追加
```bash
# Node.js/npm
export NODE_ENV=development
export NPM_TOKEN="your-npm-token"

# Docker
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Kubernetes
export KUBECONFIG="$HOME/.kube/config"
export KUBECTL_EXTERNAL_DIFF="colordiff -N -u"

# Cloud providers
export AWS_PROFILE="microservices-dev"
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/credentials.json"
export AZURE_CONFIG_DIR="$HOME/.azure"

# データベース
export DATABASE_URL="postgresql://user:pass@localhost:5432/microservices_db"
export REDIS_URL="redis://localhost:6379"
export MONGODB_URI="mongodb://localhost:27017/microservices"

# 監視・ログ
export JAEGER_ENDPOINT="http://localhost:14268/api/traces"
export PROMETHEUS_URL="http://localhost:9090"
export GRAFANA_URL="http://localhost:3000"

# API Keys
export GITHUB_PERSONAL_ACCESS_TOKEN="your-github-token"

# FireCrawl (セルフホスト)
export FIRECRAWL_API_KEY="your-firecrawl-api-key"
export FIRECRAWL_API_URL="http://localhost:3002"

# Service Mesh
export ISTIO_VERSION="1.20.0"
export LINKERD_VERSION="stable-2.14.0"

# E2Eテスト（ヘッドレス）
export PUPPETEER_HEADLESS=true
export PUPPETEER_NO_SANDBOX=true
export PUPPETEER_DISABLE_DEV_SHM_USAGE=true
export PLAYWRIGHT_HEADLESS=true
export CYPRESS_HEADLESS=true

# テスト環境設定
export TEST_ENV=e2e
export E2E_BASE_URL="http://localhost:3000"
export E2E_TIMEOUT=30000
export E2E_RETRIES=2

# ブラウザ設定
export CHROME_BIN="/usr/bin/google-chrome"
export CHROMIUM_BIN="/usr/bin/chromium"
export FIREFOX_BIN="/usr/bin/firefox"

# 仮想ディスプレイ（CI環境用）
export DISPLAY=:99
export XVFB_DISPLAY=:99
export XVFB_RESOLUTION="1920x1080x24"

# スクリーンショット・レポート
export E2E_SCREENSHOTS_DIR="./test-results/screenshots"
export E2E_VIDEOS_DIR="./test-results/videos"
export E2E_REPORTS_DIR="./test-results/reports"

# Development
export DEBUG="microservices:*"
export LOG_LEVEL="debug"
export PORT=3000
```

## 7. 便利なエイリアス設定

### ~/.bashrc または ~/.zshrc に追加
```bash
# Kubernetes shortcuts
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kgi='kubectl get ingress'
alias klog='kubectl logs -f'
alias kdesc='kubectl describe'
alias kexec='kubectl exec -it'

# Docker shortcuts
alias dc='docker-compose'
alias dcu='docker-compose up'
alias dcd='docker-compose down'
alias dcr='docker-compose restart'
alias dps='docker ps'
alias dimg='docker images'
alias dlog='docker logs -f'

# Development shortcuts
alias nr='npm run'
alias nrd='npm run dev'
alias nrt='npm run test'
alias nrb='npm run build'
alias nrl='npm run lint'
alias nrp='npm run preview'

# Service mesh
alias ic='istioctl'
alias lc='linkerd'
alias consul='consul'

# Monitoring
alias prom='curl -s http://localhost:9090/api/v1'
alias jaeger='open http://localhost:16686'
alias grafana='open http://localhost:3000'

# E2Eテスト関連
alias e2e-run='npm run test:e2e'
alias e2e-run-headless='npm run test:e2e:headless'
alias e2e-debug='npm run test:e2e:debug'
alias e2e-ui='npm run test:e2e:ui'

# Playwright
alias pw='npx playwright'
alias pw-test='npx playwright test'
alias pw-debug='npx playwright test --debug'
alias pw-headed='npx playwright test --headed'
alias pw-report='npx playwright show-report'

# Cypress
alias cy='npx cypress'
alias cy-run='npx cypress run'
alias cy-open='npx cypress open'
alias cy-headed='npx cypress run --headed'

# Puppeteer
alias pptr='npx puppeteer'

# テスト結果
alias test-results='ls -la ./test-results/'
alias test-screenshots='ls -la ./test-results/screenshots/'
alias test-videos='ls -la ./test-results/videos/'

# ヘッドレスブラウザ制御
alias start-xvfb='Xvfb :99 -screen 0 1920x1080x24 &'
alias stop-xvfb='pkill Xvfb'

# Terraform
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
```

## 8. 設定の確認とデバッグ

### 設定確認コマンド
```bash
# 現在の設定を確認
claude config ls

# 特定の設定値を確認
claude config get permissions

# MCP サーバー状態確認
/mcp

# デバッグモードで起動
claude --mcp-debug

# 許可されたツールの確認
/allowed-tools
```

### トラブルシューティング
```bash
# MCPサーバーのログを確認
tail -f mcp-server-*.log

# Node.jsとnpxの確認
node --version
npx --version

# 権限の手動テスト
claude --allowedTools "Edit,Bash(docker:*)" -p "test docker ps command"
```

## 9. セットアップ手順

### 1. 初期セットアップ
```bash
# Claude Codeのインストール
curl -fsSL https://console.anthropic.com/install.sh | sh

# 認証
claude
# OAuth認証プロセスを完了

# プロジェクトの初期化
cd /path/to/your/microservices-project
claude
/init
```

### 2. 設定ファイルの作成
```bash
# グローバル設定ディレクトリの作成
mkdir -p ~/.claude/commands

# プロジェクト設定ディレクトリの作成
mkdir -p .claude/commands

# 設定ファイルのコピー
# 上記の設定内容を適切なファイルに保存
```

### 3. 環境変数とエイリアスの設定
```bash
# .bashrc または .zshrc に環境変数とエイリアスを追加
source ~/.bashrc  # または ~/.zshrc
```

### 4. MCPサーバーの確認
```bash
# Claude Code起動後
/mcp
# すべてのサーバーが "connected" 状態であることを確認
```

## 10. 使用例

### デプロイ実行例
```bash
claude
> /microservice-deploy user-service:v1.2.3
```

### ヘルスチェック実行例
```bash
claude
> /service-health-check payment-service
```

### 新しいサービス作成例
```bash
claude
> /setup-new-service notification-service
```

## 11. コンテナ環境での追加設定

### LXCコンテナ権限設定
LXCコンテナ内でClaude Codeを使用する場合、以下の権限設定が必要です：

```bash
# コンテナ設定ファイル: /var/lib/lxc/claude-code/config
lxc.apparmor.profile = unconfined
lxc.cgroup2.devices.allow = a
lxc.mount.auto = cgroup:rw:force sys:rw cgroup:rw
```

### コンテナ内のユーザー権限
```bash
# ubuntu ユーザーに必要な権限を付与
sudo usermod -aG docker ubuntu
sudo usermod -aG sudo ubuntu

# Docker デーモンの再起動
sudo systemctl restart docker
```

### MCP サーバー起動権限
```bash
# Node.js グローバルパッケージの権限修正
sudo chown -R ubuntu:ubuntu /usr/lib/node_modules
sudo chown -R ubuntu:ubuntu /home/ubuntu/.npm

# MCP サーバー実行権限
chmod +x /home/ubuntu/.local/share/claude/mcp-servers/*
```

### セキュリティポリシー設定
```json
// /etc/claude-code/policies.json (Enterprise Policy)
{
  "permissions": {
    "containerized": true,
    "allowedPaths": [
      "/home/ubuntu/**",
      "/tmp/**",
      "/var/log/claude-code/**"
    ],
    "deniedPaths": [
      "/etc/**",
      "/root/**",
      "/boot/**",
      "/sys/**",
      "/proc/**"
    ],
    "maxFileSize": "100MB",
    "maxMemoryUsage": "4GB"
  }
}
```

## 12. MCP詳細説明

### Filesystem MCP
Filesystem MCPは、Claude Codeが**プロジェクト外のファイルやディレクトリ**にアクセスするために必要です。

#### 必要な理由
- **プロジェクト内**: Claude Codeはデフォルトで現在のプロジェクトディレクトリ内のファイルにアクセス可能
- **プロジェクト外**: システム設定、他のプロジェクト、共有設定等にはFilesystem MCPが必要

#### マイクロサービス開発での用途
```
典型的なディレクトリ構造:
/home/ubuntu/
├── microservices/
│   ├── user-service/          ← プロジェクト1
│   ├── payment-service/       ← プロジェクト2
│   └── notification-service/  ← プロジェクト3
├── docker-configs/            ← プロジェクト外（共有設定）
│   ├── docker-compose.yml
│   └── nginx.conf
└── k8s-manifests/            ← プロジェクト外（K8s設定）
    ├── user-service.yaml
    └── payment-service.yaml
```

#### 具体的な利用場面
- **横断的分析**: 全サービスの設定を比較分析
- **共有設定管理**: Docker Compose、Nginx設定の管理
- **ログ分析**: システムログファイルの読み取り
- **環境設定**: ユーザー設定ファイル（`~/.bashrc`等）の確認

#### セキュリティ利点
- 指定されたディレクトリのみアクセス可能
- システム重要ファイルへの誤アクセス防止
- 監査可能なファイル操作履歴

### Sequential-Thinking MCP
複雑な問題を管理可能なステップに分解し、各段階で最適なMCPツールを推奨するガイドツールです。

#### 使用AIモデルについて
**公式版Sequential-Thinking MCPは独自のAIモデルを使用しません。**

- **ツール機能のみ**: 思考の構造化、ステップ管理、履歴追跡を提供
- **実際の思考処理**: クライアント側のAIモデル（Claude 3.7 Sonnet等）が実行
- **動作原理**: `Claude Code → Sequential-Thinking MCP → 構造化プロセス → Claude Code`

#### バリエーション比較

**公式版（@modelcontextprotocol/server-sequential-thinking）**
- AIモデル: 使用しない（ツールのみ）
- コスト: 低（クライアント側モデルのトークンのみ）
- 設定: シンプル

**Multi-Agent版（コミュニティ開発）**
- AIモデル: DeepSeek等の独自モデルを使用
- コスト: 高（3-6倍のトークン消費）
- 設定: 複雑（API キー等が必要）

```json
// 公式版設定例
{
  "sequential-thinking": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
  }
}

// Multi-Agent版設定例
{
  "mas-sequential-thinking": {
    "type": "stdio",
    "command": "python", 
    "args": ["/path/to/mas-sequential-thinking/main.py"],
    "env": {
      "LLM_PROVIDER": "deepseek",
      "DEEPSEEK_API_KEY": "your-key"
    }
  }
}
```

#### 主な機能
1. **問題分解**: 複雑なタスクを論理的なステップに分割
2. **ツール推奨**: 各ステップに最適なMCPツールを提案
3. **思考プロセス支援**: 段階的な問題解決をサポート
4. **進捗追跡**: 各ステップの完了状況を管理

#### 実際の使用例

**例1: マイクロサービスのデバッグ**
```
問題: "支払いサービスがタイムアウトエラーを起こしている"

Sequential-thinkingによる分解:
1. ログ確認 → filesystem MCPでログファイル読み取り
2. データベース接続確認 → postgres MCPでDB状態チェック
3. 依存サービス確認 → kubernetes MCPでサービス状態確認
4. 設定確認 → filesystem MCPで設定ファイル読み取り
5. 修正実装 → 適切なツールで修正作業
```

**例2: 新機能の実装**
```
タスク: "ユーザー認証機能の追加"

Sequential-thinkingによる分解:
1. 要件分析 → firecrawl MCPで最新のベストプラクティス調査
2. 設計検討 → filesystem MCPで既存コード構造確認
3. データベース設計 → postgres MCPでスキーマ設計
4. 実装 → 各種ツールで段階的実装
5. テスト → テストツールで検証
```

#### 組み合わせの効果
Sequential-thinkingとFilesystem MCPの組み合わせにより：

**構造化された作業フロー**:
```
Sequential-thinking: "データベース移行タスクを分解"
1. 現在のスキーマ確認 → Filesystem MCP
2. 移行スクリプト作成 → Filesystem MCP + Postgres MCP
3. テスト実行 → Kubernetes MCP
4. 本番デプロイ → 複数MCPの協調
```

**安全な実行環境**:
- 各ステップでの権限確認
- 危険な操作の事前警告
- ロールバック可能な変更管理

**効率的な問題解決**:
- 適切なツールの自動選択
- 無駄な操作の削減
- 一貫性のある作業手順

## FireCrawl MCPサーバーの追加設定

### FireCrawl MCPサーバーの設定詳細

#### パッケージについて
使用している`firecrawl-mcp`パッケージは、高機能なFireCrawl MCPクライアントです：

- **基本機能**: セルフホストFireCrawlとの連携
- **リトライ機能**: 指数バックオフによる自動再試行
- **クレジット監視**: 使用量の監視とアラート
- **エラーハンドリング**: 堅牢な例外処理

#### 設定項目詳細

**基本設定:**
```json
{
  "FIRECRAWL_API_URL": "http://localhost:3002",
  "FIRECRAWL_API_KEY": "your-firecrawl-api-key"
}
```

**リトライ設定:**
```json
{
  "FIRECRAWL_RETRY_MAX_ATTEMPTS": "5",
  "FIRECRAWL_RETRY_INITIAL_DELAY": "2000",
  "FIRECRAWL_RETRY_MAX_DELAY": "30000",
  "FIRECRAWL_RETRY_BACKOFF_FACTOR": "3"
}
```

**クレジット監視:**
```json
{
  "FIRECRAWL_CREDIT_WARNING_THRESHOLD": "2000",
  "FIRECRAWL_CREDIT_CRITICAL_THRESHOLD": "500"
}
```

#### リトライ動作例
```
1回目失敗 → 2秒待機
2回目失敗 → 6秒待機 (2×3)
3回目失敗 → 18秒待機 (6×3)
4回目失敗 → 30秒待機 (最大値に制限)
5回目失敗 → 諦める
```

1. **セキュリティ**: 本番環境では適切な権限制限を設定してください
2. **API Keys**: 環境変数やシークレット管理システムを使用してAPIキーを安全に管理してください
3. **リソース使用量**: Claude Codeは多くのトークンを消費する可能性があるため、使用量を監視してください
4. **設定の同期**: チーム開発では`.claude/settings.json`をGitで管理し、個人設定は`.claude/settings.local.json`を使用してください

このガイドに従って設定することで、マイクロサービス開発に最適化されたClaude Code環境を構築できます。