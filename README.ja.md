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
git clone https://github.com/yourusername/claude_code_lxc.git
cd claude_code_lxc

# 2. プロファイルの適用とコンテナ作成
cd profiles
./apply-profile.sh -n claude-code-dev  # 標準プロファイル
# または
./apply-profile.sh -n claude-code-external  # 外部SSH接続対応プロファイル

# 3. コンテナの作成
lxc launch ubuntu:22.04 claude-code-container --profile claude-code-dev
```

## ドキュメント

詳細なドキュメントは [docs/](./docs/) ディレクトリを参照してください。

## 変更履歴

プロジェクトの変更履歴は [CHANGELOG.ja.md](./CHANGELOG.ja.md) を参照してください。

## ライセンス

このプロジェクトは [MITライセンス](./LICENSE) の下で公開されています。
