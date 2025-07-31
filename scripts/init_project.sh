#!/bin/bash

# Gemini Corpus Builder - プロジェクト初期設定スクリプト

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Gemini Corpus Builder 初期設定 ===${NC}"
echo ""

# ディレクトリ作成
echo "必要なディレクトリを作成しています..."
mkdir -p input output logs .gemini/templates consistency_work test/input test/output

# .gitkeepファイルの作成
touch input/.gitkeep output/.gitkeep logs/.gitkeep
touch test/input/.gitkeep test/output/.gitkeep
touch .gemini/templates/.gitkeep consistency_work/.gitkeep

# スクリプトに実行権限を付与
echo "スクリプトに実行権限を付与しています..."
chmod +x scripts/*.sh

# 設定ファイルのコピー（存在しない場合）
if [ ! -f "$HOME/.gemini/settings.json" ] && [ -f ".gemini/settings.json" ]; then
    echo "Gemini設定ファイルをコピーしています..."
    mkdir -p "$HOME/.gemini"
    cp .gemini/settings.json "$HOME/.gemini/settings.json"
    echo -e "${GREEN}✓ ~/.gemini/settings.json を作成しました${NC}"
fi

# Gemini CLIのインストール確認
echo ""
echo "Gemini CLIのインストールを確認しています..."
if command -v gemini &> /dev/null; then
    echo -e "${GREEN}✓ Gemini CLIがインストールされています${NC}"
    gemini --version
else
    echo -e "${YELLOW}⚠ Gemini CLIがインストールされていません${NC}"
    echo ""
    echo "以下のコマンドでインストールしてください："
    echo "  npm install -g @google/gemini-cli"
fi

# 認証状態の確認
echo ""
echo "認証状態を確認しています..."
if [ -f "scripts/check_auth.sh" ]; then
    ./scripts/check_auth.sh
else
    if [ -f "$HOME/.gemini/credentials.json" ] || [ -n "$GEMINI_API_KEY" ]; then
        echo -e "${GREEN}✓ 認証情報が見つかりました${NC}"
    else
        echo -e "${YELLOW}⚠ 認証が必要です${NC}"
        echo ""
        echo "以下のコマンドで認証を行ってください："
        echo "  make auth"
    fi
fi

# サンプルファイルの作成
echo ""
echo "サンプルファイルを作成しますか？ [y/N]: "
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    cat > input/sample1.txt << 'EOF'
まあ、昨日の会議はちょっと長かったよね。でも、いろいろ重要な話ができて良かったと思うよ。
特に新しいプロジェクトの方向性が決まったのは大きいんじゃないかな。
みんなも納得してたみたいだし、これからが楽しみだね。
EOF

    cat > input/sample2.txt << 'EOF'
今日さ、久しぶりに大学時代の友達と会ったんだ。
もう10年ぶりくらいかな？すごく懐かしかったよ。
昔話に花が咲いちゃって、気づいたら3時間も話してた。
やっぱり古い友達っていいよね。
EOF

    echo -e "${GREEN}✓ サンプルファイルを作成しました${NC}"
    echo "  - input/sample1.txt"
    echo "  - input/sample2.txt"
fi

# 最終確認
echo ""
echo -e "${GREEN}=== セットアップ完了 ===${NC}"
echo ""
echo "次のステップ："

if ! command -v gemini &> /dev/null; then
    echo "1. Gemini CLIをインストール:"
    echo "   npm install -g @google/gemini-cli"
    echo ""
fi

if [ ! -f "$HOME/.gemini/credentials.json" ] && [ -z "$GEMINI_API_KEY" ]; then
    echo "2. 認証を実行:"
    echo "   make auth"
    echo ""
fi

echo "3. 変換したいテキストファイルを input/ に配置"
echo ""
echo "4. 変換を実行:"
echo "   make convert      # 基本的な変換"
echo "   make consistency  # 整合性保証付き変換（大規模向け）"
echo ""
echo "詳細は README.md および PROJECT_SETUP.md を参照してください。"