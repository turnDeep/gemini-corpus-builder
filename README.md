# 📚 Gemini Corpus Builder

**口語テキストを文語コーパスに変換する自動化ツール**

このリポジトリは、Gemini CLIを使用して大量の口語テキストファイルを文語形式に変換し、RAG（Retrieval-Augmented Generation）システムで使用可能な高品質なコーパスを構築するためのフレームワークです。

## ✨ 主な機能

- 📝 **大量ファイルの自動変換**: 1000個以上のテキストファイルを一括処理
- 🎯 **RAG最適化**: 検索・参照しやすい構造化された文語形式に変換
- 🤖 **完全自動化**: 人間の確認なしで全ファイルを処理
- 📊 **進捗管理**: バッチ処理の進捗状況をリアルタイムで確認
- 🔍 **品質チェック**: 変換結果の一貫性を自動検証

## 🚀 クイックスタート

### 1. リポジトリのクローン
```bash
git clone https://github.com/yourusername/gemini-corpus-builder.git
cd gemini-corpus-builder
```

### 2. Dev Containerで開く（推奨）
VS Codeでプロジェクトを開き、「Reopen in Container」を選択

### 3. 初期設定
```bash
# Gemini CLIの認証
gemini

# 設定ファイルのカスタマイズ
cp .gemini/settings.json.sample ~/.gemini/settings.json
```

### 4. 変換の実行
```bash
# 入力ファイルを配置
cp your-files/*.txt input/

# 変換実行
make convert

# または個別実行
./scripts/batch_convert.sh
```

## 📁 プロジェクト構造

```
gemini-corpus-builder/
├── 📁 input/              # 口語テキストファイル（入力）
├── 📁 output/             # 文語テキストファイル（出力）
├── 📁 .gemini/            # Gemini CLI設定
│   ├── 📜 GEMINI.md       # Gemini への指示書
│   └── 📜 settings.json   # Gemini CLI設定
├── 📁 scripts/            # 処理スクリプト
│   ├── 📜 batch_convert.sh    # バッチ変換スクリプト
│   ├── 📜 validate_output.sh  # 品質検証スクリプト
│   └── 📜 progress_monitor.sh # 進捗モニター
└── 📁 logs/               # 処理ログ
```

## 🔧 設定のカスタマイズ

### 変換ルールの調整

`.gemini/GEMINI.md`を編集して、変換ルールをプロジェクトに合わせてカスタマイズできます：

- 文語化のレベル（古典的/現代的）
- 専門用語の扱い
- 文体の統一基準
- メタデータの付与

### バッチ処理の設定

`scripts/config.sh`で処理パラメータを調整：

```bash
BATCH_SIZE=50        # 一度に処理するファイル数
PARALLEL_JOBS=4      # 並列実行数
RETRY_ATTEMPTS=3     # エラー時のリトライ回数
```

## 📊 変換例

### 入力（口語）
```
まあ、そんな感じで、昨日は友達と一緒に新しくできたカフェに行ってきたんだけど、
すごく雰囲気が良くて、コーヒーも美味しかったよ。
```

### 出力（文語・RAG最適化）
```
昨日、友人と共に新規開店した喫茶店を訪問した。
店内の雰囲気は非常に良好であり、提供されたコーヒーの品質も優れていた。

[メタデータ]
- トピック: 飲食店訪問
- キーワード: カフェ, コーヒー, 友人, 新規開店
- 感情: ポジティブ
```

## 🛠️ トラブルシューティング

### よくある問題

1. **変換が進まない**
   - `logs/conversion.log`でエラーを確認
   - Gemini APIのレート制限を確認

2. **品質が安定しない**
   - `.gemini/GEMINI.md`の指示を具体化
   - サンプル変換で事前検証

3. **メモリ不足**
   - バッチサイズを小さく調整
   - 並列実行数を減らす

## 📝 ライセンス

MIT License

---

**このツールにより、大規模な口語テキストコーパスを効率的に文語形式に変換し、高品質なRAGシステムの構築が可能になります。**