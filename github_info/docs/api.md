# GitHubREST` API リファレンス

パッケージ: `GitHubREST``
依存: NBAccess (https://github.com/transreal/NBAccess), claudecode (https://github.com/transreal/claudecode)
認証: `NBAccess\`NBGetAPIKey["github"]` 経由で GitHub Personal Access Token を取得する。

## パッケージURL・ローカルリポジトリ管理

### GitHubPackageURL[packageName, opts]
`$packageDirectory` 内パッケージの GitHub URL を返す。
→ String | $Failed
Options: Owner -> Automatic (Automatic なら API トークンから取得), Repository -> Automatic, Fallback -> False

### GitHubPackageURLs[]
`$packageDirectory` 内の全パッケージ名 → URL の Association を返す。
→ Association

### GitHubRepoPath[packageName] → String
`FileNameJoin[{$packageDirectory, "GithubRepositories", packageName}]` を返す。

### GitHubEnsureLocalRepo[packageName, opts]
ローカル GitHub 作業フォルダを作成して返す。
→ String (ディレクトリパス)
Options: LocalRepoPath -> Automatic

### GitHubReadManifest[packageName] → Association
`packageName_info/upload_manifest.json` を読む。存在しなければ自動生成してディスクに保存する。パッケージ種別 (.wl/パクレット) が変わった場合も自動更新する。

### GitHubRefreshLocalPackageGroup[packageName, opts]
`upload_manifest.json` に基づき対象ファイル・ディレクトリをローカル GitHub 作業フォルダへコピーする。`_info/docs/README.md` が存在すればトップレベル `README.md` として配置する。
→ Association
Options: LocalRepoPath -> Automatic

### GitHubRefreshLocalPackage[packageName, opts]
`$packageDirectory/packageName.wl` をローカル GitHub 作業フォルダへコピーする。単一ファイル用後方互換関数。グループアップロードには `GitHubRefreshLocalPackageGroup` を使う。
→ String (コピー先パス) | Failure
Options: LocalRepoPath -> Automatic, PackageFile -> Automatic

## リポジトリ作成・ファイル操作

### GitHubCreateRepository[packageName, opts]
GitHub 上に新規リポジトリを作成する。`upload_manifest.json` が存在すれば対象ファイル群をまとめてコミットする。`_info/docs/README.md` があればトップレベル `README.md` として配置する。作成後 API から参照可能になるまで待機し、結果 Association を返す。
→ Association | Failure
Options: Repository -> Automatic, Public -> False, Description -> "", Homepage -> None, AutoInit -> True, GitignoreTemplate -> None, LicenseTemplate -> None, LocalRepoPath -> Automatic, IncludePackageFile -> True, PackageFile -> Automatic, ExtraDirectories -> {}, Fallback -> False
例: `GitHubCreateRepository["mypackage", Public -> True, Description -> "my pkg"]`

### GitHubReadFile[packageName, path, opts]
GitHub 上のファイルを読み取る。
→ String | ByteArray | List | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, ReturnType -> "Text" ("Text" | "ByteArray" | "Bytes"), Fallback -> False

### GitHubReadLocalFile[packageName, path]
ローカルファイルを常に UTF-8 でデコードして読み取る。`path` 省略時はパッケージの `.wl` ファイルを読む。`ReadString` と異なり ShiftJIS 環境でも文字化けしない。
→ String | Failure

## Pull / Commit / Push

### GitHubPull[packageName, opts]
指定ブランチのリポジトリ内容をローカル GitHub 作業フォルダへ取得する。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, Clean -> False, LocalRepoPath -> Automatic, Fallback -> False

### GitHubCommit[packageName, message, opts]
ローカル GitHub 作業フォルダの内容を GitHub の指定ブランチへコミットする。blob/tree/commit/ref 更新をまとめて実行する。`BaseBranch -> Automatic` のときリポジトリの default branch を自動使用する。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, CreateBranch -> Automatic (Branch ≠ BaseBranch なら True), LocalRepoPath -> Automatic, IncludePackageFile -> True, PackageFile -> Automatic, Force -> False, DeleteMissing -> False, Author -> Automatic, Committer -> Automatic, Fallback -> False

### GitHubRefreshAndCommit[packageName, message, opts]
`upload_manifest.json` に基づき対象ファイル群をローカル GitHub 作業フォルダへコピーし、GitHub へコミットする。`_info/docs/README.md` が変更されていればトップレベル `README.md` も自動更新する。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, CreateBranch -> Automatic, LocalRepoPath -> Automatic, IncludePackageFile -> True, PackageFile -> Automatic, ExtraDirectories -> {}, Force -> False, DeleteMissing -> False, Author -> Automatic, Committer -> Automatic, Fallback -> False

## Pull Request

### GitHubCreatePullRequest[packageName, title, opts]
Pull Request を作成する。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, BaseBranch -> Automatic, Branch -> Automatic, Head -> Automatic, Body -> "", Draft -> False, MaintainerCanModify -> True, Fallback -> False

### GitHubSubmitPullRequest[packageName, title, message, opts]
refresh → ブランチ作成 → commit → PR 作成を一発で実行する。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, BaseBranch -> Automatic, Branch -> Automatic, Head -> Automatic, Body -> "", Draft -> False, MaintainerCanModify -> True, LocalRepoPath -> Automatic, IncludePackageFile -> True, PackageFile -> Automatic, ExtraDirectories -> {}, Force -> False, DeleteMissing -> False, Author -> Automatic, Committer -> Automatic, Fallback -> False

### GitHubListPullRequests[packageName, opts]
オープンな PR 一覧を緊急度・依存関係でソートして返す。
→ List | Failure
Options: Owner -> Automatic, Repository -> Automatic, Fallback -> False

