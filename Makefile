.PHONY: setup convert validate clean stats help

# デフォルトタスク
default: help

# ヘルプ
help:
	@echo "Gemini Corpus Builder コマンド:"
	@echo "  make setup      - 初期セットアップ"
	@echo "  make convert    - 口語→文語変換の実行"
	@echo "  make validate   - 変換結果の検証"
	@echo "  make stats      - 変換統計の表示"
	@echo "  make clean      - 出力ファイルのクリア"
	@echo "  make test       - テスト変換の実行"

# セットアップ
setup:
	@echo "環境をセットアップしています..."
	mkdir -p input output logs .gemini/templates
	chmod +x scripts/*.sh
	@echo "Gemini CLIがインストールされていることを確認してください："
	@echo "  npm install -g @google/gemini-cli"
	@echo ""
	@echo "初期設定："
	@echo "  1. gemini コマンドで認証"
	@echo "  2. cp .gemini/settings.json.sample ~/.gemini/settings.json"
	@echo "  3. inputディレクトリに変換したいテキストファイルを配置"

# 変換実行
convert:
	@echo "口語→文語変換を開始します..."
	@./scripts/batch_convert.sh

# 検証
validate:
	@echo "変換結果を検証しています..."
	@./scripts/validate_output.sh

# 統計表示
stats:
	@echo "変換統計："
	@echo "入力ファイル数: $$(find input -name "*.txt" | wc -l)"
	@echo "出力ファイル数: $$(find output -name "*.txt" | wc -l)"
	@echo "エラー数: $$(grep -c "ERROR" logs/conversion.log 2>/dev/null || echo 0)"
	@echo ""
	@./scripts/show_stats.sh

# クリーンアップ
clean:
	@echo "出力ファイルをクリアしますか？ [y/N]"
	@read ans && [ $${ans:-N} = y ] && rm -rf output/* logs/* || echo "キャンセルしました"

# テスト実行
test:
	@echo "テスト変換を実行します..."
	@mkdir -p test/input test/output
	@echo "これはテストです。まあ、そんな感じかな。" > test/input/test1.txt
	@echo "昨日さ、友達と会ったんだけど、すごく楽しかったよ。" > test/input/test2.txt
	@./scripts/convert_single.sh test/input/test1.txt test/output/test1.txt
	@echo ""
	@echo "変換結果："
	@echo "--- 入力 ---"
	@cat test/input/test1.txt
	@echo "--- 出力 ---"
	@cat test/output/test1.txt