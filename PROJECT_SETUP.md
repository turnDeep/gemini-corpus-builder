# Gemini Corpus Builder セットアップガイド

このプロジェクトは、Gemini CLIを使用して口語テキストを文語形式に変換し、RAG用の高品質なコーパスを構築するツールです。

## 必要な環境

- Node.js 18以上
- npm または yarn
- Docker (Dev Container使用時)
- VS Code (推奨)
- **ブラウザ** (認証に必要)

## セットアップ手順

### 1. Gemini CLIのインストール

```bash
# グローバルインストール
npm install -g @google/gemini-cli

# バージョン確認
gemini --version
```

### 2. 初回認証

#### 方法1: ブラウザ認証（推奨）

```bash
# 認証セットアップスクリプトを実行
chmod +x scripts/setup_auth.sh
./scripts/setup_auth.sh

# または直接実行
gemini auth login
```

**認証の流れ：**
1. コマンド実行後、ブラウザが自動的に開きます
2. Googleアカウントでログイン
3. 権限を承認
4. "認証が完了しました"のメッセージを確認

**トラブルシューティング：**

**ブラウザが開かない場合：**
- 表示されたURLを手動でブラウザにコピー＆ペースト
- WSL2の場合: Windows側のブラウザでURLを開く

**タイムアウトエラーの場合：**
```bash
# タイムアウトを延長
export GEMINI_AUTH_TIMEOUT=600  # 10分に設定
gemini auth login
```

**SSH接続の場合：**
```bash
# X11転送を有効にしてSSH接続
ssh -X username@hostname

# または、ローカルで認証してファイルをコピー
# ローカルマシンで:
gemini auth login
scp ~/.gemini/credentials.json username@hostname:~/.gemini/
```

#### 方法2: APIキー認証（ブラウザが使えない場合）

```bash
# Google AI StudioでAPIキーを取得
# https://aistudio.google.com/app/apikey

# 環境変数として設定
echo "export GEMINI_API_KEY=your-api-key-here" >> ~/.bashrc
source ~/.bashrc

# または .env ファイルに記載
echo "GEMINI_API_KEY=your-api-key-here" > .env
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

### 5. 認証の確認

```bash
# 認証状態の確認
gemini auth status

# テスト実行
echo "テスト" | gemini -p "これは何ですか？"
```

## Dev Container での認証

Dev Container環境では、以下の方法で認証を行います：

### 方法1: ホストマシンの認証情報を共有

`.devcontainer/devcontainer.json` に以下を追加：

```json
{
  "mounts": [
    "source=${localEnv:HOME}/.gemini,target=/home/node/.gemini,type=bind"
  ]
}
```

### 方法2: 環境変数でAPIキーを渡す

```json
{
  "remoteEnv": {
    "GEMINI_API_KEY": "${localEnv:GEMINI_API_KEY}"
  }
}
```

### 方法3: コンテナ内で認証

```bash
# コンテナ内のターミナルで
./scripts/setup_auth.sh
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

# 整合性保証付き変換（大規模処理向け）
make consistency

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

## 認証に関するFAQ

### Q: 「Sign in」で止まってタイムアウトする

A: 以下を確認してください：
1. ブラウザが利用可能な環境か
2. ポップアップブロッカーが無効か
3. ネットワーク接続が安定しているか

### Q: WSL2で認証できない

A: Windows側のブラウザを使用：
```bash
# WSL2内で
gemini auth login
# 表示されたURLをWindows側のブラウザで開く
```

### Q: リモートサーバーで認証したい

A: 以下のいずれかの方法：
1. ローカルで認証してcredentials.jsonをコピー
2. APIキーを使用
3. SSH X11転送を使用（ssh -X）

### Q: 認証情報はどこに保存される？

A: `~/.gemini/credentials.json` に保存されます。
このファイルは安全に管理してください。

## トラブルシューティング

詳細なトラブルシューティングについては、[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) を参照してください。

---

**準備が整ったら、`make convert`で変換を開始してください！**