# ADR-001: LXCコンテナ内アプリケーション開発効率化決定

## ステータス

提案中

## コンテキスト

### プロジェクトの目的

Claude Code LXC環境は維持しつつ、**コンテナ内でのアプリケーション開発・パッケージ構築・インフラ管理の効率化**を図ります。

### 現在の課題

LXCコンテナ内での開発ワークフローには以下の非効率性があります：

#### 開発プロセスの課題
1. **手動ビルドプロセス**: アプリケーションのビルド・テスト・デプロイが手動操作に依存
2. **分散したツール管理**: 開発ツール（言語ランタイム、CLI、インフラツール）の管理が分散
3. **再現性の欠如**: 開発環境とプロダクション環境の差異による問題
4. **バージョン管理の複雑性**: 言語ごとに異なるバージョン管理ツール

#### インフラ管理の課題
5. **インフラ変更の手動対応**: サーバー設定、ネットワーク構成の手動管理
6. **設定ドリフト**: インフラの実際の状態と想定される状態の乖離
7. **デプロイメント手順の非標準化**: プロジェクトごとに異なるデプロイ方法
8. **監視・ログ管理の非統一**: アプリケーションとインフラの監視が分散

### 先進的コミュニティの動向

vim-jpのような先進的なコミュニティでは、以下のトレンドが観察されています：

- **開発ツール統一化**: mise、aquaによる宣言的ツール管理
- **Infrastructure as Code**: Terraform、Ansibleによるインフラ自動化
- **CI/CDパイプライン**: GitHub Actions、GitLab CIによる自動化
- **コンテナ化**: Docker、Kubernetesによるアプリケーション配布

## 決定

以下の段階的アプローチでLXCコンテナ内の開発効率化を実現します：

### Phase 1: 開発ツール統一化 (高優先度)

**対象範囲**: 
- mise: 言語ランタイム（Node.js、Python、Rust）のバージョン管理統一
- aqua: 開発・インフラ管理CLIツールの宣言的管理
- タスクランナー: ビルド・テスト・デプロイの自動化

**利点**:
- 開発環境セットアップの高速化
- チーム間での環境統一
- セキュリティ強化（チェックサム検証）

### Phase 2: Infrastructure as Code導入 (高優先度)

**対象範囲**:
- Terraform: インフラリソースの管理とプロビジョニング
- Ansible: サーバー設定とアプリケーションデプロイ
- Docker Compose: 開発環境でのマルチコンテナ管理

**利点**:
- インフラ変更の自動化と再現性
- 設定ドリフトの防止
- インフラとアプリケーションの統合管理

### Phase 3: CI/CDパイプライン構築 (中優先度)

**対象範囲**:
- GitHub Actions: ビルド・テスト・デプロイの自動化
- Container Registry: イメージ管理とバージョニング
- 監視・ログ統合: アプリケーション・インフラの統合監視

**利点**:
- 開発からリリースまでの自動化
- 品質保証プロセスの標準化
- デプロイメント時間の短縮

## 実装計画

### 技術的実装

#### 1. 開発ツール統一化（mise + aqua）

**mise.toml** - アプリケーション開発・ビルド管理:
```toml
[tools]
node = "lts"
python = "3.11"
rust = "stable"

[env]
NODE_ENV = "development"
DOCKER_BUILDKIT = "1"
CI = "true"

[tasks.build]
run = ["npm run build", "docker build -t app:latest ."]

[tasks.test]
run = ["npm test", "python -m pytest", "cargo test"]

[tasks.deploy]
run = ["terraform apply", "kubectl apply -f k8s/"]
```

**aqua.yaml** - インフラ・開発CLIツール管理:
```yaml
registries:
- type: standard
  ref: v4.249.0

packages:
# 開発ツール
- name: cli/cli@v2.40.1                    # GitHub CLI
- name: docker/cli@v24.0.7                # Docker CLI
- name: kubernetes/kubectl@v1.28.4        # Kubernetes CLI

# インフラ管理ツール
- name: hashicorp/terraform@v1.6.6        # Infrastructure as Code
- name: ansible/ansible@v2.15.5           # Configuration Management
- name: helm/helm@v3.13.3                 # Kubernetes package manager

# 監視・ログツール
- name: prometheus/prometheus@v2.47.2     # Monitoring
- name: grafana/grafana@v10.2.0          # Visualization
```

#### 2. Infrastructure as Code設定

**terraform/main.tf** - インフラ定義:
```hcl
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

resource "docker_network" "app_network" {
  name = "claude-code-network"
}

resource "docker_container" "app" {
  image = "app:latest"
  name  = "claude-code-app"
  
  networks_advanced {
    name = docker_network.app_network.name
  }
}
```

#### 3. CI/CDパイプライン

