#!/bin/bash

# Claude Code LXCプロファイル適用スクリプト

set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ヘルプメッセージ
show_help() {
    echo "使用方法: $0 [オプション] <プロファイル名>"
    echo ""
    echo "利用可能なプロファイル:"
    echo "  claude-code-dev      - 標準開発環境 (4CPU, 16GB RAM)"
    echo "  claude-code-minimal  - 最小構成 (2CPU, 8GB RAM)"
    echo ""
    echo "オプション:"
    echo "  -h, --help          このヘルプを表示"
    echo "  -c, --container     コンテナ名を指定 (デフォルト: claude-code-container)"
    echo "  -n, --new           新規コンテナを作成"
    echo "  -f, --force         既存のプロファイルを強制的に上書き"
    echo ""
    echo "例:"
    echo "  $0 claude-code-dev                          # プロファイルを適用"
    echo "  $0 -n claude-code-dev                       # 新規コンテナを作成"
    echo "  $0 -c mycontainer claude-code-minimal        # 特定のコンテナに適用"
}

# デフォルト値
CONTAINER_NAME="claude-code-container"
CREATE_NEW=false
FORCE=false
PROFILE_NAME=""

# 引数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -c|--container)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        -n|--new)
            CREATE_NEW=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        *)
            PROFILE_NAME="$1"
            shift
            ;;
    esac
done

# プロファイル名チェック
if [ -z "$PROFILE_NAME" ]; then
    echo -e "${RED}エラー: プロファイル名を指定してください${NC}"
    show_help
    exit 1
fi

# プロファイルファイルの存在確認
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_FILE="${SCRIPT_DIR}/${PROFILE_NAME}.yaml"

if [ ! -f "$PROFILE_FILE" ]; then
    echo -e "${RED}エラー: プロファイルファイル '${PROFILE_FILE}' が見つかりません${NC}"
    exit 1
fi

echo -e "${GREEN}=== Claude Code LXCプロファイル適用スクリプト ===${NC}"
echo "プロファイル: $PROFILE_NAME"
echo "設定ファイル: $PROFILE_FILE"

# プロファイルの存在確認
if lxc profile show "$PROFILE_NAME" >/dev/null 2>&1; then
    if [ "$FORCE" = true ]; then
        echo -e "${YELLOW}警告: 既存のプロファイル '$PROFILE_NAME' を上書きします${NC}"
    else
        echo -e "${YELLOW}プロファイル '$PROFILE_NAME' は既に存在します${NC}"
        read -p "上書きしますか？ (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "中止しました"
            exit 1
        fi
    fi
else
    echo "新規プロファイル '$PROFILE_NAME' を作成します"
    lxc profile create "$PROFILE_NAME"
fi

# プロファイルの適用
echo "プロファイルを適用しています..."
lxc profile edit "$PROFILE_NAME" < "$PROFILE_FILE"
echo -e "${GREEN}✓ プロファイルが適用されました${NC}"

# 新規コンテナの作成
if [ "$CREATE_NEW" = true ]; then
    echo ""
    echo "新規コンテナ '$CONTAINER_NAME' を作成します"
    
    # 既存コンテナのチェック
    if lxc list --format json | jq -r '.[].name' | grep -q "^${CONTAINER_NAME}$"; then
        echo -e "${YELLOW}警告: コンテナ '$CONTAINER_NAME' は既に存在します${NC}"
        read -p "削除して再作成しますか？ (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "既存のコンテナを削除しています..."
            lxc delete -f "$CONTAINER_NAME"
        else
            echo "中止しました"
            exit 1
        fi
    fi
    
    # コンテナ作成
    echo "コンテナを作成しています..."
    lxc launch ubuntu:22.04 "$CONTAINER_NAME" --profile "$PROFILE_NAME"
    
    # 起動待ち
    echo "コンテナの起動を待っています..."
    sleep 10
    
    # cloud-init完了待ち
    echo "cloud-initの完了を待っています..."
    lxc exec "$CONTAINER_NAME" -- cloud-init status --wait
    
    # IPアドレスの取得と表示
    CONTAINER_IP=$(lxc list "$CONTAINER_NAME" --format json | jq -r '.[0].state.network.eth0.addresses[] | select(.family=="inet") | .address')
    
    echo -e "${GREEN}=== コンテナが正常に作成されました ===${NC}"
    echo "コンテナ名: $CONTAINER_NAME"
    echo "IPアドレス: $CONTAINER_IP"
    echo "プロファイル: $PROFILE_NAME"
    echo ""
    echo "SSHで接続するには:"
    echo "  ssh ubuntu@$CONTAINER_IP"
fi

echo -e "${GREEN}完了しました！${NC}"