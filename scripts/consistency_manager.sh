#!/bin/bash

# Gemini Corpus Builder - 整合性管理スクリプト（自動分割対応版）

# 共通関数を読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/split_and_convert.sh"

# 設定
WORK_DIR="consistency_work"
DICT_FILE="$WORK_DIR/global_dictionary.json"
GRAPH_FILE="$WORK_DIR/document_graph.json"
CLUSTER_FILE="$WORK_DIR/clusters.json"
LOG_FILE="logs/consistency_$(date +%Y%m%d_%H%M%S).log"

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

# ファイル名をサニタイズする関数
sanitize_filename() {
    # スラッシュ、ヌル文字、その他制御文字を削除
    # スペースと特殊文字をアンダースコアに置換
    # 連続するアンダースコアを一つにまとめる
    # 先頭と末尾のアンダースコアを削除
    echo "$1" | tr -d '/\0' | tr '[:space:][:punct:]' '_' | sed 's/__*/_/g' | sed 's/^_//;s/_$//'
}

# 変換されたテキストからファイル名を生成する関数
generate_filename_from_content() {
    local content_file=$1
    local max_chars=1000 # 要約のためにGeminiに渡す最大文字数

    # ファイルの内容を切り詰める
    local truncated_content=$(head -c $max_chars "$content_file")

    # Geminiに要約を依頼
    local summary=$(gemini -p "以下のテキスト内容を、ファイル名として適切な30文字程度の日本語の要約にしてください。句読点や特殊文字は含めず、簡潔な表現でお願いします。要約のみを出力してください。

テキスト：
$truncated_content
")

    # サニタイズして返す
    sanitize_filename "$summary"
}

# 初期化
init_consistency_system() {
    echo -e "${BLUE}=== 整合性管理システム初期化 ===${NC}"
    mkdir -p "$WORK_DIR" logs output
    
    # グローバル辞書の初期化
    if [ ! -f "$DICT_FILE" ]; then
        echo '{"terms": {}, "entities": {}, "styles": {}}' > "$DICT_FILE"
    fi
    
    # ドキュメントグラフの初期化
    if [ ! -f "$GRAPH_FILE" ]; then
        echo '{"nodes": [], "edges": []}' > "$GRAPH_FILE"
    fi
    
    log "整合性管理システムを初期化しました"
}

# Phase 1: 文書分析とクラスタリング
analyze_documents() {
    echo -e "${BLUE}Phase 1: 文書分析とクラスタリング${NC}"
    
    # 大容量ファイルのチェック
    local large_count=0
    while IFS= read -r file; do
        if is_large_file "$file"; then
            ((large_count++))
        fi
    done < <(find "input" -name "*.txt" -type f)
    
    if [ $large_count -gt 0 ]; then
        echo -e "${YELLOW}  ※ ${large_count}個の大容量ファイルが検出されました${NC}"
        log "大容量ファイル数: $large_count"
    fi
    
    # Geminiで文書分析を実行
    gemini -p "以下のタスクを実行してください：
1. inputディレクトリ内の全テキストファイルを分析
2. 内容の類似性に基づいてクラスタリング
3. 各クラスタの特徴を抽出
4. 結果をJSON形式で出力

分析観点：
- トピックの類似性
- 文体の特徴
- 使用語彙の傾向
- 時系列的な関連性

注意：大きなファイルは部分的にサンプリングして分析してください。" > "$CLUSTER_FILE" 2>> "$LOG_FILE"
    
    log "文書分析完了"
}

# Phase 2: グローバル辞書構築
build_global_dictionary() {
    echo -e "${BLUE}Phase 2: グローバル辞書構築${NC}"
    
    # 既存の辞書を読み込み
    existing_dict=$(cat "$DICT_FILE" 2>/dev/null || echo '{}')
    
    gemini -p "以下のタスクを実行してください：
1. inputディレクトリの全ファイルから頻出用語を抽出
2. 口語表現と対応する文語表現のマッピングを作成
3. 固有名詞の統一表記を決定
4. 既存の辞書データとマージ：
$existing_dict

5. 更新された辞書をJSON形式で出力

辞書形式：
{
  \"terms\": {
    \"口語表現\": \"文語表現\",
    ...
  },
  \"entities\": {
    \"表記ゆれ\": \"統一表記\",
    ...
  },
  \"styles\": {
    \"カジュアル\": \"フォーマル\",
    ...
  }
}

