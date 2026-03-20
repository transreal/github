# GitHub パッケージ セットアップガイド

このドキュメントでは、GitHubREST` パッケージの初期設定手順について説明します。

## 前提条件

### 必要な依存パッケージ

GitHubパッケージは以下のパッケージに依存しています：

- **[NBAccess](https://github.com/transreal/NBAccess)**: API認証とキー管理を担当します
- **[claudecode](https://github.com/transreal/claudecode)**: Claude Code環境での動作に必要です

これらのパッケージが`$packageDirectory`にインストールされていることを確認してください。

### GitHub API トークンの準備

GitHubの操作にはPersonal Access Tokenが必要です：

1. GitHub → Settings → Developer settings → Personal access tokens
2. "Generate new token (classic)"を選択
3. 以下のスコープを有効にしてください：
   - `repo` (リポジトリへのフルアクセス)
   - `workflow` (GitHub Actionsワークフロー管理)
   - `user` (ユーザー情報の読み取り)

## 初期設定手順

### 1. パッケージの読み込み

```mathematica
Needs["GitHubREST`", "github.wl"]
```

### 2. GitHub APIキーの登録

NBAccessを使用してGitHub APIトークンを登録します：

```mathematica
NBSetAPIKey["github", "your-personal-access-token-here"]
```

登録されたキーは暗号化されて`~/.claude/api_keys.json`に保存されます。

### 3. ライセンスホルダーの設定（オプション）

MIT ライセンスを使用する場合は、著作権者名を設定してください：

```mathematica
$GitHubLicenseHolder = "Your Name"
```

空文字列`""`を設定すると、ライセンスセクションは README.md に挿入されません。

### 4. 動作確認

設定が正しく行われたかを確認します：

```mathematica
(* 認証状況の確認 *)
NBGetAPIKey["github"]

(* パッケージ一覧の取得 *)
GitHubPackageURLs[]
```

## ディレクトリ構造

GitHubパッケージは以下のディレクトリ構造を使用します：

```
$packageDirectory/
├── GithubRepositories/          (* ローカル作業フォルダ *)
│   ├── repo_database.json      (* パッケージ名→リポジトリ名マッピング *)
│   └── [packageName]/          (* 各パッケージのローカルコピー *)
├── [packageName]_info/          (* パッケージメタデータ *)
│   ├── upload_manifest.json    (* アップロード対象ファイル設定 *)
│   └── docs/                   (* ドキュメントフォルダ *)
└── [packageName].wl             (* パッケージファイル *)
```

これらのディレクトリは必要に応じて自動作成されます。

## 次のステップ

セットアップが完了したら、以下の機能をお試しください：

1. **既存パッケージのリポジトリ作成**: `GitHubCreateRepository["packageName"]`
2. **プルリクエスト一覧の確認**: `GitHubPullRequestDataset["packageName"]`
3. **コミット履歴の確認**: `GitHubCommitDataset["packageName"]`

詳細な使用方法については、各機能のヘルプドキュメントをご参照ください。