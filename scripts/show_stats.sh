#!/bin/bash
# 詳細統計表示スクリプト（分割処理対応版）

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== 変換統計詳細 ===${NC}"
echo ""

# 基本統計
echo -e "${BLUE}◆ 基本統計${NC}"
input_count=$(find input -name "*.txt" 2>/dev/null | wc -l)
output_count=$(find output -name "*.txt" 2>/dev/null | wc -l)
echo "入力ファイル数: $input_count"
echo "出力ファイル数: $output_count"
if [ $input_count -gt 0 ]; then
    conversion_rate=$((output_count * 100 / input_count))
    echo "変換率: ${conversion_rate}%"
fi
echo ""

# ファイルサイズ統計
echo -e "${BLUE}◆ ファイルサイズ分布${NC}"
if [ -d output ] && [ "$(find output -name "*.txt" 2>/dev/null | wc -l)" -gt 0 ]; then
    # 平均サイズ
    avg_size=$(find output -name "*.txt" -exec wc -c {} \; 2>/dev/null | awk '{sum+=$1; files++} END {if(files>0) print int(sum/files); else print 0}')
    echo "平均ファイルサイズ: ${avg_size} bytes"
    
    # 最大・最小サイズ
    sizes=$(find output -name "*.txt" -exec stat -f%z {} \; 2>/dev/null || find output -name "*.txt" -exec stat -c%s {} \; 2>/dev/null | sort -n)
    if [ -n "$sizes" ]; then
        min_size=$(echo "$sizes" | head -1)
        max_size=$(echo "$sizes" | tail -1)
        echo "最小: ${min_size} bytes"
        echo "最大: ${max_size} bytes"
    fi
fi
echo ""

# 分割処理統計
echo -e "${BLUE}◆ 分割処理統計${NC}"
split_count=$(grep -l "処理方式: 分割処理" output/*.txt 2>/dev/null | wc -l)
echo "分割処理されたファイル: $split_count"
if [ $split_count -gt 0 ] && [ $output_count -gt 0 ]; then
    split_rate=$((split_count * 100 / output_count))
    echo "分割処理率: ${split_rate}%"
    
    # チャンク数の統計
    chunk_counts=$(grep -h "分割処理（[0-9]*チャンク）" output/*.txt 2>/dev/null | grep -o "[0-9]*" | sort -n)
    if [ -n "$chunk_counts" ]; then
        avg_chunks=$(echo "$chunk_counts" | awk '{sum+=$1; count++} END {if(count>0) print sum/count; else print 0}')
        max_chunks=$(echo "$chunk_counts" | tail -1)
        printf "平均チャンク数: %.1f\n" $avg_chunks
        echo "最大チャンク数: $max_chunks"
    fi
fi
echo ""

# メタデータ統計
echo -e "${BLUE}◆ メタデータ統計${NC}"
metadata_count=$(grep -l "\[文書情報\]" output/*.txt 2>/dev/null | wc -l)
if [ $output_count -gt 0 ]; then
    metadata_rate=$((metadata_count * 100 / output_count))
    echo "メタデータ付与率: ${metadata_rate}%"
fi

# キーワード統計
keyword_files=$(grep -l "キーワード:" output/*.txt 2>/dev/null | wc -l)
if [ $output_count -gt 0 ]; then
    keyword_rate=$((keyword_files * 100 / output_count))
    echo "キーワード付与率: ${keyword_rate}%"
fi
echo ""

# 整合性統計
if [ -f consistency_work/consistency_report.json ]; then
    echo -e "${BLUE}◆ 整合性統計${NC}"
    overall_score=$(cat consistency_work/consistency_report.json | grep -o '"overall_score":[0-9.]*' | cut -d: -f2)
    if [ -n "$overall_score" ]; then
        echo "整合性スコア: $overall_score"
    fi
    
    # 問題検出数
    issues=$(cat consistency_work/consistency_report.json | grep -o '"issues":[0-9]*' | cut -d: -f2)
    if [ -n "$issues" ]; then
        echo "検出された問題: $issues 件"
    fi
    echo ""
fi

# 処理時間統計
echo -e "${BLUE}◆ 処理時間統計${NC}"
latest_log=$(ls -t logs/conversion_*.log 2>/dev/null | head -1)
if [ -f "$latest_log" ]; then
    start_time=$(head -1 "$latest_log" | grep -o '\[[^]]*\]' | tr -d '[]')
    end_time=$(tail -1 "$latest_log" | grep -o '\[[^]]*\]' | tr -d '[]')
    
    if [ -n "$start_time" ] && [ -n "$end_time" ]; then
        echo "最終実行:"
        echo "  開始: $start_time"
        echo "  終了: $end_time"
        
        # 処理速度（ファイル/分）
        success_count=$(grep -c "成功:" "$latest_log" 2>/dev/null || echo 0)
        if [ $success_count -gt 0 ]; then
            # 簡易的な時間計算（分単位）
            duration_minutes=$(( $(date -d "$end_time" +%s 2>/dev/null || date +%s) - $(date -d "$start_time" +%s 2>/dev/null || date +%s) ))
            duration_minutes=$((duration_minutes / 60))
            if [ $duration_minutes -gt 0 ]; then
                files_per_minute=$((success_count / duration_minutes))
                echo "  処理速度: 約 $files_per_minute ファイル/分"
            fi
        fi
    fi
    
    # エラー統計
    error_count=$(grep -c "エラー:" "$latest_log" 2>/dev/null || echo 0)
    if [ $error_count -gt 0 ]; then
        echo "  エラー数: $error_count"
    fi
fi
echo ""

# 推奨事項
echo -e "${YELLOW}◆ 推奨事項${NC}"
if [ $split_count -gt 10 ]; then
    echo "• 多数のファイルが分割処理されています。"
    echo "  MAX_FILE_SIZE の値を調整することを検討してください。"
fi

if [ $output_count -lt $input_count ]; then
    missing=$((input_count - output_count))
    echo "• $missing 個のファイルが未変換です。"
    echo "  エラーログを確認してください: logs/"
fi

if [ "$metadata_rate" -lt 100 ] 2>/dev/null; then
    echo "• 一部のファイルでメタデータが欠落しています。"
    echo "  make validate で詳細を確認してください。"
fi