注意：大きなファイルは効率的にサンプリングして処理してください。" > "$DICT_FILE" 2>> "$LOG_FILE"
    
    log "グローバル辞書構築完了"
}

# Phase 3: 文書間関係の分析
analyze_document_relations() {
    echo -e "${BLUE}Phase 3: 文書間関係の分析${NC}"
    
    gemini -p "以下のタスクを実行してください：
1. 全文書間の参照関係を分析
2. 時系列的な依存関係を特定
3. トピックの継続性を確認
4. ドキュメントグラフを構築してJSON形式で出力

グラフ形式：
{
  \"nodes\": [
    {\"id\": \"doc1.txt\", \"cluster\": 0, \"topics\": [...], \"is_large\": false},
    ...
  ],
  \"edges\": [
    {\"source\": \"doc1.txt\", \"target\": \"doc2.txt\", \"type\": \"reference\", \"weight\": 0.8},
    ...
  ]
}

注意：大きなファイルは「is_large\": true」とマークしてください。" > "$GRAPH_FILE" 2>> "$LOG_FILE"
    
    log "文書間関係分析完了"
}

# Phase 4: 整合性チェックルールの生成
generate_consistency_rules() {
    echo -e "${BLUE}Phase 4: 整合性チェックルール生成${NC}"
    
    # 分析結果を統合
    clusters=$(cat "$CLUSTER_FILE" 2>/dev/null)
    dictionary=$(cat "$DICT_FILE" 2>/dev/null)
    graph=$(cat "$GRAPH_FILE" 2>/dev/null)
    
    gemini -p "以下の分析結果を基に、整合性チェックルールをJSON形式で生成してください：

クラスタ情報：
$clusters

グローバル辞書：
$dictionary

文書グラフ：
$graph

生成するルール：
1. クラスタごとの変換ルール
2. 用語統一性のチェックリスト
3. 文体一貫性の基準
4. 参照整合性の検証方法
5. 大容量ファイルの特別処理ルール" > "$WORK_DIR/consistency_rules.json" 2>> "$LOG_FILE"
    
    log "整合性チェックルール生成完了"
}

