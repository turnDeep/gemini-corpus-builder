#!/bin/bash

# Gemini Corpus Builder - 大容量ファイル専用処理スクリプト

# 共通関数を読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/split_and_convert.sh"

# 設定
INPUT_DIR="input"
OUTPUT_DIR="output"
LOG_DIR="logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/large_files_${TIMESTAMP}.log"

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# ログ関数
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# メイン処理
main() {
    echo -e "${BLUE}=== 大容量ファイル専用処理システム ===${NC}"
    log "大容量ファイル処理を開始します"
    
    # ディレクトリ準備
    mkdir -p "$OUTPUT_DIR" "$LOG_DIR"
    
    # 引数でファイルが指定された場合
    if [ $# -gt 0 ]; then
        echo "指定されたファイルを処理します..."
        for file in "$@"; do
            if [ -f "$file" ]; then
                local filename=$(basename "$file")
                local output_file="$OUTPUT_DIR/$filename"
                
                echo -e "${GREEN}処理中: $filename${NC}"
                
                # smart_convert_fileで処理（強制的に分割処理）
                MAX_FILE_SIZE=0  # 全てのファイルを分割処理
                if smart_convert_file "$file" "$output_file" "" "" "log"; then
                    echo -e "  ${GREEN}✓ 完了${NC}"
                else
                    echo -e "  ${RED}✗ エラー${NC}"
                fi
            else
                echo -e "${RED}エラー: ファイルが見つかりません: $file${NC}"
            fi
        done
    else
        # 全大容量ファイルを検出して処理
        echo "大容量ファイルを検出中..."
        large_files=()
        while IFS= read -r file; do
            size=$(check_file_size "$file")
            if [ "$size" -gt "$MAX_FILE_SIZE" ]; then
                large_files+=("$file")
                size_mb=$(printf "%.2f" $(echo "scale=2; $size / 1024 / 1024" | bc))
                echo -e "${YELLOW}検出: $(basename "$file") (${size_mb}MB)${NC}"
                log "大容量ファイル検出: $file (${size}バイト)"
            fi
        done < <(find "$INPUT_DIR" -name "*.txt" -type f)
        
        if [ ${#large_files[@]} -eq 0 ]; then
            echo "大容量ファイルは見つかりませんでした。"
            echo "通常の変換処理を使用してください: make convert"
            exit 0
        fi
        
        echo ""
        echo "検出された大容量ファイル: ${#large_files[@]} 個"
        echo ""
        
        # 各大容量ファイルを処理
        local total=${#large_files[@]}
        local current=0
        local success=0
        local errors=0
        
        for file in "${large_files[@]}"; do
            ((current++))
            local filename=$(basename "$file")
            local output_file="$OUTPUT_DIR/$filename"
            
            echo -e "${GREEN}[$current/$total] 処理中: $filename${NC}"
            log "ファイル処理開始: $file"
            
            # smart_convert_fileで処理
            if smart_convert_file "$file" "$output_file" "" "" "log"; then
                ((success++))
            else
                ((errors++))
            fi
            
            echo ""
            
            # 処理間の休憩
            if [ $current -lt $total ]; then
                sleep 2
            fi
        done
        
        # 結果サマリー
        echo -e "${GREEN}=== 処理完了 ===${NC}"
        echo "処理ファイル数: $total"
        echo -e "${GREEN}成功: $success${NC}"
        if [ $errors -gt 0 ]; then
            echo -e "${RED}エラー: $errors${NC}"
        fi
        log "大容量ファイル処理完了 - 成功: $success, エラー: $errors"
    fi
    
    # クリーンアップ
    cleanup_temp_files
}

# スクリプト実行
main "$@"
