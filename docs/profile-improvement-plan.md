# Claude Code Profile Improvement Plan

## 📋 概要

**作成日**: 2025-05-29  
**目的**: claude-code-dev-auto.yamlの改善案を現在のclaude-code-dev.yamlに適用し、セットアップ時間の短縮と自動化の向上を図る

## 🔍 改善案の分析

### claude-code-dev-auto.yamlの主な改善点

1. **パッケージの事前インストール**
   - Node.js/npm（公式パッケージ）
   - GitHub CLI（gh）
   - 追加ツールスクリプトで後からインストールしていたものを事前に含める

2. **自動設定の強化**
   - Node.js LTSの自動セットアップ
   - npm globalパッケージ（yarn, pnpm）の自動インストール
   - Python pipパッケージの自動インストール
   - Rust環境の自動セットアップ
   - Claude Code CLIの自動インストール（修正必要）

3. **Claude Code設定の自動化**
   - MCP設定ファイル（~/.claude.json）の自動生成
   - パーミッション設定（~/.claude/settings.json）の自動生成
   - 環境変数の自動設定

4. **ディレクトリ構造の自動作成**
   - workspaceディレクトリの詳細な構造
   - カスタムコマンドディレクトリ

## 📐 実装計画

### Phase 1: 現在のプロファイルの分析
- 現在のclaude-code-dev.yamlとの差分確認
- 重複や競合の確認
- パッケージ更新/アップグレードのリスク評価

### Phase 2: 改善版プロファイルの作成
- claude-code-dev-improved.yamlの作成
- 以下の要素を統合：
  - パッケージの事前インストール
  - 自動設定スクリプト
  - Claude Code設定の自動化

### Phase 3: テスト計画
1. 改善版プロファイルでのコンテナ作成
2. セットアップ時間の測定
3. 全機能の動作確認
4. 既存プロファイルとの比較

## 🎯 期待される成果

1. **セットアップ時間の短縮**
   - 追加ツールスクリプトの実行が不要に
   - 現在: 基本セットアップ5分 + 追加ツール10分 = 合計15分
   - 目標: 統合セットアップ7-8分

2. **ユーザー体験の向上**
   - コンテナ作成後すぐに開発可能
   - Claude Code設定済み
   - 環境変数設定済み

3. **メンテナンス性の向上**
   - 単一のプロファイルファイルで管理
   - スクリプト依存の削減

## 🚨 注意事項と対策

### 1. Claude Codeインストールコマンドの修正
```yaml
# 修正前（動作しない）
- sudo -u claude_code bash -c 'curl -fsSL https://console.anthropic.com/install.sh | sh'

# 修正後
- sudo -u claude_code bash -c 'npm install -g @anthropic-ai/claude-code'
```

### 2. パッケージ更新の影響
- `package_update: true`は初回起動を遅くする可能性
- テストで実際の影響を測定

### 3. Node.jsのインストール方法
- NodeSourceリポジトリの追加が必要
- cloud-init内での実行順序に注意

## 📊 成功指標

1. セットアップ時間が10分以内
2. すべての開発ツールが即座に利用可能
3. Claude Code CLIが正常に動作
4. SSH接続後すぐに開発開始可能

## 🔧 実装手順

1. 改善版プロファイルの作成
2. テスト用コンテナの作成
3. 機能テストの実施
4. パフォーマンス測定
5. ドキュメントの更新