#!/bin/bash

# Gemini Corpus Builder - 共通ユーティリティ関数

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

# Geminiコマンドのラッパー関数（ロギング対応）
gemini_wrapper() {
    local prompt="$1"
    local output_file="${2:-}" # 出力ファイルは任意

    # log関数が存在し、LOG_LEVELがdebugの場合のみプロンプトをログに出力
    if declare -f log > /dev/null && [ "${LOG_LEVEL}" == "debug" ]; then
        log "--- Gemini Prompt ---\n$prompt\n---------------------"
    fi

    local response
    local stderr_dest
    # LOG_FILEが設定されている場合はそこへ、なければ/dev/nullへエラー出力をリダイレクト
    if [ -n "$LOG_FILE" ]; then
        stderr_dest="$LOG_FILE"
    else
        stderr_dest="/dev/null"
    fi

    if response=$(gemini -p "$prompt" 2>> "$stderr_dest"); then
        # log関数が存在し、LOG_LEVELがdebugの場合のみレスポンスをログに出力
        if declare -f log > /dev/null && [ "${LOG_LEVEL}" == "debug" ]; then
            log "--- Gemini Response ---\n$response\n-----------------------"
        fi

        if [ -n "$output_file" ]; then
            echo "$response" > "$output_file"
        else
            echo "$response"
        fi
        return 0
    else
        # log関数が存在すればログに、なければ標準エラー出力にエラーを書き込む
        if declare -f log > /dev/null; then
            log "エラー: Geminiコマンドの実行に失敗しました。"
        else
            echo "エラー: Geminiコマンドの実行に失敗しました。" >&2
        fi
        response="GEMINI_COMMAND_FAILED"
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
