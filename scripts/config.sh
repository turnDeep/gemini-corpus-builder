#!/bin/bash
# 共通設定ファイル

# API設定
export BATCH_SIZE=50
export API_DELAY=0.5
export MAX_RETRIES=3

# ディレクトリ設定
export INPUT_DIR="input"
export OUTPUT_DIR="output"
export LOG_DIR="logs"

# 変換設定
export CONVERSION_MODE="standard"  # standard/strict/lenient
export INCLUDE_METADATA=true
export PRESERVE_STRUCTURE=true