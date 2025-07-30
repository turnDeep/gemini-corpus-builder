#!/bin/bash

# Gemini Corpus Builder - 変換結果検証スクリプト

# 設定
OUTPUT_DIR="output"
LOG_FILE="logs/validation_$(date +%Y%m%d_%H%M%S).log"

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# カウンター初期化
total_files=0
valid_files=0
invalid_files=0
warnings=0

# ログ関数
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 検証開始
echo -e "${GREEN}=== 変換結果検証 ===${NC}"
log "検証を開始します"

# 出力ファイルの取得
mapfile -t output_files < <(find "$OUTPUT_DIR" -name "*.txt" -type f | sort)
total_files=${#output_files[@]}

if [ $total_files -eq 0 ]; then
    echo -e "${RED}エラー: 出力ファイルが見つかりません${NC}"
    exit 1
fi

echo "検証対象: $total_files ファイル"
echo ""

# 検証項目
check_file() {
    local file=$1
    local filename=$(basename "$file")
    local errors=()
    local warns=()
    
    # ファイルサイズチェック
    if [ ! -s "$file" ]; then
        errors+=("ファイルが空です")
    fi
    
    # 内容の読み込み
    content=$(cat "$file" 2>/dev/null)
    
    # 文語化チェック
    if echo "$content" | grep -qE "(だよ|だね|かな|じゃない|ちゃった)"; then
        warns+=("口語表現が残っています")
    fi
    
    # メタデータチェック
    if ! echo "$content" | grep -q "\[文書情報\]"; then
        errors+=("メタデータが不足しています")
    fi
    
    # 文体の一貫性チェック
    if echo "$content" | grep -qE "(です。|ます。)" && echo "$content" | grep -qE "(である。|だ。)"; then
        warns+=("文体が混在しています")
    fi
    
    # 構造チェック
    line_count=$(echo "$content" | wc -l)
    if [ $line_count -lt 3 ]; then
        errors+=("内容が短すぎます")
    fi
    
    # 結果の出力
    if [ ${#errors[@]} -eq 0 ] && [ ${#warns[@]} -eq 0 ]; then
        echo -e "[${GREEN}OK${NC}] $filename"
        ((valid_files++))
    elif [ ${#errors[@]} -eq 0 ]; then
        echo -e "[${YELLOW}WARN${NC}] $filename"
        for warn in "${warns[@]}"; do
            echo "      ⚠ $warn"
            log "警告 - $filename: $warn"
        done
        ((valid_files++))
        ((warnings++))
    else
        echo -e "[${RED}ERROR${NC}] $filename"
        for error in "${errors[@]}"; do
            echo "      ✗ $error"
            log "エラー - $filename: $error"
        done
        ((invalid_files++))
    fi
}

# プログレスバー付き検証
echo "検証中..."
for i in "${!output_files[@]}"; do
    # プログレス表示
    printf "\r進捗: %d/%d" $((i + 1)) $total_files
    
    # ファイル検証
    check_file "${output_files[$i]}" > /tmp/check_result.tmp
    
    # 結果を表示（プログレスバーを上書きしないように）
    printf "\r\033[K"
    cat /tmp/check_result.tmp
done

rm -f /tmp/check_result.tmp

# サマリー
echo ""
echo -e "${GREEN}=== 検証結果サマリー ===${NC}"
echo "総ファイル数: $total_files"
echo -e "${GREEN}有効: $valid_files${NC}"
echo -e "${YELLOW}警告: $warnings${NC}"
echo -e "${RED}無効: $invalid_files${NC}"

# 成功率
success_rate=$(( valid_files * 100 / total_files ))
echo ""
echo "成功率: ${success_rate}%"

# 品質スコア
quality_score=$(( (valid_files * 100 - warnings * 10) / total_files ))
echo "品質スコア: ${quality_score}/100"

log "検証完了 - 有効: $valid_files, 警告: $warnings, 無効: $invalid_files"

# 推奨事項
if [ $invalid_files -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}推奨事項:${NC}"
    echo "- エラーファイルの再変換を検討してください"
    echo "- ログファイルで詳細を確認: $LOG_FILE"
fi

if [ $warnings -gt 10 ]; then
    echo ""
    echo -e "${YELLOW}品質改善の提案:${NC}"
    echo "- .gemini/GEMINI.mdの変換ルールを見直してください"
    echo "- サンプルファイルでテストを実施してください"
fi
