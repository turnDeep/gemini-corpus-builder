# Gemini Corpus Builder セットアップガイド

このプロジェクトは、Gemini CLIを使用して口語テキストを文語形式に変換し、RAG用の高品質なコーパスを構築するツールです。

## 必要な環境

- Node.js 18以上
- npm または yarn
- Docker (Dev Container使用時)
- VS Code (推奨)

## セットアップ手順

### 1. Gemini CLIのインストール

```bash
# グローバルインストール
npm install -g @google/gemini-cli

# バージョン確認
gemini --version
```

### 2. 初回認証

```bash
# Gemini CLIの認証
gemini

# Googleアカウントでログイン
# 無料枠: 60リクエスト/分、1000リクエスト/日
```

### 3. プロジェクトのセットアップ

```bash
# リポジトリをクローン
git clone https://github.com/yourusername/gemini-corpus-builder.git
cd gemini-corpus-builder

# 初期セットアップ
make setup
```

### 4. 設定ファイルの準備

```bash
# Gemini設定ファイルをコピー
cp .gemini/settings.json.sample ~/.gemini/settings.json

# 必要に応じて編集
nano ~/.gemini/settings.json
```

### 5. APIキーの設定（高頻度利用時）

無料枠を超える場合は、Google AI StudioでAPIキーを取得：

```bash
# 環境変数として設定
echo "export GEMINI_API_KEY=your-api-key-here" >> ~/.bashrc
source ~/.bashrc

# または .env ファイルに記載
echo "GEMINI_API_KEY=your-api-key-here" > .env
```

## 使用方法

### 1. 入力ファイルの準備

```bash
# 口語テキストファイルをinputディレクトリに配置
cp /path/to/your/files/*.txt input/
```

### 2. 変換の実行

```bash
# 全ファイルを一括変換
make convert

# または個別に実行
./scripts/batch_convert.sh
```

### 3. 結果の確認

```bash
# 変換統計を表示
make stats

# 出力ファイルを確認
ls -la output/

# 変換結果の検証
make validate
```

## ディレクトリ構造

```
gemini-corpus-builder/
├── input/          # 口語テキストファイル（入力）
├── output/         # 文語テキストファイル（出力）
├── logs/           # 処理ログ
├── scripts/        # 処理スクリプト
├── .gemini/        # Gemini設定
│   ├── GEMINI.md   # 変換ルール定義
│   └── templates/  # テンプレート
└── test/           # テスト用ファイル
```

## カスタマイズ

### 変換ルールの調整

`.gemini/GEMINI.md`を編集して変換ルールをカスタマイズ：

- 文語化のレベル
- メタデータの形式
- 特殊な処理ルール

### バッチ処理の最適化

`scripts/config.sh`で処理パラメータを調整：

```bash
# バッチサイズ（一度に処理するファイル数）
BATCH_SIZE=50

# API呼び出し間隔（秒）
API_DELAY=0.5

# リトライ設定
MAX_RETRIES=3
```

## トラブルシューティング

### Gemini CLIが見つからない

```bash
# npmのグローバルパスを確認
npm config get prefix

# パスを追加
export PATH=$PATH:$(npm config get prefix)/bin
```

### レート制限エラー

- APIキーを設定して制限を緩和
- バッチサイズを小さくする
- API呼び出し間隔を増やす

### 変換品質が不安定

- `.gemini/GEMINI.md`の指示を具体化
- サンプル変換で事前テスト
- ログを確認して問題箇所を特定

### メモリ不足

```bash
# Node.jsのメモリ上限を増やす
export NODE_OPTIONS="--max-old-space-size=4096"
```

## 高度な使用方法

### 並列処理（実験的）

```bash
# 並列処理スクリプトを使用
./scripts/parallel_convert.sh -j 4
```

### カスタムフィルター

```bash
# 特定のパターンのファイルのみ処理
find input -name "*interview*.txt" | ./scripts/convert_from_list.sh
```

### 差分変換

```bash
# 未変換のファイルのみ処理
./scripts/incremental_convert.sh
```

## パフォーマンスチューニング

### 推奨設定

- **小規模（〜100ファイル）**: デフォルト設定で問題なし
- **中規模（100〜1000ファイル）**: バッチサイズ50、API遅延0.5秒
- **大規模（1000ファイル以上）**: APIキー必須、並列処理推奨

### モニタリング

```bash
# リアルタイム進捗確認
tail -f logs/conversion_*.log

# 処理速度の確認
./scripts/show_performance.sh
```

## サポート

問題が発生した場合：

1. まず`logs/`ディレクトリのログを確認
2. [トラブルシューティングガイド](docs/TROUBLESHOOTING.md)を参照
3. それでも解決しない場合はIssueを作成

---

**準備が整ったら、`make convert`で変換を開始してください！**