### GitHubPullRequestDataset[packageName, opts]
PR 一覧を Review/Pull/Merge/Close ボタン付き Grid で返す。ノートブック上でインタラクティブに操作できる。
→ Grid | Failure
Options: Owner -> Automatic, Repository -> Automatic, Fallback -> False

### GitHubMergePullRequest[packageName, prNumber, reason]
PR をマージする。
→ Association | Failure

### GitHubClosePullRequest[packageName, prNumber, reason]
PR をクローズする。
→ Association | Failure

### GitHubReviewPullRequest[packageName, prNumber]
PR のコードをダウンロードし、レビュー用コードをノートブックに出力する。
→ Association | Failure

## コミット履歴

### GitHubListCommits[packageName, opts]
リポジトリのコミット履歴を取得してリストで返す。
→ List | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, MaxItems -> 30, Fallback -> False

### GitHubCommitDataset[packageName, opts]
コミット履歴を Review/Pull/Revert ボタン付き Grid で表示する。起動時に現在の作業状態をローカルスナップショットとして保存する。#0 行の Pull でスナップショットに戻せる。
→ Grid | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, MaxItems -> 30, Fallback -> False

### GitHubReviewCommit[packageName, sha]
指定コミットの詳細・差分をノートブックに表示する。
→ Association | Failure

### GitHubRevertCommit[packageName, sha]
指定コミットの変更を元に戻すリバートコミットを作成する。
→ Association | Failure

## リポジトリ名データベース

### GitHubRepoDB[]
`GithubRepositories/repo_database.json` を読み込み、全レコードを Association で返す。日本語パッケージ名 → 英語リポジトリ名の対応表。
→ Association

### GitHubRepoDBSet[packageName, repoName]
パッケージ名と GitHub リポジトリ名の対応を DB に登録する。
→ String (DBファイルパス)

### GitHubRepoDBSet[packageName, repoName, owner]
owner も含めて DB に登録する。
→ String (DBファイルパス)

### GitHubRepoDBLookup[packageName] → String
DB からリポジトリ名を解決する。未登録なら `packageName` をそのまま返す。

## パッケージインストール・更新

### GitHubInstallPackage[packageName, opts]
GitHub から `$packageDirectory` にパッケージを初回ダウンロードする。インストール後は `packageName` だけで各操作関数が動作する。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, Fallback -> False

### GitHubInstallPackage[packageName, url, opts]
他人のリポジトリ URL からインストールする。
→ Association | Failure
例: `GitHubInstallPackage["pkg", "https://github.com/user/repo"]`

### GitHubUpdatePackage[packageName, opts]
既存パッケージを GitHub の最新に更新する。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, Fallback -> False

## オプションシンボル

### Owner
GitHub の所有者 (ユーザー名/組織名)。Automatic なら認証トークンの所有ユーザーを使う。

### Repository
GitHub リポジトリ名。Automatic なら `packageName` を使う。

### Public
新規リポジトリを公開にするか。既定値 False (private)。

### Description
新規リポジトリ作成時の description。

### Homepage
新規リポジトリ作成時の homepage URL。

### AutoInit
新規リポジトリ作成時に README 付きで初期化するか。既定値 True。

### GitignoreTemplate
GitHub の gitignore template 名。

### LicenseTemplate
GitHub の license template 名。

### Branch
操作対象ブランチ。Automatic なら BaseBranch を使う。

### BaseBranch
既定ブランチまたは PR の base branch。Automatic なら API からリポジトリの default branch を自動取得する。

### CreateBranch
`GitHubCommit` 実行時に対象ブランチが存在しなければ BaseBranch から新規作成するか。Automatic なら Branch ≠ BaseBranch のとき True。

### LocalRepoPath
ローカル GitHub 作業フォルダを明示指定する。

### PackageFile
元の `packageName.wl` のパスを明示指定する。

### IncludePackageFile
`GitHubCommit` / `GitHubCreateRepository` の前に `packageName.wl` をローカル GitHub 作業フォルダへコピーするか。既定値 True。

### ReturnType
`GitHubReadFile` の戻り値型。`"Text"` | `"ByteArray"` | `"Bytes"`。

### Clean
`GitHubPull` 時に既存のローカルファイルを先に削除するか。既定値 False。

### Force
ref 更新時に fast-forward 制約を無視するか。既定値 False。

### DeleteMissing
`GitHubCommit` 時にローカルに存在しないリモート blob を削除対象として tree に含めるか。既定値 False。

### Head
PR の head ブランチ。Automatic なら Branch を使う。

### Body
PR 本文。

### Draft
PR を draft として作成するか。

### MaintainerCanModify
PR で maintainers に head branch の編集を許可するか。

### Author
commit author。`<|"name" -> ..., "email" -> ...|>` 形式で指定する。

### Committer
commit committer。`<|"name" -> ..., "email" -> ...|>` 形式で指定する。

### ExtraDirectories
`GitHubCreateRepository` / `GitHubRefreshAndCommit` で `upload_manifest.json` の directories に追加するディレクトリのリスト。指定されたディレクトリは manifest に永続的に追加される。
例: `ExtraDirectories -> {"Claude Directives"}`

### MaxItems
`GitHubListCommits` / `GitHubCommitDataset` で取得するコミット数の上限。既定値 30。

## 変数

### $GitHubLicenseHolder
型: String, 初期値: ""
MIT ライセンスの著作権者名。空文字列 `""` の場合、ライセンスセクションは `README.md` に挿入されない。
例: `$GitHubLicenseHolder = "Katsunobu Imai"`