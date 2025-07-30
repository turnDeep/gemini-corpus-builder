#!/bin/bash

# Gemini Corpus Builder - 整合性管理スクリプト

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

# 初期化
init_consistency_system() {
    echo -e "${BLUE}=== 整合性管理システム初期化 ===${NC}"
    mkdir -p "$WORK_DIR"
    
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
    
    # Geminiで文書分析を実行
    gemini -p "以下のタスクを実行してください：
1. inputディレクトリ内の全テキストファイルを分析
2. 内容の類似性に基づいてクラスタリング
3. 各クラスタの特徴を抽出
4. 結果を$CLUSTER_FILEに保存

分析観点：
- トピックの類似性
- 文体の特徴
- 使用語彙の傾向
- 時系列的な関連性

write-fileツールを使用して自動的に結果を保存してください。" >> "$LOG_FILE" 2>&1
    
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

5. 更新された辞書を$DICT_FILEに保存

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

write-fileツールで自動保存してください。" >> "$LOG_FILE" 2>&1
    
    log "グローバル辞書構築完了"
}

# Phase 3: 文書間関係の分析
analyze_document_relations() {
    echo -e "${BLUE}Phase 3: 文書間関係の分析${NC}"
    
    gemini -p "以下のタスクを実行してください：
1. 全文書間の参照関係を分析
2. 時系列的な依存関係を特定
3. トピックの継続性を確認
4. ドキュメントグラフを構築して$GRAPH_FILEに保存

グラフ形式：
{
  \"nodes\": [
    {\"id\": \"doc1.txt\", \"cluster\": 0, \"topics\": [...]},
    ...
  ],
  \"edges\": [
    {\"source\": \"doc1.txt\", \"target\": \"doc2.txt\", \"type\": \"reference\", \"weight\": 0.8},
    ...
  ]
}

write-fileツールで自動保存してください。" >> "$LOG_FILE" 2>&1
    
    log "文書間関係分析完了"
}

# Phase 4: 整合性チェックルールの生成
generate_consistency_rules() {
    echo -e "${BLUE}Phase 4: 整合性チェックルール生成${NC}"
    
    # 分析結果を統合
    clusters=$(cat "$CLUSTER_FILE" 2>/dev/null)
    dictionary=$(cat "$DICT_FILE" 2>/dev/null)
    graph=$(cat "$GRAPH_FILE" 2>/dev/null)
    
    gemini -p "以下の分析結果を基に、整合性チェックルールを生成してください：

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

結果を$WORK_DIR/consistency_rules.jsonに保存してください。
write-fileツールで自動保存してください。" >> "$LOG_FILE" 2>&1
    
    log "整合性チェックルール生成完了"
}

# Phase 5: バッチ変換（整合性考慮）
convert_with_consistency() {
    echo -e "${BLUE}Phase 5: 整合性を考慮したバッチ変換${NC}"
    
    # ルールとリソースを読み込み
    rules=$(cat "$WORK_DIR/consistency_rules.json" 2>/dev/null)
    dictionary=$(cat "$DICT_FILE" 2>/dev/null)
    
    # クラスタごとに処理
    echo "クラスタベースの変換を開始..."
    
    gemini -p "以下の整合性リソースを使用して、inputディレクトリの全ファイルを変換してください：

整合性ルール：
$rules

グローバル辞書：
$dictionary

変換要件：
1. クラスタごとに適切な変換ルールを適用
2. グローバル辞書を使用して用語を統一
3. 文書間の参照関係を維持
4. 各ファイルにメタデータを付与（クラスタID、関連文書など）
5. outputディレクトリに自動保存

処理状況をログに記録しながら、write-fileツールで各ファイルを自動的に保存してください。" >> "$LOG_FILE" 2>&1
    
    log "整合性考慮のバッチ変換完了"
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

検証結果を$WORK_DIR/consistency_report.jsonに保存してください。
問題のあるファイルはリストアップし、修正提案も含めてください。" >> "$LOG_FILE" 2>&1
    
    log "整合性検証完了"
}

# Phase 7: 自動修正
auto_correct_inconsistencies() {
    echo -e "${BLUE}Phase 7: 不整合の自動修正${NC}"
    
    report=$(cat "$WORK_DIR/consistency_report.json" 2>/dev/null)
    
    if [ -n "$report" ]; then
        gemini -p "整合性検証レポートに基づいて、以下の自動修正を実行してください：

検証レポート：
$report

修正内容：
1. 用語の不統一を修正
2. 文体の不整合を調整
3. 参照エラーを解決
4. メタデータの補完

修正したファイルはoutputディレクトリに上書き保存してください。
修正ログを$WORK_DIR/corrections.logに記録してください。" >> "$LOG_FILE" 2>&1
    fi
    
    log "自動修正完了"
}

# メイン処理
main() {
    echo -e "${GREEN}=== Gemini Corpus Builder 整合性管理 ===${NC}"
    echo "大規模ファイルの整合性を保証しながら変換を実行します"
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
