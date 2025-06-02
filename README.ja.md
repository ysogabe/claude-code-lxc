# Claude Code LXC コンテナセットアップ

Claude CodeをLXCコンテナ環境で実行するための設定ガイドとドキュメント集です。

## 概要

このリポジトリには、以下の主要なドキュメントとツールが含まれています：

1. **docs/claude_code_container_setup.md** - VS CodeからSSH接続でClaude Codeを実行するためのLXCコンテナ構築手順
2. **docs/claude-code-microservices-config.md** - マイクロサービス開発に特化したClaude Codeの詳細な設定ガイド
3. **docs/external-access-design.md** - 外部ネットワークからのSSH接続を可能にする設計ドキュメント
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
- 🌍 **外部SSH接続対応** - 動的ポート割り当て（2222-2299）とポート競合回避機能
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
git clone https://github.com/ysogabe/claude-code-lxc.git
cd claude_code_lxc

# 2. プロファイルの適用とコンテナ作成
cd profiles
./apply-profile.sh -n claude-code-dev  # 標準プロファイル
# または
./apply-profile.sh -n claude-code-external  # 外部SSH接続対応プロファイル

# 3. コンテナの作成
lxc launch ubuntu:22.04 claude-code-container --profile claude-code-dev

# 4. 追加ツールのインストール（オプション）
lxc exec claude-code-container -- bash < scripts/setup-additional-tools.sh

# 5. Claude Code設定の適用（オプション）
lxc exec claude-code-container -- bash
cd /home/ubuntu
git clone https://github.com/ysogabe/claude-code-lxc.git
cd claude-code-lxc/claude-config
./apply-config.sh -n microservices-full
```

## ドキュメント構造

### profiles/
LXCプロファイル定義とヘルパースクリプト：
- `claude-code-dev.yaml` - 標準開発環境プロファイル（4 CPU、16GB RAM）
- `claude-code-dev-auto.yaml` - 自動MCP/パーミッション設定付きプロファイル
- `claude-code-minimal.yaml` - 最小構成プロファイル（2 CPU、8GB RAM）
- `claude-code-external.yaml` - 外部SSHアクセスプロファイル（LXD Proxy Device設定を含む）
- `apply-profile.sh` - プロファイル適用ヘルパースクリプト
- `README.md` - プロファイルの詳細ドキュメント

### claude-config/
Claude Code設定テンプレートとヘルパースクリプト：
- `microservices-full.json` - マイクロサービス開発用フル機能設定
- `web-development.json` - Web開発用標準設定
- `data-science.json` - データサイエンス用設定
- `minimal.json` - 最小設定
- `apply-config.sh` - 設定適用ヘルパースクリプト
- `README.md` - 設定テンプレートの詳細ドキュメント

### 主要ドキュメント

#### docs/claude_code_container_setup.md
LXCコンテナ構築から運用までの包括的なガイド：
- LXCプロファイルの作成と設定
- コンテナ初期セットアップとSSH設定（キー認証、パスワード認証、ハイブリッド認証）
- Claude Code環境のセットアップ
- VS Code Remote-SSH接続設定
- 開発ツールのインストール
- プロファイルの変更と更新手順
- トラブルシューティング

#### docs/external-access-design.md
外部ネットワークからのSSH接続を実現するための設計：
- LXD Proxy Deviceを使用したポートフォワーディング設定
- セキュリティ設定（fail2ban、UFW）
- VS Code Remote-SSH設定例

#### docs/claude-code-microservices-config.md
マイクロサービス開発に必要な詳細設定：
- 設定ファイル階層
- 詳細なパーミッション設定
- MCPサーバーの設定と活用
- カスタムコマンドの作成
- 環境変数とエイリアス設定
- FireCrawl MCPサーバー設定

### docs/
公開ドキュメント：
- `external-access-design-considerations.md` - 外部アクセス設計の考慮事項
- `profile-improvement-plan.md` - プロファイル改善計画
- `github-publish-checklist.md` - GitHub公開チェックリスト
- `README.md` - ドキュメント概要

## 主要機能

### MCPサーバー統合
- **filesystem** - プロジェクト外のファイルアクセス
- **github** - GitHub API統合
- **postgres/redis** - データベース接続
- **docker/kubernetes** - コンテナオーケストレーション
- **puppeteer/playwright** - ブラウザ自動化

### セキュリティ機能
- 細かなパーミッション制御
- SSHキー認証
- ファイアウォール設定
- 危険なコマンドのブロック

### 開発サポート機能
- カスタムコマンド（デプロイ、ヘルスチェックなど）
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

### 新しいサービスの作成
```bash
claude
> /setup-new-service notification-service
```

## トラブルシューティング

問題が発生した場合は、以下を確認してください：

1. **SSH接続の問題** - `docs/claude_code_container_setup.md`のセクション10を参照
2. **外部SSH接続の問題** - `docs/external-access-design.md`と`profiles/claude-code-external.yaml`を参照
3. **MCP接続エラー** - `docs/claude-code-microservices-config.md`のセクション8を参照
4. **パーミッションエラー** - 設定ファイルのパーミッション設定を確認
5. **cloud-init関連の問題** - プロファイルファイルのcloud-init設定を確認
6. **GitHub CLI認証の問題** - `docs/claude_code_container_setup.md`のセクション11を参照

## コントリビューション

プルリクエストや改善提案を歓迎します。大きな変更については、まずissueを作成して議論してください。

## 最新の更新

- 外部SSH接続サポートプロファイル（`claude-code-external.yaml`）を追加
- LXD Proxy Deviceを使用した安全な外部アクセスを実装
- SSH認証オプションを拡張（キー認証、パスワード認証、ハイブリッド）
- cloud-init設定を最適化してビルド時間を短縮（約2分）
- GitHub CLIとmDNSサポートを統合
- ドキュメントを整理し、公開ドキュメントをdocsフォルダに移動

## ドキュメント

詳細なドキュメントは [docs/](./docs/) ディレクトリを参照してください。

## 変更履歴

プロジェクトの変更履歴は [CHANGELOG.ja.md](./CHANGELOG.ja.md) を参照してください。

## ライセンス

このプロジェクトは [MITライセンス](./LICENSE) の下で公開されています。

## 作者

Yoshio

## 関連リンク

- [Claude Code公式ドキュメント](https://docs.anthropic.com/en/docs/claude-code)
- [LXD公式ドキュメント](https://documentation.ubuntu.com/lxd/)
- [Model Context Protocol (MCP)](https://modelcontextprotocol.io/)
- [VS Codeリモート開発](https://code.visualstudio.com/docs/remote/remote-overview)
