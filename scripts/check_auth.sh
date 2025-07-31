#!/bin/bash

# Gemini CLI 認証状態チェックスクリプト

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 認証状態をチェック
check_auth_status() {
    # 認証ファイルの存在確認
    if [ -f "$HOME/.gemini/credentials.json" ]; then
        # ファイルが存在する場合、簡単なテストを実行
        if echo "test" | gemini -p "Say OK" 2>&1 | grep -q "OK\|ok\|Ok"; then
            return 0  # 認証OK
        else
            # エラー内容を確認
            local error_msg=$(echo "test" | gemini -p "Say OK" 2>&1)
            if echo "$error_msg" | grep -q "401\|403\|Unauthorized\|Forbidden"; then
                return 2  # 認証期限切れ
            else
                return 3  # その他のエラー
            fi
        fi
    else
        # APIキーが設定されているか確認
        if [ -n "$GEMINI_API_KEY" ]; then
            # APIキーでテスト
            if echo "test" | gemini -p "Say OK" 2>&1 | grep -q "OK\|ok\|Ok"; then
                return 0  # APIキー認証OK
            else
                return 4  # APIキーが無効
            fi
        else
            return 1  # 未認証
        fi
    fi
}

# メイン処理
main() {
    check_auth_status
    local status=$?
    
    case $status in
        0)
            echo -e "${GREEN}✓ 認証状態: 正常${NC}"
            if [ -f "$HOME/.gemini/credentials.json" ]; then
                echo "  認証方法: OAuth"
            else
                echo "  認証方法: APIキー"
            fi
            ;;
        1)
            echo -e "${RED}✗ 認証状態: 未認証${NC}"
            echo ""
            echo "認証が必要です。以下のコマンドを実行してください："
            echo "  make auth"
            echo "または"
            echo "  ./scripts/setup_auth.sh"
            exit 1
            ;;
        2)
            echo -e "${YELLOW}⚠ 認証状態: 期限切れ${NC}"
            echo ""
            echo "認証の有効期限が切れています。再認証してください："
            echo "  make auth"
            exit 1
            ;;
        3)
            echo -e "${YELLOW}⚠ 認証状態: エラー${NC}"
            echo ""
            echo "認証情報に問題がある可能性があります。"
            echo "ネットワーク接続を確認するか、再認証してください："
            echo "  make auth"
            exit 1
            ;;
        4)
            echo -e "${RED}✗ 認証状態: APIキーが無効${NC}"
            echo ""
            echo "APIキーが無効です。以下を確認してください："
            echo "1. APIキーが正しく設定されているか"
            echo "2. APIキーの有効期限"
            echo "3. APIキーの権限"
            exit 1
            ;;
    esac
}

# 引数処理
if [ "$1" == "--quiet" ] || [ "$1" == "-q" ]; then
    # 静かなモード（スクリプトから呼び出す用）
    check_auth_status
    exit $?
else
    # 通常モード
    main
fi