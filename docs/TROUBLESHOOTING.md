# Gemini Corpus Builder トラブルシューティングガイド

## 認証関連の問題

### 問題: 「Sign in」で止まってタイムアウトする

**症状:**
- `gemini auth login` 実行後、"Sign in"メッセージで止まる
- 数分後にタイムアウトエラーが発生
- ブラウザが開かない

**原因:**
- 環境変数 `NO_BROWSER=true` が設定されている
- ブラウザが利用できない環境
- ファイアウォールやプロキシの問題

**解決方法:**

#### 1. 環境変数の確認と削除
```bash
# 環境変数を確認
env | grep NO_BROWSER

# 設定されている場合は削除
unset NO_BROWSER

# .bashrcなどから永続的に削除
nano ~/.bashrc
# NO_BROWSER=true の行を削除またはコメントアウト
```

#### 2. 認証スクリプトを使用
```bash
# 認証セットアップスクリプトを実行
chmod +x scripts/setup_auth.sh
./scripts/setup_auth.sh
```

#### 3. 手動でURLを開く
```bash
# geminiコマンド実行
gemini auth login

# 表示されるURLをコピーしてブラウザで開く
# 例: https://accounts.google.com/o/oauth2/auth?client_id=...
```

#### 4. タイムアウトを延長
```bash
# タイムアウトを10分に設定
export GEMINI_AUTH_TIMEOUT=600
gemini auth login
```

### 問題: WSL2でブラウザが開かない

**解決方法:**

#### 方法1: Windows側のブラウザを使用
```bash
# WSL2でデフォルトブラウザを設定
export BROWSER="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"

# または
export BROWSER="cmd.exe /c start"

# 認証実行
gemini auth login
```

#### 方法2: 手動でURLを開く
1. WSL2ターミナルで `gemini auth login` を実行
2. 表示されたURLをコピー
3. Windows側のブラウザでURLを開く
4. 認証完了後、WSL2側で自動的に検出される

### 問題: SSH接続でブラウザが使えない

**解決方法:**

#### 方法1: ローカルで認証してファイルをコピー
```bash
# ローカルマシンで
gemini auth login
ls ~/.gemini/credentials.json

# リモートサーバーにコピー
scp ~/.gemini/credentials.json user@server:~/.gemini/
```

#### 方法2: X11転送を使用
```bash
# SSH接続時にX11転送を有効化
ssh -X user@server

# または
ssh -Y user@server

# サーバー側で認証
gemini auth login
```

#### 方法3: APIキーを使用
```bash
# Google AI StudioでAPIキーを取得
# https://aistudio.google.com/app/apikey

# 環境変数として設定
export GEMINI_API_KEY="your-api-key-here"
```

### 問題: Dev Containerで認証できない

**解決方法:**

#### 方法1: ホストの認証情報を共有
1. ホストマシンで先に認証を完了
2. `.devcontainer/devcontainer.json` の mounts セクションを確認
3. コンテナを再起動

#### 方法2: コンテナ内で認証
```bash
# コンテナ内のターミナルで
export BROWSER="echo 'Please open this URL in your browser:'"
gemini auth login
# 表示されたURLをホスト側のブラウザで開く
```

### 問題: 認証は成功したが、APIエラーが発生する

**症状:**
- 認証は完了したが、実際の変換時にエラー
- "403 Forbidden" や "401 Unauthorized" エラー

**解決方法:**

#### 1. 認証情報の確認
```bash
# 認証状態を確認
gemini auth status

# 認証ファイルの存在確認
ls -la ~/.gemini/credentials.json

# 権限の確認
chmod 600 ~/.gemini/credentials.json
```

#### 2. 再認証
```bash
# 既存の認証情報を削除
rm ~/.gemini/credentials.json

# 再認証
./scripts/setup_auth.sh
```

#### 3. API制限の確認
- 無料枠: 60リクエスト/分、1000リクエスト/日
- 制限に達している場合は時間を置くかAPIキーを使用

## 変換処理の問題

### 問題: 大容量ファイルの処理が失敗する

**解決方法:**
```bash
# チャンクサイズを調整
export CHUNK_SIZE=20000  # より小さく設定

# タイムアウトを延長
export LARGE_FILE_TIMEOUT=600
```

### 問題: メモリ不足エラー

**解決方法:**
```bash
# Node.jsのメモリ上限を増やす
export NODE_OPTIONS="--max-old-space-size=8192"

# バッチサイズを減らす
export BATCH_SIZE=20
```

## その他の問題

### ログファイルの確認方法

```bash
# 最新のログを確認
tail -f logs/conversion_*.log

# エラーのみ抽出
grep "ERROR" logs/*.log

# 特定のファイルに関するログ
grep "filename.txt" logs/*.log
```

### デバッグモードの有効化

```bash
# デバッグログを有効化
export LOG_LEVEL=debug

# 実行
make convert
```

### 問題が解決しない場合

1. `logs/` ディレクトリのログファイルを確認
2. Gemini CLIのバージョンを最新に更新
   ```bash
   npm update -g @google/gemini-cli
   ```
3. プロジェクトのIssueに報告（ログを添付）

---

**注意:** 認証情報（credentials.json、APIキー）は機密情報です。Gitにコミットしたり、公開したりしないよう注意してください。