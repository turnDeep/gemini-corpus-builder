#!/bin/bash
# 単一ファイル変換スクリプト

if [ $# -ne 2 ]; then
    echo "使用方法: $0 <入力ファイル> <出力ファイル>"
    exit 1
fi

INPUT_FILE=$1
OUTPUT_FILE=$2

# ファイル内容を読み込み
CONTENT=$(cat "$INPUT_FILE")

# Geminiで変換
gemini -p "以下の口語テキストを文語形式に変換し、RAG用に最適化してください。
write-fileツールを使用して結果を「$OUTPUT_FILE」に自動保存してください。

入力テキスト:
$CONTENT"

echo "変換完了: $OUTPUT_FILE"