**.github/workflows/deploy.yml** - 自動化ワークフロー:
```yaml
name: Build and Deploy
on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Setup tools
      run: |
        mise install
        aqua install
    - name: Build application
      run: mise run build
    - name: Run tests
      run: mise run test
    - name: Deploy infrastructure
      run: mise run deploy
```

### 移行戦略

1. **段階的導入**: 既存のLXCコンテナ環境を維持しながら新ツールを追加
2. **並行運用**: 従来の手動プロセスと自動化ツールの共存期間を設定
3. **プロジェクト単位導入**: 新プロジェクトから優先的に新しいワークフローを適用
4. **トレーニング**: チームメンバーへのツール習得支援
5. **段階的移行**: Phase 1 → Phase 2 → Phase 3の順次展開

## 期待効果

### 短期効果 (Phase 1: 開発ツール統一化)

- **開発セットアップ時間**: 70%短縮（10分→3分）
- **ビルド時間**: 自動化により30%短縮
- **エラー率削減**: 手動ステップ削減により50%削減
- **セキュリティ向上**: チェックサム検証による安全性強化

### 中期効果 (Phase 2: Infrastructure as Code)

- **インフラ変更時間**: 手動作業から数分の自動実行へ
- **設定ドリフト**: 宣言的管理により根本的解決
- **環境一貫性**: 開発・ステージング・本番環境の統一
- **障害復旧時間**: インフラの迅速な再構築

### 長期効果 (Phase 3: CI/CDパイプライン)

- **リリース頻度**: 手動リリースから継続デプロイメントへ
- **品質向上**: 自動テスト・デプロイによる品質保証
- **開発者生産性**: 手動作業からコード開発への集中
- **運用負荷軽減**: 監視・ログの統合による効率化

## リスク分析

### 技術的リスク

1. **学習コスト**: 新ツール（Terraform、mise、aqua）の習得時間
2. **複雑性増加**: インフラコード管理の初期複雑性
3. **ツール間依存**: 複数ツールの組み合わせによる問題
4. **パフォーマンス**: 初回セットアップとビルド時間

### 運用リスク

5. **チーム移行**: 既存ワークフローからの変更抵抗
6. **デバッグ困難**: 自動化ツール内でのエラー特定
7. **ツール更新**: 依存ツールのバージョン管理負荷

### 軽減策

1. **段階的導入**: Phase 1から順次展開、リスク分散
2. **並行運用**: 従来手法との共存期間（3-6ヶ月）を設定
3. **文書化**: 詳細な移行ガイドとトラブルシューティング
4. **トレーニング**: チーム向けハンズオン研修の実施
5. **フォールバック**: 各段階での従来手法への復帰手順整備

## 代替案検討

### 検討したが採用しなかった案

1. **Jenkins CI/CD**: GitHub Actionsの方がクラウドネイティブで軽量
2. **Puppet/Chef**: Ansibleの方が学習コストが低く、エージェントレス
3. **手動Docker Compose**: Terraformによる宣言的管理の方が再現性が高い
4. **AWS CDK**: Terraformの方がマルチクラウド対応で汎用性が高い

### 部分的採用案

1. **mise のみ導入**: 開発ツール統一化のみ実施
2. **Terraform のみ導入**: インフラ管理のみ自動化
3. **段階的スキップ**: Phase 2までで止めてCI/CDは将来検討

## 関連決定

- **LXCコンテナ環境**: 継続利用（変更なし）
- **VS Code Remote-SSH**: 継続利用（統合強化）
- **セキュリティ設定**: 既存のfail2ban、ufw設定は維持
- **ネットワーク構成**: 既存のlxdbr0ブリッジ設定は維持
- **ストレージ**: 既存のディレクトリ構造は維持

## 成功指標

### 定量的指標
- セットアップ時間: 現在10分 → 目標3分
- ビルド時間: 現在の70%を目標
- デプロイ時間: 現在手動30分 → 目標自動5分
- エラー率: 手動作業エラーの50%削減

### 定性的指標
- 開発者満足度の向上
- インフラ変更の確実性向上
- 新メンバーのオンボーディング効率化
- プロジェクト間の一貫性向上

## 実装タイムライン

- **Month 1**: Phase 1実装（mise + aqua）
- **Month 2**: Phase 1検証とPhase 2準備
- **Month 3**: Phase 2実装（Terraform + IaC）
- **Month 4**: Phase 2検証とPhase 3準備
- **Month 5-6**: Phase 3実装（CI/CD）
- **Month 7**: 全体評価と最適化

## 次のアクション

1. Phase 1の技術検証開始
2. チーム向け新ツール紹介セッション
3. パイロットプロジェクトの選定
4. 詳細実装計画の策定

---

**作成日**: 2025-06-30  
**作成者**: Claude Code  
**レビュー**: 要レビュー