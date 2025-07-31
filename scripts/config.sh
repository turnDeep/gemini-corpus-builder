#!/bin/bash
# 共通設定ファイル

# API設定
export BATCH_SIZE=50              # バッチ処理のファイル数
export API_DELAY=0.5              # 通常ファイルのAPI遅延（秒）
export MAX_RETRIES=3              # リトライ回数

# ディレクトリ設定
export INPUT_DIR="input"
export OUTPUT_DIR="output"
export LOG_DIR="logs"
export WORK_DIR="consistency_work"
export TEMP_DIR="temp_chunks"

# 変換設定
export CONVERSION_MODE="standard"  # standard/strict/lenient
export INCLUDE_METADATA=true
export PRESERVE_STRUCTURE=true

# 大容量ファイル設定
export MAX_FILE_SIZE=50000        # 50KB以上を大容量とみなす
export CHUNK_SIZE=30000           # 30KB単位で分割
export LARGE_FILE_TIMEOUT=300     # 大容量ファイルのタイムアウト（秒）
export CHUNK_DELAY=1              # チャンク間の待機時間（秒）

# 分割処理設定
export AUTO_SPLIT=true            # 自動分割を有効化
export SPLIT_BY_PARAGRAPH=true    # 段落単位で分割
export MIN_CHUNK_SIZE=5000        # 最小チャンクサイズ（5KB）
export MAX_CHUNKS=20              # 最大チャンク数

# ログ設定
export LOG_LEVEL="info"           # debug/info/warn/error
export LOG_ROTATION=true          # ログローテーション有効化
export MAX_LOG_SIZE="100M"        # 最大ログサイズ

# 整合性管理設定
export CONSISTENCY_CHECK=true     # 整合性チェック有効化
export GLOBAL_DICT_UPDATE=true    # グローバル辞書の自動更新
export AUTO_CORRECTION=false      # 自動修正（デフォルトは手動確認）

# 認証設定
# ブラウザ認証を有効にするため、NO_BROWSERは設定しない
# export NO_BROWSER=true を削除