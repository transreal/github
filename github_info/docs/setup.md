# GitHub パッケージ セットアップガイド

このドキュメントでは、`GitHubREST`` パッケージの初期設定手順について説明します。

## 前提条件

### 必要な依存パッケージ

GitHubパッケージは以下のパッケージに依存しています：

- **[NBAccess](https://github.com/transreal/NBAccess)**: API認証とキー管理を担当します
- **[claudecode](https://github.com/transreal/claudecode)**: Claude Code環境での動作に必要です。コミットメッセージのLLM自動生成 (`PackageLLMMessageGenerator`) を利用する場合にも使用されます

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

なお、`GithubRepositories/[packageName]/` は GitHub へのアップロード内容であると同時に、**前回コミット時のスナップショット**としても機能します。`PackageCommitDiff` / `PackageCommit` はこのスナップショットと現ソースを内容比較して差分を求めるため、リフレッシュ前に呼び出す必要があります。

## 次のステップ

セットアップが完了したら、以下の機能をお試しください：

1. **既存パッケージのリポジトリ作成**: `GitHubCreateRepository["packageName"]`
2. **プルリクエスト一覧の確認**: `GitHubPullRequestDataset["packageName"]`
3. **コミット履歴の確認**: `GitHubCommitDataset["packageName"]`
4. **配布前のマニフェスト検証**: `GitHubValidateManifest["packageName"]`
5. **ローカルファイルの UTF-8 読み取り**: `GitHubReadLocalFile["packageName", "path"]`
6. **差分ベースの自動コミット**: `PackageCommit["packageName"]`（既定は DryRun。計画とコミットメッセージ案のみを返します）

詳細な使用方法については、各機能のヘルプドキュメントをご参照ください。

## 補足: 配布前チェック

`GitHubValidateManifest[packageName]` を使用すると、コミット・配布前に以下の項目を検証できます：

- `upload_manifest.json` に列挙されたファイルの実在確認
- secret / token / credential など秘密情報が混入していないかのスキャン
- 除外パターン (`ExcludePatterns`) の確認

```mathematica
GitHubValidateManifest["myPackage"]
(* <|"Status" -> "OK", "FileCount" -> 3, "MissingFiles" -> {}, "Issues" -> {}, ...|> *)
```

## 補足: ドキュメント鮮度ゲートと自動コミット

`PackageCommit[packageName]` は、配布前の自動コミット駆動関数です。実行すると、以下の流れを経て安全にコミットを行います。

1. **ドキュメント鮮度ゲート** (`PackageDocsFreshnessGate`): `packageName_info/docs` 配下の `api.md` / `api_*.md` が対応する `.wl` ファイル以降に更新されているかを検査します。`.wl` を更新したのにドキュメントが古いままの場合は `Blocked` となり、実コミットを停止します。
2. **差分計算** (`PackageCommitDiff`): 前回コミットスナップショットと現ソースを内容比較し、追加・変更・削除ファイルを求めます。差分が無ければ `NoChange` となります。
3. **コミットメッセージ案の生成**: 差分から決定論的に単文メッセージを生成します。`claudecode` を併用する場合は `PackageLLMMessageGenerator` で LLM 生成に切り替えられます。

```mathematica
(* 既定は DryRun: 実コミットせず計画とメッセージ案のみ確認 *)
PackageCommit["myPackage"]

(* 実コミット (ドキュメントが古ければ Blocked で停止) *)
PackageCommit["myPackage", "DryRun" -> False]
```

ドキュメントが古く `Blocked` になった場合は、ドキュメントを更新してから再実行してください。メッセージ案だけを確認したい場合は `DryRun` のまま `"SkipDocsGate" -> True` を指定するとゲートを無視してプレビューできます（実コミットでは `SkipDocsGate` は無効で、必ず鮮度ゲートが適用されます）。

## 補足: 並列実行時の注意

複数のノートブックや Kernel から同時に `GitHubCommit` / `GitHubRefreshAndCommit` を実行すると、GitHub API 側で 422 (head SHA 競合) エラーが発生する場合があります。パッケージは自動的に head SHA を再取得してリトライしますが、競合が繰り返す場合は**並列実行を避けるか、時間をおいて再試行**してください。

## 補足: ローカルファイルの UTF-8 読み取り

`GitHubReadLocalFile[packageName, path]` は、`$CharacterEncoding` の設定に依存しない UTF-8 固定読み取りを行います。`GitHubReadFile` との内容比較や、日本語環境での文字化け回避に使用できます。`path` を省略すると、パッケージの `.wl` ファイルを読み取ります。

```mathematica
(* ローカルとリモートの内容を比較する例 *)
local  = GitHubReadLocalFile["myPackage", "myPackage.wl"];
remote = GitHubReadFile["myPackage", "myPackage.wl"];
local === remote