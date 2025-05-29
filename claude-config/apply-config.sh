#!/bin/bash

# Claude Code設定適用スクリプト

set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# デフォルト値
CONFIG_NAME=""
CONTAINER_NAME=""
DRY_RUN=false
VERBOSE=false

# スクリプトのディレクトリ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ヘルプメッセージ
show_help() {
    echo "Claude Code設定適用スクリプト"
    echo ""
    echo "使用方法: $0 [オプション] <設定名>"
    echo ""
    echo "利用可能な設定:"
    echo "  microservices-full  - マイクロサービス開発用フル機能"
    echo "  web-development     - Web開発用標準設定"
    echo "  data-science        - データサイエンス用設定"
    echo "  minimal             - 最小構成"
    echo ""
    echo "オプション:"
    echo "  -h, --help          このヘルプを表示"
    echo "  -c, --container     コンテナ名を指定"
    echo "  -d, --dry-run       実際には適用せず、内容を表示"
    echo "  -v, --verbose       詳細な出力を表示"
    echo ""
    echo "例:"
    echo "  $0 microservices-full"
    echo "  $0 -c mycontainer web-development"
    echo "  $0 -d minimal"
}

# エラー処理
error_exit() {
    echo -e "${RED}エラー: $1${NC}" >&2
    exit 1
}

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
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        *)
            CONFIG_NAME="$1"
            shift
            ;;
    esac
done

# 設定名チェック
if [ -z "$CONFIG_NAME" ]; then
    error_exit "設定名を指定してください"
fi

# 設定ファイルの存在確認
CONFIG_FILE="${SCRIPT_DIR}/${CONFIG_NAME}.json"
if [ ! -f "$CONFIG_FILE" ]; then
    error_exit "設定ファイル '${CONFIG_FILE}' が見つかりません"
fi

echo -e "${BLUE}=== Claude Code設定適用 ===${NC}"
echo "設定: $CONFIG_NAME"
echo "ファイル: $CONFIG_FILE"

# コンテナ指定がない場合は、現在のユーザーに適用
if [ -z "$CONTAINER_NAME" ]; then
    echo "対象: 現在のユーザー環境"
    TARGET_HOME="$HOME"
    EXEC_PREFIX=""
else
    echo "対象: コンテナ $CONTAINER_NAME"
    # コンテナの存在確認
    if ! lxc list --format json | jq -r '.[].name' | grep -q "^${CONTAINER_NAME}$"; then
        error_exit "コンテナ '${CONTAINER_NAME}' が見つかりません"
    fi
    TARGET_HOME="/home/ubuntu"
    EXEC_PREFIX="lxc exec $CONTAINER_NAME -- sudo -u ubuntu"
fi

# jqのインストール確認
check_jq() {
    if [ -z "$CONTAINER_NAME" ]; then
        if ! command -v jq &> /dev/null; then
            error_exit "jqがインストールされていません。'sudo apt install jq' でインストールしてください"
        fi
    else
        if ! $EXEC_PREFIX bash -c "command -v jq" &> /dev/null; then
            echo "コンテナにjqをインストールしています..."
            lxc exec $CONTAINER_NAME -- apt update
            lxc exec $CONTAINER_NAME -- apt install -y jq
        fi
    fi
}

check_jq

