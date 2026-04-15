# GitHubREST` API リファレンス

パッケージ: `GitHubREST`` / ファイル: `github_fixed.wl`
依存: [NBAccess](https://github.com/transreal/NBAccess) (`NBAccess`NBGetAPIKey["github"]` で認証)

## パッケージ URL 取得

### GitHubPackageURL[packageName, opts]
`$packageDirectory` 内のパッケージの GitHub URL を返す。
→ String | $Failed
Options: Owner -> Automatic (Automatic なら API トークンから取得), Repository -> Automatic, Fallback -> False (True でフォールバックモード有効)

### GitHubPackageURLs[]
`$packageDirectory` 内の全パッケージの `<|name -> url, ...|>` を返す。
→ Association

## ローカルリポジトリ管理

### GitHubRepoPath[packageName] → String
ローカル GitHub 作業フォルダのパスを返す。`FileNameJoin[{$packageDirectory, "GithubRepositories", packageName}]`

### GitHubEnsureLocalRepo[packageName, opts]
ローカル GitHub 作業フォルダを作成して返す。
→ String (ディレクトリパス)
Options: LocalRepoPath -> Automatic

### GitHubReadManifest[packageName] → Association
`packageName_info/upload_manifest.json` を読む。ファイルが存在しない場合は自動生成してディスクに保存する。パッケージ種別 (.wl/パクレット) が変わった場合も自動更新する。

### GitHubRefreshLocalPackageGroup[packageName, opts]
`upload_manifest.json` に基づき対象ファイル・ディレクトリをローカル GitHub 作業フォルダへコピーする。`_info/docs/README.md` が存在すればトップレベル `README.md` として配置する。
→ Association
Options: LocalRepoPath -> Automatic

### GitHubRefreshLocalPackage[packageName, opts]
`$packageDirectory/packageName.wl` をローカル GitHub 作業フォルダへコピーする。単一ファイル用後方互換。グループアップロードには `GitHubRefreshLocalPackageGroup` を使う。
→ String (コピー先パス) | Failure
Options: LocalRepoPath -> Automatic, PackageFile -> Automatic

## リポジトリ作成・読み書き

### GitHubCreateRepository[packageName, opts]
GitHub 上に新規リポジトリを作成する。`upload_manifest.json` が存在すれば対象ファイル群をまとめてコミットする。作成後リポジトリが API から参照可能になるまで待機し、default branch を含む Association を返す。
→ `<|"Package"->..., "Owner"->..., "Repository"->..., "DefaultBranch"->..., "LocalRepoPath"->..., "RefreshResult"->..., "Response"->...|>` | Failure
Options: Repository -> Automatic, Public -> False, Description -> "", Homepage -> None, AutoInit -> True, GitignoreTemplate -> None, LicenseTemplate -> None, LocalRepoPath -> Automatic, IncludePackageFile -> True, PackageFile -> Automatic, ExtraDirectories -> {} (manifest の directories に永続追加), Fallback -> False

### GitHubReadFile[packageName, path, opts]
GitHub 上のファイルを読み取る。
→ String | ByteArray | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, ReturnType -> "Text" ("Text" | "ByteArray" | "Bytes"), Fallback -> False

### GitHubReadLocalFile[packageName, path]
ローカルファイルを常に UTF-8 でデコードして返す。`path` 省略時はパッケージの `.wl` ファイルを読む。`ReadString` と異なり `$CharacterEncoding` に依存しない。
→ String

## プッシュ・コミット操作

### GitHubPull[packageName, opts]
指定ブランチのリポジトリ内容をローカル GitHub 作業フォルダへ取得する。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, Clean -> False (True で既存ローカルファイルを先に削除)

### GitHubCommit[packageName, message, opts]
ローカル GitHub 作業フォルダの内容を GitHub の指定ブランチへコミットする。blob/tree/commit/ref 更新の流れで複数ファイルをまとめて反映する。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic (Automatic でリポジトリの default branch を自動使用), CreateBranch -> Automatic (Automatic かつ Branch ≠ BaseBranch なら True), LocalRepoPath -> Automatic, IncludePackageFile -> True, PackageFile -> Automatic, Force -> False (True で ref 更新時 fast-forward 制約を無視), DeleteMissing -> False (True でローカルに存在しないリモート blob を削除), Author -> Automatic (`<|"name"->..., "email"->...|>`), Committer -> Automatic

### GitHubRefreshAndCommit[packageName, message, opts]
`upload_manifest.json` に基づき対象ファイル群をローカルへコピーし GitHub へコミットする。`_info/docs/README.md` が変更されていればトップレベル `README.md` も自動更新する。
→ Association | Failure

### GitHubCreatePullRequest[packageName, title, opts]
Pull Request を作成する。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, BaseBranch -> Automatic, Head -> Automatic (Automatic で Branch を使用), Body -> "", Draft -> False, MaintainerCanModify -> True

### GitHubSubmitPullRequest[packageName, title, message, opts]
refresh → branch 作成 → commit → pull request 作成を一括実行する。
→ Association | Failure

## リポジトリ名データベース

### GitHubRepoDB[] → Association
`GithubRepositories/repo_database.json` を読み込み全レコードを返す。日本語パッケージ名 → 英語リポジトリ名の対応表。

