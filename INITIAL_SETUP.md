# Gemini Corpus Builder - ディレクトリ構造

プロジェクトの初期ディレクトリ構造を作成するために、以下のコマンドを実行してください：

```bash
# ディレクトリ作成
mkdir -p gemini-corpus-builder/{input,output,logs,scripts,.gemini/templates,test/{input,output},.devcontainer,docs}

# .gitkeepファイルの作成（空ディレクトリをGitで管理するため）
touch gemini-corpus-builder/input/.gitkeep
touch gemini-corpus-builder/output/.gitkeep
touch gemini-corpus-builder/logs/.gitkeep
touch gemini-corpus-builder/test/input/.gitkeep
touch gemini-corpus-builder/test/output/.gitkeep
touch gemini-corpus-builder/.gemini/templates/.gitkeep

# スクリプトの作成と実行権限付与
cd gemini-corpus-builder
chmod +x scripts/*.sh
```

## 完全なプロジェクト構造

```
gemini-corpus-builder/
├── README.md                      # プロジェクト説明
├── PROJECT_SETUP.md              # セットアップガイド
├── Makefile                      # 便利コマンド集
├── package.json                  # Node.js設定
├── .gitignore                    # Git無視設定
│
├── .gemini/                      # Gemini CLI設定
│   ├── GEMINI.md                # 変換ルール定義
│   ├── settings.json.sample     # 設定サンプル
│   └── templates/               # テンプレート用
│       └── .gitkeep
│
├── .devcontainer/               # VS Code Dev Container
│   └── devcontainer.json       # Container設定
│
├── input/                       # 入力ファイル置き場
│   └── .gitkeep
│
├── output/                      # 出力ファイル置き場
│   └── .gitkeep
│
├── logs/                        # ログファイル
│   └── .gitkeep
│
├── scripts/                     # 処理スクリプト
│   ├── batch_convert.sh        # バッチ変換
│   ├── validate_output.sh      # 検証スクリプト
│   ├── convert_single.sh       # 単一ファイル変換
│   ├── show_stats.sh          # 統計表示
│   └── config.sh              # 共通設定
│
├── test/                        # テスト用
│   ├── input/                  # テスト入力
│   │   └── .gitkeep
│   └── output/                 # テスト出力
│       └── .gitkeep
│
└── docs/                        # ドキュメント
    └── TROUBLESHOOTING.md      # トラブルシューティング
```

## 追加で必要なスクリプト

### scripts/convert_single.sh
```bash
#!/bin/bash
# 単一ファイル変換スクリプト

if [ $# -ne 2 ]; then
    echo "使用方法: $0 <入力ファイル> <出力ファイル>"
    exit 1
fi

INPUT_FILE=$1
OUTPUT_FILE=$2

# ファイル内容を読み込み
CONTENT=$(cat "$INPUT_FILE")

# Geminiで変換
gemini -p "以下の口語テキストを文語形式に変換し、RAG用に最適化してください。
write-fileツールを使用して結果を「$OUTPUT_FILE」に自動保存してください。

入力テキスト:
$CONTENT"

echo "変換完了: $OUTPUT_FILE"
```

### scripts/show_stats.sh
```bash
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

# 処理時間統計
if [ -f logs/conversion_*.log ]; then
    echo ""
    echo "平均処理時間:"
    # ログから処理時間を抽出して計算
fi
```

### scripts/config.sh
```bash
#!/bin/bash
# 共通設定ファイル

# API設定
export BATCH_SIZE=50
export API_DELAY=0.5
export MAX_RETRIES=3

# ディレクトリ設定
export INPUT_DIR="input"
export OUTPUT_DIR="output"
export LOG_DIR="logs"

# 変換設定
export CONVERSION_MODE="standard"  # standard/strict/lenient
export INCLUDE_METADATA=true
export PRESERVE_STRUCTURE=true
```

これらのファイルを作成することで、口語から文語への大量テキスト変換を効率的に実行できる環境が整います。