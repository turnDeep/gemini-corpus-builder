#!/bin/bash

# Gemini CLI 認証セットアップスクリプト（シンプル版）

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Gemini CLI 認証セットアップ ===${NC}"
echo ""

# Gemini CLIがインストールされているか確認
if ! command -v gemini &> /dev/null; then
    echo -e "${RED}エラー: Gemini CLIがインストールされていません${NC}"
    echo "以下のコマンドでインストールしてください："
    echo "  npm install -g @google/gemini-cli"
    exit 1
fi

# 既存の認証情報確認
if [ -f "$HOME/.gemini/credentials.json" ]; then
    echo -e "${GREEN}既存の認証情報が見つかりました${NC}"
    echo -n "再認証しますか？ [y/N]: "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "認証をスキップします"
        exit 0
    fi
fi

# 認証実行（環境変数を設定せずにデフォルトで実行）
echo ""
echo -e "${YELLOW}認証を開始します...${NC}"
echo "表示されるURLをブラウザで開いてください"
echo ""

# シンプルに認証コマンドを実行
if gemini auth login; then
    echo ""
    echo -e "${GREEN}認証が完了しました！${NC}"
    
    # テスト実行
    echo "接続テストを実行しています..."
    if echo "Hello" | gemini -p "Say OK" 2>&1 | grep -qi "ok"; then
        echo -e "${GREEN}✓ Gemini CLIが正常に動作しています${NC}"
    fi
else
    echo ""
    echo -e "${RED}認証に失敗しました${NC}"
    echo ""
    echo "トラブルシューティング："
    echo "1. 表示されたURLをブラウザで開いたか確認"
    echo "2. ネットワーク接続を確認"
    echo "3. 以下の代替方法を試す："
    echo "   - APIキーを使用: export GEMINI_API_KEY=..."
    exit 1
fi