# 設定の適用
apply_config() {
    local config_json="$1"
    
    # MCP設定の作成
    echo -e "\n${GREEN}1. MCP設定を適用中...${NC}"
    local mcp_config=$(echo "$config_json" | jq -r '.mcp')
    
    if [ "$DRY_RUN" = true ]; then
        echo "MCP設定内容:"
        echo "$mcp_config" | jq '.'
    else
        if [ -z "$CONTAINER_NAME" ]; then
            mkdir -p "$TARGET_HOME/.claude"
            echo "$mcp_config" > "$TARGET_HOME/.claude.json"
        else
            $EXEC_PREFIX bash -c "mkdir -p $TARGET_HOME/.claude"
            echo "$mcp_config" | $EXEC_PREFIX bash -c "cat > $TARGET_HOME/.claude.json"
        fi
        echo "✓ ~/.claude.json を作成しました"
    fi
    
    # パーミッション設定の作成
    echo -e "\n${GREEN}2. パーミッション設定を適用中...${NC}"
    local permissions_config=$(echo "$config_json" | jq -r '.permissions')
    
    if [ "$DRY_RUN" = true ]; then
        echo "パーミッション設定内容:"
        echo "$permissions_config" | jq '.'
    else
        if [ -z "$CONTAINER_NAME" ]; then
            mkdir -p "$TARGET_HOME/.claude"
            echo "$permissions_config" > "$TARGET_HOME/.claude/settings.json"
        else
            $EXEC_PREFIX bash -c "mkdir -p $TARGET_HOME/.claude"
            echo "$permissions_config" | $EXEC_PREFIX bash -c "cat > $TARGET_HOME/.claude/settings.json"
        fi
        echo "✓ ~/.claude/settings.json を作成しました"
    fi
    
    # 環境変数の設定
    echo -e "\n${GREEN}3. 環境変数を設定中...${NC}"
    local env_vars=$(echo "$config_json" | jq -r '.environment // {}')
    
    if [ "$DRY_RUN" = true ]; then
        echo "環境変数:"
        echo "$env_vars" | jq -r 'to_entries[] | "export \(.key)=\"\(.value)\""'
    else
        local env_exports=$(echo "$env_vars" | jq -r 'to_entries[] | "export \(.key)=\"\(.value)\""')
        if [ ! -z "$env_exports" ]; then
            local bashrc_marker="# Claude Code Environment Variables"
            
            if [ -z "$CONTAINER_NAME" ]; then
                # 既存のClaude Code環境変数を削除
                sed -i "/${bashrc_marker}/,/# End Claude Code Environment Variables/d" "$TARGET_HOME/.bashrc" 2>/dev/null || true
                
                # 新しい環境変数を追加
                {
                    echo ""
                    echo "$bashrc_marker"
                    echo "$env_exports"
                    echo "# End Claude Code Environment Variables"
                } >> "$TARGET_HOME/.bashrc"
            else
                # コンテナ内で同様の処理
                $EXEC_PREFIX bash -c "sed -i '/${bashrc_marker}/,/# End Claude Code Environment Variables/d' $TARGET_HOME/.bashrc 2>/dev/null || true"
                
                echo "$env_exports" | $EXEC_PREFIX bash -c "
                    {
                        echo ''
                        echo '${bashrc_marker}'
                        cat
                        echo '# End Claude Code Environment Variables'
                    } >> $TARGET_HOME/.bashrc
                "
            fi
            echo "✓ 環境変数を ~/.bashrc に追加しました"
        fi
    fi
    
    # カスタムコマンドの作成
    echo -e "\n${GREEN}4. カスタムコマンドを作成中...${NC}"
    local custom_commands=$(echo "$config_json" | jq -r '.customCommands[]?' 2>/dev/null)
    
    if [ ! -z "$custom_commands" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "カスタムコマンド:"
            echo "$config_json" | jq -r '.customCommands[] | "- \(.name): \(.description)"'
        else
            if [ -z "$CONTAINER_NAME" ]; then
                mkdir -p "$TARGET_HOME/.claude/commands"
            else
                $EXEC_PREFIX bash -c "mkdir -p $TARGET_HOME/.claude/commands"
            fi
            
            echo "$config_json" | jq -r '.customCommands[] | @base64' | while read -r cmd_base64; do
                local cmd=$(echo "$cmd_base64" | base64 -d)
                local cmd_name=$(echo "$cmd" | jq -r '.name')
                local cmd_content=$(echo "$cmd" | jq -r '.content')
                
                if [ -z "$CONTAINER_NAME" ]; then
                    echo "$cmd_content" > "$TARGET_HOME/.claude/commands/${cmd_name}.md"
                else
                    echo "$cmd_content" | $EXEC_PREFIX bash -c "cat > $TARGET_HOME/.claude/commands/${cmd_name}.md"
                fi
                echo "  ✓ コマンド '${cmd_name}' を作成しました"
            done
        fi
    fi
}

# メイン処理
if [ "$DRY_RUN" = true ]; then
    echo -e "\n${YELLOW}[ドライラン] 実際には適用されません${NC}"
fi

# 設定ファイルの読み込みと適用
CONFIG_JSON=$(cat "$CONFIG_FILE")
apply_config "$CONFIG_JSON"

# 必要なディレクトリの作成
if [ "$DRY_RUN" = false ]; then
    echo -e "\n${GREEN}5. 追加のディレクトリを作成中...${NC}"
    
    # 設定に応じたディレクトリを作成
    case "$CONFIG_NAME" in
        microservices-full)
            if [ -z "$CONTAINER_NAME" ]; then
                mkdir -p "$TARGET_HOME"/{microservices,docker-configs,k8s-manifests}
            else
                $EXEC_PREFIX bash -c "mkdir -p $TARGET_HOME/{microservices,docker-configs,k8s-manifests}"
            fi
            echo "✓ マイクロサービス用ディレクトリを作成しました"
            ;;
        data-science)
            if [ -z "$CONTAINER_NAME" ]; then
                mkdir -p "$TARGET_HOME"/{notebooks,datasets,models}
            else
                $EXEC_PREFIX bash -c "mkdir -p $TARGET_HOME/{notebooks,datasets,models}"
            fi
            echo "✓ データサイエンス用ディレクトリを作成しました"
            ;;
        web-development)
            if [ -z "$CONTAINER_NAME" ]; then
                mkdir -p "$TARGET_HOME"/{projects,shared}
            else
                $EXEC_PREFIX bash -c "mkdir -p $TARGET_HOME/{projects,shared}"
            fi
            echo "✓ Web開発用ディレクトリを作成しました"
            ;;
    esac
fi

echo -e "\n${GREEN}=== 設定の適用が完了しました ===${NC}"

if [ "$DRY_RUN" = false ]; then
    echo -e "\n次のステップ:"
    if [ -z "$CONTAINER_NAME" ]; then
        echo "1. ターミナルを再起動するか、'source ~/.bashrc' を実行してください"
        echo "2. 'claude' コマンドでClaude Codeを起動してください"
    else
        echo "1. コンテナに接続: lxc exec $CONTAINER_NAME -- sudo -u ubuntu bash"
        echo "2. 'source ~/.bashrc' を実行してください"
        echo "3. 'claude' コマンドでClaude Codeを起動してください"
    fi
fi