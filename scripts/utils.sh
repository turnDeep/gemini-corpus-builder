#!/bin/bash

# Gemini Corpus Builder - 共通ユーティリティ関数

# スクリプトディレクトリを取得
UTILS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ログ関数 (呼び出し元のスクリプトで定義されていることを想定)
# log() { ... }

# ファイルサイズをチェック
check_file_size() {
    local file=$1
    # statコマンドの互換性対応
    stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null
}

# ファイルが大容量かチェック
is_large_file() {
    local file=$1
    local size
    size=$(check_file_size "$file")
    # MAX_FILE_SIZEは呼び出し元で定義されていることを想定
    [ "$size" -gt "${MAX_FILE_SIZE:-50000}" ]
}

# ファイル名をサニタイズする関数
sanitize_filename() {
    # スラッシュ、ヌル文字、その他制御文字を削除
    # スペースと特殊文字をアンダースコアに置換
    # 連続するアンダースコアを一つにまとめる
    # 先頭と末尾のアンダースコアを削除
    echo "$1" | tr -d '/\0' | tr '[:space:][:punct:]' '_' | sed 's/__*/_/g' | sed 's/^_//;s/_$//'
}

# 認証チェック関数
check_gemini_auth() {
    if [ -f "$UTILS_SCRIPT_DIR/check_auth.sh" ]; then
        "$UTILS_SCRIPT_DIR/check_auth.sh" --quiet
        return $?
    else
        # check_auth.shがない場合は簡易チェック
        if [ -f "$HOME/.gemini/credentials.json" ] || [ -n "$GEMINI_API_KEY" ]; then
            return 0
        else
            return 1
        fi
    fi
}

# Geminiコマンドのラッパー関数（ロギング・認証エラー対応）
gemini_wrapper() {
    local prompt="$1"
    local output_file="${2:-}" # 出力ファイルは任意

    # 初回実行時に認証チェック（グローバル変数で1回だけ実行）
    if [ -z "$GEMINI_AUTH_CHECKED" ]; then
        if ! check_gemini_auth; then
            echo "エラー: Gemini CLIの認証が必要です。'make auth' を実行してください。" >&2
            exit 1
        fi
        export GEMINI_AUTH_CHECKED=1
    fi

    # log関数が存在し、LOG_LEVELがdebugの場合のみプロンプトをログに出力
    if declare -f log > /dev/null && [ "${LOG_LEVEL}" == "debug" ]; then
        log "--- Gemini Prompt ---\n$prompt\n---------------------"
    fi

    local response
    local stderr_output
    local stderr_file=$(mktemp)
    
    # geminiコマンドを実行し、標準エラー出力を一時ファイルに保存
    if response=$(gemini -p "$prompt" 2>"$stderr_file"); then
        # log関数が存在し、LOG_LEVELがdebugの場合のみレスポンスをログに出力
        if declare -f log > /dev/null && [ "${LOG_LEVEL}" == "debug" ]; then
            log "--- Gemini Response ---\n$response\n-----------------------"
        fi

        if [ -n "$output_file" ]; then
            echo "$response" > "$output_file"
        else
            echo "$response"
        fi
        
        # 一時ファイルを削除
        rm -f "$stderr_file"
        return 0
    else
        # エラー内容を読み取り
        stderr_output=$(cat "$stderr_file")
        
        # 認証エラーのチェック
        if echo "$stderr_output" | grep -qE "401|403|Unauthorized|Forbidden|credentials"; then
            # log関数が存在すればログに、なければ標準エラー出力にエラーを書き込む
            if declare -f log > /dev/null; then
                log "エラー: Gemini認証エラーが発生しました。'make auth' で再認証してください。"
            else
                echo "エラー: Gemini認証エラーが発生しました。'make auth' で再認証してください。" >&2
            fi
            # 認証チェックフラグをリセット
            unset GEMINI_AUTH_CHECKED
        elif echo "$stderr_output" | grep -qE "rate limit|429|Too Many Requests"; then
            if declare -f log > /dev/null; then
                log "エラー: APIレート制限に達しました。しばらく待ってから再試行してください。"
            else
                echo "エラー: APIレート制限に達しました。しばらく待ってから再試行してください。" >&2
            fi
        else
            # その他のエラー
            if declare -f log > /dev/null; then
                log "エラー: Geminiコマンドの実行に失敗しました。詳細: $stderr_output"
            else
                echo "エラー: Geminiコマンドの実行に失敗しました。" >&2
                echo "詳細: $stderr_output" >&2
            fi
        fi
        
        # エラーログファイルがある場合は詳細を記録
        if [ -n "$LOG_FILE" ]; then
            echo "[$(date +'%Y-%m-%d %H:%M:%S')] Gemini Error: $stderr_output" >> "$LOG_FILE"
        fi
        
        # 一時ファイルを削除
        rm -f "$stderr_file"
        return 1
    fi
}
export -f gemini_wrapper

# 変換されたテキストからファイル名を生成する関数
generate_filename_from_content() {
    local content_file=$1
    local max_chars=1000

    local truncated_content=$(head -c $max_chars "$content_file")

    local prompt="以下のテキスト内容を、ファイル名として適切な30文字程度の日本語の要約にしてください。句読点や特殊文字は含めず、簡潔な表現でお願いします。要約のみを出力してください。

テキスト：
$truncated_content
"
    local summary
    summary=$(gemini_wrapper "$prompt")

    sanitize_filename "$summary"
}

# 変換時間の予測
estimate_conversion_time() {
    local mode=$1
    shift
    local files=("$@")
    local total_files=${#files[@]}
    local total_chunks=0
    local normal_files=0
    local large_files=0

    local avg_conversion_api_time=8
    local avg_summary_api_time=3

    for file in "${files[@]}"; do
        if is_large_file "$file";
        then
            ((large_files++))
            local size
            size=$(check_file_size "$file")
            local chunks=$(( (size + CHUNK_SIZE - 1) / CHUNK_SIZE ))
            ((total_chunks += chunks))
        else
            ((normal_files++))
        fi
    done

    local api_delay=${API_DELAY:-0.5}
    local chunk_delay=${CHUNK_DELAY:-1}

    local summary_time_per_file=$avg_summary_api_time
    # 'consistency' モード以外では要約時間をゼロにする
    if [ "$mode" != "consistency" ]; then
        summary_time_per_file=0
    fi

    local normal_time_float=$(echo "$normal_files * ($avg_conversion_api_time + $summary_time_per_file) + $normal_files * $api_delay" | bc)
    local large_time_float=$(echo "$total_chunks * ($avg_conversion_api_time + $chunk_delay) + $large_files * $summary_time_per_file" | bc)
    local total_seconds_float=$(echo "$normal_time_float + $large_time_float" | bc)

    local total_seconds=${total_seconds_float%.*}

    local minutes=$(( total_seconds / 60 ))
    local seconds=$(( total_seconds % 60 ))

    echo "---"
    echo -e "${BLUE}予測変換時間: 約 ${minutes} 分 ${seconds} 秒${NC}"
    echo "  (通常ファイル: $normal_files, 大容量ファイル: $large_files, 総チャンク数: $total_chunks)"
    echo "  ※ これはあくまで目安です。ネットワークの状態やAPIの応答速度によって変動します。"
    echo "---"
}