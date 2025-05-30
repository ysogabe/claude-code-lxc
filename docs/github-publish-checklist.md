# GitHub公開前チェックリスト

## 概要
このチェックリストは、claude_codeプロジェクトをGitHubに公開する前に確認すべき項目をまとめたものです。

## 🔴 必須対応項目（公開前に必ず修正）

### 1. 機密情報の削除
- [ ] `/path/to/user`パスを汎用的なパス（例：`/path/to/project`）に変更
  - 対象ファイル：`reports/012-external-access-implementation-plan.md:392`
- [ ] 具体的なIPアドレス（10.x.x.x）を汎用的な表記に変更
  - 対象ファイル：`reports/010-claude-code-dev-01-setup-results.md`
- [ ] 日本語メッセージの英訳またはドキュメント化
  - 対象ファイル：`scripts/auto-setup-claude-container.sh`

### 2. フォルダ構成の整理
- [ ] 命名規則の統一（kebab-caseまたはsnake_caseに統一）
  - 現在：`claude_code_lxc`, `claude-config`, `github_action_selfhost`が混在
- [ ] プロジェクト固有の名前を汎用的な名前に変更
  - `claude_code_lxc` → `lxc-containers`または`containers`
  - `github_action_selfhost` → `github-actions-runner`
- [ ] 空のディレクトリの削除または内容の追加
  - `github_action_selfhost/monitoring/`
  - `github_action_selfhost/profiles/`

### 3. ドキュメントと実装の整合性
- [ ] github_action_selfhostのドキュメントを実装に合わせて修正
  - CLAUDE.mdの記述（web-dev-runner, iot-runner）が実装と不一致
  - 実際の実装はgeneric runnerのみ
- [ ] 存在しないプロファイルへの参照を削除
  - web-dev-profile, iot-dev-profileは実装されていない

## 🟡 推奨対応項目（品質向上のため）

### 4. 標準的なプロジェクト構造への移行
- [ ] `docs/`ディレクトリの作成と文書の整理
- [ ] `tests/`ディレクトリの作成
- [ ] `.github/`ディレクトリの作成（GitHub Actions, ISSUE_TEMPLATE等）
- [ ] `examples/`ディレクトリの作成

### 5. ファイル整理
- [ ] ルートディレクトリの整理
  - `test_output.log`を適切な場所へ移動
  - setup関連スクリプトを`scripts/`へ移動
- [ ] `reports/backup/`の内容確認と整理

### 6. README.mdの充実
- [ ] プロジェクト全体の説明
- [ ] インストール手順
- [ ] 使用方法
- [ ] 貢献方法（CONTRIBUTING.md）

## 🟢 確認済み項目

### セキュリティ面
- ✅ APIキー、トークンはすべてプレースホルダー使用
- ✅ 環境変数による設定値の外部化
- ✅ SSHキーパスは標準的なパスのみ

### ライセンス
- ✅ LICENSEファイルが存在

## チェックリスト使用方法

1. 🔴必須対応項目をすべて完了する
2. 🟡推奨対応項目をできる限り対応する
3. 各項目完了後、チェックボックスにチェックを入れる
4. すべての必須項目が完了したら公開可能

## 注意事項

- LXDのデフォルトネットワーク（10.x.x.x/24）は一般的な設定のため、ドキュメントに明記すれば問題なし
- プレースホルダー（`${GITHUB_TOKEN}`等）は適切に使用されているため変更不要
- 日本語コメントは国際化の観点から英訳を推奨するが、必須ではない

## 関連ドキュメント
- [GitHub公開手順書](./github-publish-procedure.md)