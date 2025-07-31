#!/bin/bash

# Gemini CLI 認証セットアップスクリプト

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Gemini CLI 認証セットアップ ===${NC}"
echo ""

# コンテナ内の.geminiディレクトリの権限を調整
# devcontainerでマウントされたディレクトリはroot所有になることがあるため、現在のユーザーに所有権を移譲する
if [ -d "$HOME/.gemini" ]; then
    # echo "Adjusting permissions for $HOME/.gemini..."
    sudo chown -R "$(id -u):$(id -g)" "$HOME/.gemini"
fi

# Gemini CLIがインストールされているか確認
if ! command -v gemini &> /dev/null; then
    echo -e "${RED}エラー: Gemini CLIがインストールされていません${NC}"
    echo "以下のコマンドでインストールしてください："
    echo "  npm install -g @google/gemini-cli"
    exit 1
fi

# ブラウザが利用可能な環境かチェック
if [ -z "$DISPLAY" ] && [ -z "$BROWSER" ] && ! command -v xdg-open &> /dev/null && ! command -v open &> /dev/null; then
    echo -e "${YELLOW}警告: ブラウザが利用できない環境の可能性があります${NC}"
    echo ""
    echo "以下の方法で対処してください："
    echo ""
    echo "1. ローカルマシンでの認証："
    echo "   a. ローカルマシンで gemini コマンドを実行"
    echo "   b. ~/.gemini/credentials.json をこのマシンにコピー"
    echo ""
    echo "2. APIキーを使用："
    echo "   a. https://aistudio.google.com/app/apikey でAPIキーを取得"
    echo "   b. export GEMINI_API_KEY=your-api-key-here"
    echo ""
    echo "3. SSH転送を使用（SSH接続の場合）："
    echo "   ssh -X または ssh -Y でSSH接続"
    echo ""
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

# 認証実行
echo ""
echo -e "${YELLOW}ブラウザが開きます。Googleアカウントでログインしてください。${NC}"
echo "※ ブラウザが自動的に開かない場合は、表示されるURLを手動でブラウザに入力してください"
echo ""

# タイムアウトを長めに設定
export GEMINI_AUTH_TIMEOUT=300  # 5分

# 認証コマンド実行
if gemini auth; then
    echo ""
    echo -e "${GREEN}認証が完了しました！${NC}"
    echo ""
    
    # 認証情報の確認
    if [ -f "$HOME/.gemini/credentials.json" ]; then
        echo "認証情報が保存されました: ~/.gemini/credentials.json"
    fi
    
    # テスト実行
    echo "接続テストを実行しています..."
    if echo "こんにちは" | gemini -p "この挨拶に短く返答してください" &> /dev/null; then
        echo -e "${GREEN}Gemini CLIが正常に動作しています${NC}"
    else
        echo -e "${YELLOW}警告: テスト実行に失敗しました。API制限の可能性があります${NC}"
    fi
else
    echo ""
    echo -e "${RED}認証に失敗しました${NC}"
    echo ""
    echo "トラブルシューティング："
    echo "1. ネットワーク接続を確認"
    echo "2. ブラウザのポップアップブロッカーを無効化"
    echo "3. 別のブラウザで試す"
    echo "4. APIキーを使用（上記参照）"
    exit 1
fi

echo ""
echo "次のステップ："
echo "  make convert    # 変換を開始"
echo "  make test       # テスト変換を実行"