### GitHubRepoDBSet[packageName, repoName]
### GitHubRepoDBSet[packageName, repoName, owner]
パッケージ名と GitHub リポジトリ名の対応を DB に登録する。日本語パッケージ名に英語リポジトリ名を指定する場合に使う。

### GitHubRepoDBLookup[packageName] → String
DB からリポジトリ名を解決する。未登録なら `packageName` をそのまま返す。

## インストール・更新

### GitHubInstallPackage[packageName, opts]
### GitHubInstallPackage[packageName, url, opts]
GitHub から `$packageDirectory` にパッケージを初回ダウンロードする。`url` を指定すると他者のリポジトリからインストールできる。インストール後は `GitHubUpdatePackage` / `GitHubCommitDataset` / `GitHubSubmitPullRequest` 等がパッケージ名だけで動作する。リポジトリ種別 (自分/リモート+_info あり/リモート+_info なし) を自動判定してコピー先を振り分ける。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, Fallback -> False
例: `GitHubInstallPackage["pkg", "https://github.com/user/repo"]`

### GitHubUpdatePackage[packageName, opts]
既存パッケージを GitHub の最新版に更新する。
→ Association | Failure

## プルリクエスト管理

### GitHubListPullRequests[packageName, opts]
オープンな PR 一覧を緊急度・依存関係でソートして返す。
→ List | Failure
Options: Owner -> Automatic, Repository -> Automatic, Fallback -> False

### GitHubPullRequestDataset[packageName, opts]
PR 一覧を Review/Pull/Merge/Close ボタン付き Grid で返す。ノートブック上でインタラクティブ操作が可能。
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
→ Null (副作用: セル出力)

## コミット履歴

### GitHubListCommits[packageName, opts]
リポジトリのコミット履歴を取得してリストで返す。
→ List | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, MaxItems -> 30, Fallback -> False

### GitHubCommitDataset[packageName, opts]
コミット履歴を Review/Pull/Revert ボタン付き Grid で表示する。起動時に現在の作業状態をローカルスナップショットとして保存する。#0 行でローカル最新版への復元が可能。
→ Grid | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, MaxItems -> 30, Fallback -> False

### GitHubReviewCommit[packageName, sha]
指定コミットの詳細・差分をノートブックに表示する。
→ Null (副作用: セル出力)

### GitHubRevertCommit[packageName, sha]
指定コミットの変更を元に戻すリバートコミットを作成する。
→ Association | Failure

## オプションシンボル

以下はオプションキーとして使用するシンボル。単独で評価しても意味を持たない。

`Owner` — GitHub 所有者名 (ユーザー/組織)。Automatic でトークンから自動取得。
`Repository` — リポジトリ名。Automatic で packageName を使用。
`Public` — リポジトリを公開にするか。既定値 False。
`Description` — リポジトリ作成時の説明文。
`Homepage` — リポジトリ作成時のホームページ URL。
`AutoInit` — 作成時に README 付きで初期化するか。既定値 True。
`GitignoreTemplate` — GitHub の gitignore テンプレート名。
`LicenseTemplate` — GitHub の license テンプレート名。
`Branch` — 操作対象ブランチ。Automatic で BaseBranch を使用。
`BaseBranch` — 既定ブランチまたは PR の base branch。Automatic でリポジトリの default branch を API から自動取得。
`CreateBranch` — コミット時に対象ブランチが存在しなければ BaseBranch から新規作成するか。Automatic かつ Branch ≠ BaseBranch なら True。
`LocalRepoPath` — ローカル GitHub 作業フォルダを明示指定。
`PackageFile` — 元の packageName.wl のパスを明示指定。
`IncludePackageFile` — コミット/作成前に packageName.wl をコピーするか。既定値 True。
`ReturnType` — GitHubReadFile の戻り値型。"Text" | "ByteArray" | "Bytes"。既定値 "Text"。
`Clean` — Pull 時に既存ローカルファイルを先に削除するか。既定値 False。
`Force` — ref 更新時に fast-forward 制約を無視するか。既定値 False。
`DeleteMissing` — コミット時にローカルに存在しないリモート blob を削除するか。既定値 False。
`Head` — PR の head ブランチ。Automatic で Branch を使用。
`Body` — PR 本文。
`Draft` — PR を draft として作成するか。
`MaintainerCanModify` — PR で maintainers に head branch の編集を許可するか。
`Author` — commit author を `<|"name"->..., "email"->...|>` で指定。
`Committer` — commit committer を `<|"name"->..., "email"->...|>` で指定。
`ExtraDirectories` — GitHubCreateRepository / GitHubRefreshAndCommit で upload_manifest.json の directories に永続追加するディレクトリリスト。例: `ExtraDirectories -> {"Claude Directives"}`
`MaxItems` — GitHubListCommits / GitHubCommitDataset で取得するコミット数の上限。既定値 30。

## 変数

### $GitHubLicenseHolder
型: String, 初期値: ""
MIT ライセンスの著作権者名。空文字列 "" の場合、ライセンスセクションは README.md に挿入されない。
例: `$GitHubLicenseHolder = "Katsunobu Imai"`