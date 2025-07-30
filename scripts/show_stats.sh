#!/bin/bash
# 詳細統計表示スクリプト

echo "=== 変換統計詳細 ==="
echo ""

# ファイルサイズ統計
echo "ファイルサイズ分布:"
find output -name "*.txt" -exec wc -c {} \; | awk '{sum+=$1; files++} END {print "平均: " int(sum/files) " bytes"}'

# メタデータ統計
echo ""
echo "メタデータ付与率:"
grep -l "\[文書情報\]" output/*.txt 2>/dev/null | wc -l | awk -v total=$(find output -name "*.txt" | wc -l) '{print ($1/total)*100 "%"}'

# 整合性統計
if [ -f consistency_work/consistency_report.json ]; then
    echo ""
    echo "整合性スコア:"
    cat consistency_work/consistency_report.json | grep -o '"overall_score":[0-9.]*' | cut -d: -f2
fi

# 処理時間統計
if [ -f logs/conversion_*.log ]; then
    echo ""
    echo "平均処理時間:"
    # ログから処理時間を抽出して計算
fi
