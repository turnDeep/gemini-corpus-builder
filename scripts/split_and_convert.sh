#!/bin/bash

# Gemini Corpus Builder - 分割変換共通関数

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/utils.sh"

# 設定
TEMP_DIR="temp_chunks"
MAX_FILE_SIZE=${MAX_FILE_SIZE:-50000}  # 50KB以上を大きいファイルとする
CHUNK_SIZE=${CHUNK_SIZE:-30000}        # 30KB単位で分割
CHUNK_DELAY=${CHUNK_DELAY:-1}          # チャンク間の遅延


# テキストを段落で分割
split_by_paragraphs() {
    local input_file=$1
    local output_prefix=$2
    local max_chunk_size=$3
    
    # 段落や長大な行を考慮して、より堅牢な分割を実行
    awk -v prefix="$output_prefix" -v max_size="$max_chunk_size" '
    function new_chunk() {
        if (output_file != "") close(output_file);
        chunk_num++;
        output_file = prefix "_chunk_" chunk_num ".txt";
        current_size = 0;
    }

    BEGIN {
        chunk_num = 0;
        output_file = "";
        new_chunk();
    }
    {
        if (NF == 0) {
            if (current_size > 0 && current_size < max_size) {
                print "" >> output_file;
                current_size++;
            }
            next;
        }

        line = $0;
        while (length(line) > 0) {
            if (current_size >= max_size) {
                new_chunk();
            }

            remaining_space = max_size - current_size;
            piece = substr(line, 1, remaining_space);

            if (length(piece) == 0) {
                line = ""; # Should not happen, but as a safeguard
                continue;
            }

            printf "%s", piece >> output_file;
            current_size += length(piece);

            line = substr(line, length(piece) + 1);
        }
        
        # Add a newline after processing the original line, mimicking `print`
        if (current_size > 0 && current_size < max_size) {
            print "" >> output_file;
            current_size++;
        }
    }
    END {
        if (output_file != "") close(output_file);
        print chunk_num;
    }' "$input_file"
}

# チャンクを変換（整合性ルール対応版）
convert_chunk_with_rules() {
    local chunk_file=$1
    local chunk_output=$2
    local original_filename=$3
    local chunk_number=$4
    local total_chunks=$5
    local consistency_rules=$6
    local global_dict=$7
    
    # チャンクの内容を読み込み
    local content=$(cat "$chunk_file")
    
    # プロンプトの構築
    local prompt="以下は大きなファイル「$original_filename」の一部（チャンク $chunk_number/$total_chunks）です。"
    
    # 整合性ルールがある場合は追加
    if [ -n "$consistency_rules" ] && [ "$consistency_rules" != "null" ]; then
        prompt="$prompt

## 整合性ルール
$consistency_rules"
    fi
    
    # グローバル辞書がある場合は追加
    if [ -n "$global_dict" ] && [ "$global_dict" != "null" ]; then
        prompt="$prompt

## グローバル辞書
$global_dict"
    fi
    
    prompt="$prompt

この部分を文語形式に変換し、RAG用に最適化してください。

注意事項：
- これは完全な文書の一部分です
- 文の途中から始まる場合は、文脈を推測して適切に処理してください
- 変換後も部分的な文書として自然に読めるようにしてください
- 整合性ルールとグローバル辞書がある場合は厳密に適用してください

入力テキスト:
$content

変換後の文語テキストのみを出力してください。"
    
    # Geminiで変換
    if gemini_wrapper "$prompt" "$chunk_output"; then
        return 0
    else
        return 1
    fi
}

# チャンクを結合
merge_chunks() {
    local base_name=$1
    local output_file=$2
    local total_chunks=$3
    local original_file=$4
    
    # ヘッダーを追加
    {
        echo "[文書情報]"
        echo "- 変換日時: $(date +'%Y-%m-%d %H:%M:%S')"
        echo "- 元ファイル: $(basename "$original_file")"
        echo "- 処理方式: 分割処理（${total_chunks}チャンク）"
        echo ""
    } > "$output_file"
    
    # チャンクを順番に結合
    for ((i=1; i<=total_chunks; i++)); do
        local chunk_file="${TEMP_DIR}/${base_name}_chunk_${i}_converted.txt"
        if [ -f "$chunk_file" ]; then
            cat "$chunk_file" >> "$output_file"
            # 最後のチャンク以外は空行を挿入
            if [ $i -lt $total_chunks ]; then
                echo "" >> "$output_file"
            fi
        fi
    done
}

# 統合変換関数（通常/分割を自動判定）
smart_convert_file() {
    local input_file=$1
    local output_file=$2
    local consistency_rules=${3:-""}
    local global_dict=${4:-""}
    local log_func=${5:-echo}
    
    local filename=$(basename "$input_file")
    local base_name="${filename%.*}"
    
    # ファイルサイズチェック
    if is_large_file "$input_file"; then
        local size=$(check_file_size "$input_file")
        local size_kb=$((size / 1024))
        $log_func "大容量ファイル検出: $filename (${size_kb}KB) - 分割処理を実行"
        
        # 一時ディレクトリ作成
        mkdir -p "$TEMP_DIR"
        
        # ファイルを分割
        local total_chunks=$(split_by_paragraphs "$input_file" "$TEMP_DIR/$base_name" "$CHUNK_SIZE")
        $log_func "  → ${total_chunks}個のチャンクに分割"
        
        # 各チャンクを変換
        local success_count=0
        for ((i=1; i<=total_chunks; i++)); do
            local chunk_file="$TEMP_DIR/${base_name}_chunk_${i}.txt"
            local chunk_output="$TEMP_DIR/${base_name}_chunk_${i}_converted.txt"
            
            if convert_chunk_with_rules "$chunk_file" "$chunk_output" "$filename" $i $total_chunks "$consistency_rules" "$global_dict"; then
                ((success_count++))
            else
                $log_func "  ⚠ チャンク $i の変換に失敗"
            fi
            
            # API負荷軽減
            sleep "$CHUNK_DELAY"
        done
        
        # チャンクを結合
        merge_chunks "$base_name" "$output_file" "$total_chunks" "$input_file"
        
        # 一時ファイルをクリーンアップ
        rm -f "${TEMP_DIR}/${base_name}_chunk_"*.txt
        
        if [ $success_count -eq $total_chunks ]; then
            $log_func "  ✓ 分割処理完了 ($success_count/$total_chunks チャンク成功)"
            return 0
        else
            $log_func "  ⚠ 部分的完了 ($success_count/$total_chunks チャンク成功)"
            return 1
        fi
    else
        # 通常サイズのファイルは従来の処理
        return 2  # 呼び出し元で通常処理を実行
    fi
}

# クリーンアップ関数
cleanup_temp_files() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}
