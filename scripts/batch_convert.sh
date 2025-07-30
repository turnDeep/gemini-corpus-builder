#!/bin/bash

# Gemini Corpus Builder - バッチ変換スクリプト

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

# 初期化
echo -e "${GREEN}=== Gemini Corpus Builder ===${NC}"
log "バッチ変換を開始します"

# ディレクトリ確認
mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

# 入力ファイルの取得
mapfile -t input_files < <(find "$INPUT_DIR" -name "*.txt" -type f | sort)
total_files=${#input_files[@]}

if [ $total_files -eq 0 ]; then
    echo -e "${RED}エラー: 入力ファイルが見つかりません${NC}"
    exit 1
fi

log "処理対象ファイル数: $total_files"
echo -e "${YELLOW}処理対象: $total_files ファイル${NC}"

# Geminiプロンプトテンプレート
PROMPT_TEMPLATE='以下の口語テキストを文語形式に変換し、RAG用のコーパスとして最適化してください。

入力ファイル: INPUT_FILE
出力ファイル: OUTPUT_FILE

変換時は以下を実行してください：
1. 口語表現を適切な文語表現に変換
2. RAG検索に適した構造化
3. メタデータの自動付与
4. write-fileツールを使用して結果を自動保存（確認不要）

入力テキスト:
INPUT_CONTENT'

# バッチ処理
batch_count=$(( (total_files + BATCH_SIZE - 1) / BATCH_SIZE ))
processed=0
errors=0

echo ""
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
        show_progress $processed $total_files
        
        # ファイル内容の読み込み
        if [ -f "$input_file" ]; then
            content=$(cat "$input_file")
            
            # プロンプトの生成
            prompt=${PROMPT_TEMPLATE//INPUT_FILE/$input_file}
            prompt=${prompt//OUTPUT_FILE/$output_file}
            prompt=${prompt//INPUT_CONTENT/$content}
            
            # Geminiで変換実行
            if gemini -p "$prompt" >> "$LOG_FILE" 2>&1; then
                log "成功: $filename"
            else
                log "エラー: $filename"
                ((errors++))
            fi
        else
            log "ファイルが見つかりません: $input_file"
            ((errors++))
        fi
        
        # APIレート制限対策（必要に応じて調整）
        sleep 0.5
    done
    
    # バッチ間の休憩
    if [ $batch -lt $((batch_count - 1)) ]; then
        echo ""
        echo -e "${YELLOW}バッチ $((batch + 1)) 完了。次のバッチまで5秒待機...${NC}"
        sleep 5
    fi
done

echo ""
echo ""

# 結果サマリー
success=$((processed - errors))
echo -e "${GREEN}=== 変換完了 ===${NC}"
echo "処理ファイル数: $processed"
echo -e "${GREEN}成功: $success${NC}"
if [ $errors -gt 0 ]; then
    echo -e "${RED}エラー: $errors${NC}"
fi

log "バッチ変換完了 - 成功: $success, エラー: $errors"

# 検証の実行を提案
echo ""
echo "変換結果を検証するには以下を実行してください："
echo "  make validate"
