# Claude Code LXC Container Setup

Claude CodeをLXCコンテナ環境で実行するための設定ガイドとドキュメント集です。

## 概要

このリポジトリには、以下の主要なドキュメントとツールが含まれています：

1. **claude_code_container_setup.md** - VS CodeからSSH接続でClaude Codeを実行するためのLXCコンテナ構築手順
2. **claude-code-microservices-config.md** - マイクロサービス開発に特化したClaude Codeの詳細な設定ガイド
3. **external-access-design.md** - 外部ネットワークからのSSH接続を可能にする設計ドキュメント
4. **profiles/** - 再利用可能なLXCプロファイルテンプレート
5. **claude-config/** - Claude Code設定テンプレート
6. **reports/** - 検証結果、問題解決記録、設計検討資料

## 特徴

- 🐳 **コンテナ化された開発環境** - LXCコンテナによる分離された安全な実行環境
- 🔧 **マイクロサービス対応** - Docker、Kubernetes、各種MCPサーバーの設定を含む
- 🔒 **セキュリティ重視** - 詳細なパーミッション設定とSSHセキュリティ強化
- 📦 **MCP (Model Context Protocol) サポート** - filesystem、GitHub、PostgreSQL、Docker等の統合
- 💻 **VS Code統合** - Remote-SSH拡張機能による快適な開発体験
- 🔗 **GitHub CLI (gh) 統合** - GitHub操作をコマンドラインから直接実行
- 🌐 **mDNS対応** - `.local`ドメインでコンテナに簡単アクセス
- 🌍 **外部SSH接続対応** - LXD Proxy Deviceによる安全な外部アクセス（ポート2222）
- ⚡ **高速セットアップ** - cloud-init最適化により約2分でコンテナ構築完了
- 🔐 **柔軟な認証方式** - SSHキー認証、パスワード認証、ハイブリッド認証に対応

## クイックスタート

### 前提条件

- Ubuntu 22.04以降のホストシステム
- LXD/LXCがインストール済み
- 十分なシステムリソース（推奨: 4CPU、16GB RAM、80GB ストレージ）

### 基本的なセットアップ

```bash
# 1. リポジトリのクローン
git clone https://github.com/yourusername/claude_code_lxc.git
cd claude_code_lxc

# 2. プロファイルの適用とコンテナ作成
cd profiles
./apply-profile.sh -n claude-code-dev  # 標準プロファイル
# または
./apply-profile.sh -n claude-code-external  # 外部SSH接続対応プロファイル

# 3. コンテナの作成
lxc launch ubuntu:22.04 claude-code-container --profile claude-code-dev

# 4. 追加ツールのインストール（必要に応じて）
lxc exec claude-code-container -- bash < setup-scripts/additional-tools.sh

# 5. Claude Code設定の適用（オプション）
lxc exec claude-code-container -- bash
cd /home/ubuntu
git clone https://github.com/yourusername/claude_code_lxc.git
cd claude_code_lxc/claude-config
./apply-config.sh microservices-full
```

## ドキュメント構成

### profiles/
LXCプロファイル定義とヘルパースクリプト：
- `claude-code-dev.yaml` - 標準開発環境プロファイル（4CPU、16GB RAM）
- `claude-code-dev-auto.yaml` - MCP/権限設定自動適用版プロファイル
- `claude-code-minimal.yaml` - 最小構成プロファイル（2CPU、8GB RAM）
- `claude-code-external.yaml` - 外部SSH接続対応プロファイル（LXD Proxy Device設定込み）
- `apply-profile.sh` - プロファイル適用ヘルパースクリプト
- `README.md` - プロファイルの詳細説明

### claude-config/
Claude Code設定テンプレートとヘルパースクリプト：
- `microservices-full.json` - マイクロサービス開発用フル機能設定
- `web-development.json` - Web開発用標準設定
- `data-science.json` - データサイエンス用設定
- `minimal.json` - 最小構成設定
- `apply-config.sh` - 設定適用ヘルパースクリプト
- `README.md` - 設定テンプレートの詳細説明

### 主要ドキュメント

#### claude_code_container_setup.md
LXCコンテナの構築から運用まで、以下の内容を網羅：
- LXCプロファイルの作成と設定
- コンテナの初期設定とSSH設定（キー認証、パスワード認証、ハイブリッド認証）
- Claude Code環境のセットアップ
- VS Code Remote-SSH接続設定
- 開発ツールのインストール
- プロファイルの修正と更新方法
- トラブルシューティング

#### external-access-design.md
外部ネットワークからのSSH接続を実現する設計：
- LXD Proxy Deviceによるポートフォワーディング設定
- セキュリティ設定（fail2ban、UFW）
- VS Code Remote-SSH設定例

#### claude-code-microservices-config.md
マイクロサービス開発に必要な詳細設定：
- 設定ファイルの階層構造
- パーミッション設定の詳細
- MCPサーバーの設定と活用方法
- カスタムコマンドの作成
- 環境変数とエイリアス設定
- FireCrawl MCPサーバーの設定

### reports/
検証結果と問題解決の記録：
- `container-setup-verification-results.md` - コンテナ構築の検証結果
- `external-access-design-considerations.md` - 外部接続設計の検討過程
- `setup-issues-and-fixes.md` - セットアップ時の問題と解決策
- `consistency-check-report.md` - 設定ファイルの一貫性チェック結果

## 主な機能

### MCPサーバー統合
- **filesystem** - プロジェクト外のファイルアクセス
- **github** - GitHub API統合
- **postgres/redis** - データベース接続
- **docker/kubernetes** - コンテナオーケストレーション
- **puppeteer/playwright** - ブラウザ自動化

### セキュリティ機能
- 細かいパーミッション制御
- SSH鍵認証
- ファイアウォール設定
- 危険なコマンドのブロック

### 開発支援機能
- カスタムコマンド（デプロイ、ヘルスチェック等）
- 便利なエイリアス設定
- 自動バックアップとスナップショット
- リソース監視

## 使用例

### マイクロサービスのデプロイ
```bash
claude
> /microservice-deploy user-service:v1.2.3
```

### ヘルスチェックの実行
```bash
claude
> /service-health-check payment-service
```

### 新規サービスの作成
```bash
claude
> /setup-new-service notification-service
```

## トラブルシューティング

問題が発生した場合は、以下を確認してください：

1. **SSH接続の問題** - `claude_code_container_setup.md`のセクション10を参照
2. **外部SSH接続の問題** - `external-access-design.md`および`profiles/claude-code-external.yaml`を参照
3. **MCP接続エラー** - `claude-code-microservices-config.md`のセクション8を参照
4. **パーミッションエラー** - 設定ファイルの権限設定を確認
5. **cloud-init関連の問題** - `reports/setup-issues-and-fixes.md`を参照
6. **GitHub CLI認証の問題** - `claude_code_container_setup.md`のセクション11を参照

## 貢献

プルリクエストや改善提案を歓迎します。大きな変更を行う場合は、まずイシューを作成して議論してください。

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細は[LICENSE](LICENSE)ファイルを参照してください。

## 作者

Yoshio

## 最新の更新

- 外部SSH接続対応プロファイル（`claude-code-external.yaml`）の追加
- LXD Proxy Deviceによる安全な外部アクセス実装
- SSH認証方式の選択肢拡充（キー認証、パスワード認証、ハイブリッド）
- cloud-init設定の最適化による構築時間の短縮（約2分）
- GitHub CLIとmDNSサポートの統合
- ドキュメントの整理とreportsフォルダへの検証結果の移動

## 関連リンク

- [Claude Code公式ドキュメント](https://docs.anthropic.com/en/docs/claude-code)
- [LXD公式ドキュメント](https://documentation.ubuntu.com/lxd/)
- [Model Context Protocol (MCP)](https://modelcontextprotocol.io/)
- [VS Code Remote Development](https://code.visualstudio.com/docs/remote/remote-overview)