#!/bin/bash
# 単一ファイル変換スクリプト

# 共通関数を読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/utils.sh"

if [ $# -ne 2 ]; then
    echo "使用方法: $0 <入力ファイル> <出力ファイル>"
    exit 1
fi

INPUT_FILE=$1
OUTPUT_FILE=$2

# ファイル内容を読み込み
CONTENT=$(cat "$INPUT_FILE")

# プロンプトの生成
PROMPT="以下の口語テキストを文語形式に変換し、RAG用に最適化してください。

入力テキスト:
$CONTENT"

# Geminiで変換
if gemini_wrapper "$PROMPT" "$OUTPUT_FILE"; then
    echo "変換完了: $OUTPUT_FILE"
else
    echo "エラー: 変換に失敗しました"
    exit 1
fi
