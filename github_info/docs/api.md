# GitHubREST` API リファレンス

GitHub REST API の Wolfram Language ラッパー。認証は `NBAccess\`NBGetAPIKey["github"]` に委譲する。

## 読み込み

```wolfram
Needs["GitHubREST`", "github_fixed.wl"]
```

## パッケージ URL・DB

### GitHubPackageURL[packageName, opts]
$packageDirectory 内のパッケージの GitHub URL を返す
→ String | $Failed
Options: Owner -> Automatic (ユーザー名/組織名、Automatic なら API トークンから取得), Repository -> Automatic (Automatic なら packageName を使用), Fallback -> False

### GitHubPackageURLs[] → Association
$packageDirectory 内の全パッケージの `<|name -> url, ...|>` を返す。

### GitHubRepoDB[] → Association
GithubRepositories/repo_database.json を読み込み全レコードを返す。

### GitHubRepoDBSet[packageName, repoName]
パッケージ名とリポジトリ名の対応を DB に登録する。日本語パッケージ名に英語リポジトリ名を対応付けるために使う。
→ String (保存パス)

### GitHubRepoDBSet[packageName, repoName, owner] → String
owner も含めて DB に登録する。

### GitHubRepoDBLookup[packageName] → String
DB からリポジトリ名を解決する。未登録なら packageName をそのまま返す。

## ローカルリポジトリ管理

### GitHubRepoPath[packageName] → String
ローカル作業フォルダ `FileNameJoin[{$packageDirectory, "GithubRepositories", packageName}]` を返す。

### GitHubEnsureLocalRepo[packageName, opts]
ローカル作業フォルダを作成して返す
→ String (ディレクトリパス)
Options: LocalRepoPath -> Automatic

### GitHubReadManifest[packageName] → Association
packageName_info/upload_manifest.json を読み込む。存在しない場合は自動生成してディスクに保存する。パッケージ種別 (.wl/パクレット) が変わった場合も自動更新する。

### GitHubRefreshLocalPackageGroup[packageName, opts]
upload_manifest.json に基づき対象ファイル・ディレクトリをローカル作業フォルダへコピーする。_info/docs/README.md が存在すればトップレベル README.md として配置する。
→ Association
Options: LocalRepoPath -> Automatic

### GitHubRefreshLocalPackage[packageName, opts]
$packageDirectory/packageName.wl をローカル作業フォルダへコピーする (後方互換・単一ファイル用)。グループアップロードには GitHubRefreshLocalPackageGroup を使う。
→ String | Failure
Options: LocalRepoPath -> Automatic, PackageFile -> Automatic

## リポジトリ操作

### GitHubCreateRepository[packageName, opts]
GitHub 上に新規リポジトリを作成する。upload_manifest.json が存在すれば対象ファイル群をまとめてコミットする。_info/docs/README.md があればトップレベル README.md として配置する。API から参照可能になるまで待機し結果を返す。
→ Association | Failure
Options: Repository -> Automatic, Public -> False, Description -> "", Homepage -> None, AutoInit -> True, GitignoreTemplate -> None, LicenseTemplate -> None, LocalRepoPath -> Automatic, IncludePackageFile -> True, PackageFile -> Automatic, ExtraDirectories -> {} (manifest の directories に永続追加するディレクトリリスト), Fallback -> False

### GitHubPull[packageName, opts]
指定ブランチのリポジトリ内容をローカル作業フォルダへ取得する。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, Clean -> False

### GitHubCommit[packageName, message, opts]
ローカル作業フォルダの内容を GitHub の指定ブランチへコミットする。複数ファイルを blob/tree/commit/ref 更新の流れでまとめて反映する。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic (Automatic でリポジトリの default branch を自動使用), CreateBranch -> Automatic (Branch != BaseBranch なら True), LocalRepoPath -> Automatic, IncludePackageFile -> True, PackageFile -> Automatic, DeleteMissing -> False, Force -> False, Author -> Automatic, Committer -> Automatic

### GitHubRefreshAndCommit[packageName, message, opts]
upload_manifest.json に基づき対象ファイル群をローカルへコピーし GitHub へコミットする。_info/docs/README.md が変更されていればトップレベル README.md も自動更新する。
→ Association | Failure

### GitHubReadFile[packageName, path, opts]
GitHub 上のファイルを読み取る。
→ String | ByteArray | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, ReturnType -> "Text" ("Text" | "ByteArray" | "Bytes"), Fallback -> False

### GitHubReadLocalFile[packageName, path] → String
ローカルファイルを常に UTF-8 でデコードして読み取る。path 省略時はパッケージの .wl ファイルを読む。$CharacterEncoding に依存しないため日本語環境でも文字化けしない。

## インストール・更新

### GitHubInstallPackage[packageName, opts]
GitHub から $packageDirectory にパッケージを初回ダウンロードする。インストール後は packageName だけでリモートリポジトリに対して操作できる。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, Fallback -> False

### GitHubInstallPackage[packageName, url, opts]
他人のリポジトリ URL を指定してインストールする。
→ Association | Failure
例: GitHubInstallPackage["pkg", "https://github.com/user/repo"]

### GitHubUpdatePackage[packageName] → Association | Failure
既存パッケージを GitHub の最新に更新する。

## プルリクエスト管理

### GitHubCreatePullRequest[packageName, title, opts]
pull request を作成する。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, BaseBranch -> Automatic, Branch -> Automatic, Head -> Automatic (Automatic なら Branch を使用), Body -> "", Draft -> False, MaintainerCanModify -> True

### GitHubSubmitPullRequest[packageName, title, message, opts]
refresh → branch 作成 → commit → pull request 作成を一括実行する。
→ Association | Failure

### GitHubListPullRequests[packageName, opts]
オープンな PR 一覧を緊急度・依存関係でソートして返す。
→ List | Failure
Options: Owner -> Automatic, Repository -> Automatic, Fallback -> False

### GitHubPullRequestDataset[packageName, opts]
PR 一覧を Review/Pull/Merge/Close ボタン付き Grid で返す。ノートブック上でインタラクティブに操作できる。
→ Grid | Failure
Options: Owner -> Automatic, Repository -> Automatic, Fallback -> False

### GitHubMergePullRequest[packageName, prNumber, reason] → Association | Failure
PR をマージする。

### GitHubClosePullRequest[packageName, prNumber, reason] → Association | Failure
PR をクローズする。

### GitHubReviewPullRequest[packageName, prNumber] → Null
PR のコードをダウンロードし、レビュー用コードをノートブックに出力する。

## コミット履歴

### GitHubListCommits[packageName, opts]
リポジトリのコミット履歴を取得してリストで返す。
→ List | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, MaxItems -> 30, Fallback -> False

### GitHubCommitDataset[packageName, opts]
コミット履歴を Review/Pull/Revert ボタン付き Grid で表示する。起動時に現在の作業状態を `GithubRepositories/_local_snapshot/` にスナップショット保存する。#0 行 (local) で復元可能。
→ Grid | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, MaxItems -> 30, Fallback -> False

### GitHubReviewCommit[packageName, sha] → Null
指定コミットの詳細・差分をノートブックに表示する。

### GitHubRevertCommit[packageName, sha] → Association | Failure
指定コミットの変更を元に戻すリバートコミットを作成する。

## オプション一覧

### Owner -> Automatic
GitHub の所有者 (ユーザー名/組織名)。Automatic なら認証トークンの所有ユーザーを使用。

### Repository -> Automatic
GitHub のリポジトリ名。Automatic なら packageName を使用。

### Public -> False
新規作成するリポジトリを公開にするか。

### Description -> ""
新規リポジトリ作成時の description。

### Homepage -> None
新規リポジトリ作成時の homepage URL。

### AutoInit -> True
新規リポジトリ作成時に README 付きで初期化するか。

### GitignoreTemplate -> None
GitHub の gitignore template 名。

### LicenseTemplate -> None
GitHub の license template 名。

### Branch -> Automatic
操作対象ブランチ。Automatic なら BaseBranch を使用。

### BaseBranch -> Automatic
既定ブランチまたは PR の base branch。Automatic でリポジトリの default branch を API から自動取得。

### CreateBranch -> Automatic
GitHubCommit 時に対象ブランチが存在しなければ BaseBranch から新規作成するか。Automatic なら Branch != BaseBranch のとき True。

### LocalRepoPath -> Automatic
ローカル作業フォルダを明示指定。

### PackageFile -> Automatic
元の packageName.wl のパスを明示指定。

### IncludePackageFile -> True
GitHubCommit/GitHubCreateRepository の前に packageName.wl をローカルへコピーするか。

### ReturnType -> "Text"
GitHubReadFile の戻り値型。"Text" | "ByteArray" | "Bytes"。

### Clean -> False
GitHubPull 時に既存のローカルファイルを先に削除するか。

### Force -> False
ref 更新時に fast-forward 制約を無視するか。

### DeleteMissing -> False
GitHubCommit 時にローカルに存在しないリモート blob を削除対象として tree に含めるか。

### Head -> Automatic
pull request の head ブランチ。Automatic なら Branch を使用。

### Body -> ""
pull request 本文。

### Draft -> False
pull request を draft として作成するか。

### MaintainerCanModify -> True
pull request で maintainers に head branch の編集を許可するか。

### Author -> Automatic
commit author。`<|"name" -> ..., "email" -> ...|>` の形で指定。

### Committer -> Automatic
commit committer。`<|"name" -> ..., "email" -> ...|>` の形で指定。

### ExtraDirectories -> {}
GitHubCreateRepository/GitHubRefreshAndCommit で upload_manifest.json の directories に追加するディレクトリリスト。指定されたディレクトリは manifest に永続的に追加される。
例: ExtraDirectories -> {"Claude Directives"}

### MaxItems -> 30
GitHubListCommits/GitHubCommitDataset で取得するコミット数の上限。

### Fallback -> False
LLM クエリ失敗時 (日本語パッケージ名の翻訳など) に Transliterate にフォールバックするか。False の場合はエラーをそのまま伝播して処理を停止する。

## 変数

### $GitHubLicenseHolder
型: String, 初期値: ""
MIT ライセンスの著作権者名。"" の場合、ライセンスセクションは README.md に挿入されない。
例: $GitHubLicenseHolder = "Katsunobu Imai"