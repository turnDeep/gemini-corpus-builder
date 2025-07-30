#!/bin/bash

# Gemini Corpus Builder - バッチ変換スクリプト（自動分割対応版）

# 共通関数を読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/split_and_convert.sh"

# 設定
INPUT_DIR="input"
OUTPUT_DIR="output"
LOG_DIR="logs"
BATCH_SIZE=50
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/conversion_${TIMESTAMP}.log"

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

# プログレスバー関数
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    
    printf "\r["
    printf "%${completed}s" | tr ' ' '='
    printf "%$((width - completed))s" | tr ' ' ' '
    printf "] %d%% (%d/%d)" $percentage $current $total
}

# 通常変換（大容量ファイルは自動分割）
convert_file_auto() {
    local input_file=$1
    local output_file=$2
    local filename=$(basename "$input_file")
    
    # smart_convert_fileで自動判定
    smart_convert_file "$input_file" "$output_file" "" "" "log"
    local result=$?
    
    if [ $result -eq 2 ]; then
        # 通常サイズのファイルの処理
        local content=$(cat "$input_file")
        
        # プロンプトの生成
        local prompt="以下の口語テキストを文語形式に変換し、RAG用のコーパスとして最適化してください。

変換時は以下を実行してください：
1. 口語表現を適切な文語表現に変換
2. RAG検索に適した構造化
3. メタデータの自動付与

生成された文語体のテキストのみを出力してください。追加の説明や前置きは不要です。

入力テキスト:
$content"
        
        # Geminiで変換実行
        if gemini_wrapper "$prompt" "$output_file"; then
            if [ -s "$output_file" ]; then
                log "成功: $filename"
                return 0
            else
                log "エラー: $filename (出力ファイルが空です)"
                return 1
            fi
        else
            log "エラー: $filename (geminiコマンド失敗)"
            return 1
        fi
    else
        return $result
    fi
}

# 初期化
echo -e "${GREEN}=== Gemini Corpus Builder (自動分割対応版) ===${NC}"
log "バッチ変換を開始します"

# ディレクトリ確認
mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

# 入力ファイルの取得と分析
mapfile -t input_files < <(find "$INPUT_DIR" -name "*.txt" -type f | sort)
total_files=${#input_files[@]}

if [ $total_files -eq 0 ]; then
    echo -e "${RED}エラー: 入力ファイルが見つかりません${NC}"
    exit 1
fi

# 大容量ファイルの事前検出
echo "ファイルを分析中..."
large_count=0
for file in "${input_files[@]}"; do
    if is_large_file "$file"; then
        ((large_count++))
    fi
done

log "処理対象ファイル数: $total_files (うち大容量: $large_count)"
echo -e "${YELLOW}処理対象: $total_files ファイル${NC}"
if [ $large_count -gt 0 ]; then
    echo -e "${BLUE}  ※ ${large_count}個の大容量ファイルは自動的に分割処理されます${NC}"
fi
echo ""

# 変換時間の予測を表示
estimate_conversion_time "simple" "${input_files[@]}"

# バッチ処理
batch_count=$(( (total_files + BATCH_SIZE - 1) / BATCH_SIZE ))
processed=0
errors=0
split_processed=0

echo "バッチ処理を開始します（バッチサイズ: $BATCH_SIZE）"

for ((batch=0; batch<batch_count; batch++)); do
    start=$((batch * BATCH_SIZE))
    end=$((start + BATCH_SIZE))
    if [ $end -gt $total_files ]; then
        end=$total_files
    fi
    
    log "バッチ $((batch + 1))/$batch_count を処理中..."
    
    for ((i=start; i<end; i++)); do
        input_file="${input_files[$i]}"
        filename=$(basename "$input_file")
        output_file="$OUTPUT_DIR/$filename"
        
        # 進捗表示
        ((processed++))
        
        # 大容量ファイルの場合は改行して詳細表示
        if is_large_file "$input_file"; then
            ((split_processed++))
            printf "\r\033[K"  # 現在の行をクリア
            echo -e "${YELLOW}[分割処理 $split_processed/$large_count] $filename${NC}"
            
            if convert_file_auto "$input_file" "$output_file"; then
                :
            else
                ((errors++))
            fi
            
            # 分割処理後は長めの休憩
            sleep 2
        else
            # 通常ファイルはプログレスバーで表示
            show_progress $processed $total_files
            
            if convert_file_auto "$input_file" "$output_file"; then
                :
            else
                ((errors++))
            fi
            
            # APIレート制限対策
            sleep 0.5
        fi
    done
    
    # バッチ間の休憩
    if [ $batch -lt $((batch_count - 1)) ]; then
        echo ""
        echo -e "${YELLOW}バッチ $((batch + 1)) 完了。次のバッチまで5秒待機...${NC}"
        sleep 5
    fi
done

# クリーンアップ
cleanup_temp_files

echo ""
echo ""

# 結果サマリー
success=$((processed - errors))
echo -e "${GREEN}=== 変換完了 ===${NC}"
echo "処理ファイル数: $processed"
echo -e "${GREEN}成功: $success${NC}"
if [ $split_processed -gt 0 ]; then
    echo -e "${BLUE}分割処理: $split_processed ファイル${NC}"
fi
if [ $errors -gt 0 ]; then
    echo -e "${RED}エラー: $errors${NC}"
fi

log "バッチ変換完了 - 成功: $success, エラー: $errors, 分割処理: $split_processed"

# 検証の実行を提案
echo ""
echo "変換結果を検証するには以下を実行してください："
echo "  make validate"