# Phase 5: バッチ変換（整合性考慮・自動分割対応）
convert_with_consistency() {
    echo -e "${BLUE}Phase 5: 整合性を考慮したバッチ変換（自動分割対応）${NC}"

    # ルールとリソースを読み込み
    local rules=$(cat "$WORK_DIR/consistency_rules.json" 2>/dev/null)
    local dictionary=$(cat "$DICT_FILE" 2>/dev/null)

    # 入力ファイルの取得
    mapfile -t input_files < <(find "input" -name "*.txt" -type f | sort)
    local total_files=${#input_files[@]}

    if [ "$total_files" -eq 0 ]; then
        log "変換対象のファイルが見つかりません。"
        echo -e "${YELLOW}変換対象のファイルがinputディレクトリに見つかりません。${NC}"
        return
    fi

    # 大容量ファイルのカウント
    local large_count=0
    for file in "${input_files[@]}"; do
        if is_large_file "$file"; then
            ((large_count++))
        fi
    done

    log "整合性考慮のバッチ変換を開始します。対象ファイル数: $total_files (うち大容量: $large_count)"
    echo "クラスタベースの変換を開始... ($total_files ファイル)"
    if [ $large_count -gt 0 ]; then
        echo -e "${BLUE}  ※ ${large_count}個の大容量ファイルは自動的に分割処理されます${NC}"
    fi

    local processed=0
    local errors=0
    local split_processed=0
    
    for input_file in "${input_files[@]}"; do
        local filename=$(basename "$input_file")
        # 一時的な出力ファイルを作成
        local temp_output_file
        temp_output_file=$(mktemp "output/${filename}.tmp.XXXXXX")

        ((processed++))
        
        local conversion_success=false

        # 大容量ファイルの場合
        if is_large_file "$input_file"; then
            ((split_processed++))
            echo -e "${YELLOW}  ($processed/$total_files) [分割処理] $filename${NC}"
            
            # smart_convert_fileで自動分割処理
            if smart_convert_file "$input_file" "$temp_output_file" "$rules" "$dictionary" "log"; then
                log "成功（分割処理）: $filename"
                conversion_success=true
            else
                log "エラー（分割処理）: $filename"
                ((errors++))
            fi
            
            # 分割処理後は長めの休憩
            sleep 2
        else
            # 通常サイズファイルの処理
            echo "  ($processed/$total_files) $filename を変換中..."
            
            local content=$(cat "$input_file")

            # 各ファイルに対してGeminiで変換
            if gemini -p "以下の整合性リソースと入力テキストを使用して、文語形式のテキストを生成してください。

## 整合性ルール
$rules

## グローバル辞書
$dictionary

## 入力テキスト
\`\`\`
$content
\`\`\`

## 指示
1. 上記のルールと辞書を厳密に適用してください。
2. テキスト全体を、RAGでの検索に適した、高品質な文語体の文章に変換してください。
3. 元のテキストの意図や情報を保持してください。
4. 生成された文語体のテキストのみを出力してください。追加の説明や前置きは不要です。" > "$temp_output_file" 2>> "$LOG_FILE"; then
                log "成功: $filename"
                conversion_success=true
            else
                log "エラー: $filename の変換に失敗しました"
                ((errors++))
            fi
            
            # APIレート制限対策
            sleep 0.5
        fi

        # 変換が成功した場合、要約ファイル名にリネーム
        if [ "$conversion_success" = true ]; then
            if [ -s "$temp_output_file" ]; then # ファイルが空でないことを確認
                local new_filename_base
                new_filename_base=$(generate_filename_from_content "$temp_output_file")
                local final_output_file="output/${new_filename_base}.txt"

                # ファイル名の重複を避ける
                if [ -f "$final_output_file" ]; then
                    final_output_file="output/${new_filename_base}_$(date +%s).txt"
                fi

                mv "$temp_output_file" "$final_output_file"
                log "リネーム: $filename -> $(basename "$final_output_file")"
            else
                log "警告: 変換後のファイルが空のため、リネームをスキップ: $filename"
                rm "$temp_output_file" # 空の一時ファイルを削除
            fi
        else
            # 失敗した場合は一時ファイルを削除
            rm "$temp_output_file"
        fi
    done

    # クリーンアップ
    cleanup_temp_files

    local success=$((processed - errors))
    log "整合性考慮のバッチ変換完了 - 成功: $success, エラー: $errors, 分割処理: $split_processed"
    echo ""
    echo -e "${GREEN}変換完了${NC} - 成功: $success, エラー: $errors"
    if [ $split_processed -gt 0 ]; then
        echo -e "${BLUE}  分割処理: $split_processed ファイル${NC}"
    fi
}

# Phase 6: 整合性検証
verify_consistency() {
    echo -e "${BLUE}Phase 6: 整合性検証${NC}"
    
    gemini -p "outputディレクトリの全変換結果について、以下の整合性検証を実行してください：

1. 用語の一貫性チェック
   - グローバル辞書との照合
   - 同一クラスタ内での統一性

2. 文体の統一性チェック
   - クラスタごとの文体一貫性
   - 全体的な文体の調和

3. 参照整合性チェック
   - 文書間参照の妥当性
   - 時系列的な矛盾の検出

4. メタデータの完全性
   - 必須項目の確認
   - 値の妥当性検証

5. 分割処理ファイルの整合性
   - チャンク間の連続性
   - 分割による情報欠落の有無

検証結果をJSON形式で$WORK_DIR/consistency_report.jsonに出力してください。
問題のあるファイルはリストアップし、修正提案も含めてください。" > "$WORK_DIR/consistency_report.json" 2>> "$LOG_FILE"
    
    log "整合性検証完了"
}

# Phase 7: 自動修正
auto_correct_inconsistencies() {
    echo -e "${BLUE}Phase 7: 不整合の自動修正${NC}"
    
    local report=$(cat "$WORK_DIR/consistency_report.json" 2>/dev/null)
    
    # レポートが存在し、内容が空でないことを確認
    if [ -s "$WORK_DIR/consistency_report.json" ]; then
        echo "検証レポートに基づいて修正案を生成します..."
        gemini -p "整合性検証レポートに基づいて、レポートにリストされている各ファイルの問題点を修正した完全なテキストを生成してください。

## 検証レポート
$report

## 指示
1. レポートに記載されている問題点（用語の不統一、文体の不整合など）をすべて修正してください。
2. 各ファイルについて、修正後の完全なテキストのみを出力してください。
3. ファイルごとに、どのファイルに対する修正案であるか明確に示してください。
   例:
   --- START: path/to/file1.txt ---
   (修正後のテキスト)
   --- END: path/to/file1.txt ---

4. 分割処理されたファイルの場合は、全体の整合性を考慮して修正してください。
5. 修正ログを$WORK_DIR/corrections.logに記録してください。" > "$WORK_DIR/corrections.log" 2>> "$LOG_FILE"

        log "修正案の生成完了。詳細は $WORK_DIR/corrections.log を確認してください。"
        echo "修正案が $WORK_DIR/corrections.log に生成されました。手動での確認と適用を推奨します。"
    else
        log "自動修正はスキップされました（レポートが存在しないか空です）。"
        echo "整合性レポートが存在しないか、問題が検出されなかったため、自動修正はスキップされました。"
    fi
    
    log "自動修正完了"
}

# メイン処理
main() {
    echo -e "${GREEN}=== Gemini Corpus Builder 整合性管理（自動分割対応版） ===${NC}"
    echo "大規模ファイルの整合性を保証しながら変換を実行します"
    echo "大容量ファイルは自動的に分割処理されます"
    echo ""
    
    # 初期化
    init_consistency_system
    
    # 各フェーズを実行
    analyze_documents
    build_global_dictionary
    analyze_document_relations
    generate_consistency_rules
    convert_with_consistency
    verify_consistency
    auto_correct_inconsistencies
    
    # 最終レポート
    echo ""
    echo -e "${GREEN}=== 処理完了 ===${NC}"
    
    # 統計情報表示
    if [ -f "$WORK_DIR/consistency_report.json" ]; then
        echo "整合性レポートが生成されました: $WORK_DIR/consistency_report.json"
        
        # 簡易サマリー表示
        gemini -p "以下の整合性レポートから、重要な統計情報のサマリーを表示してください：
$(cat $WORK_DIR/consistency_report.json)

表示項目：
- 全体の整合性スコア
- 主な問題点
- 修正済み項目数
- 分割処理ファイルの統計
- 推奨事項" 2>/dev/null
    fi
    
    log "全処理完了"
}

# 引数処理
case "${1:-}" in
    "init")
        init_consistency_system
        ;;
    "analyze")
        analyze_documents
        ;;
    "dictionary")
        build_global_dictionary
        ;;
    "convert")
        convert_with_consistency
        ;;
    "verify")
        verify_consistency
        ;;
    "")
        main
        ;;
    *)
        echo "使用方法: $0 [init|analyze|dictionary|convert|verify]"
        echo "  引数なし: 全フェーズを実行"
        echo "  init: システムを初期化"
        echo "  analyze: 文書分析のみ実行"
        echo "  dictionary: 辞書構築のみ実行"
        echo "  convert: 変換のみ実行"
        echo "  verify: 検証のみ実行"
        exit 1
        ;;
esac
