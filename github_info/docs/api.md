# GitHubREST` API Reference

パッケージ: `GitHubREST``
依存: NBAccess`（`NBAccess`NBGetAPIKey["github"]` で認証トークンを取得）
GitHub: https://github.com/transreal/github

## パッケージURL・ローカルリポジトリ管理

### GitHubPackageURL[packageName, opts]
$packageDirectory 内のパッケージの GitHub URL を返す。
→ String | $Failed
Options: Owner -> Automatic (ユーザー名; Automatic なら API トークンから取得), Repository -> Automatic (リポジトリ名; Automatic なら packageName を使用), Fallback -> False (True で ClaudeCode フォールバックモードを有効化)

### GitHubPackageURLs[] → Association
$packageDirectory 内の全パッケージの `<|name -> url, ...|>` を返す。

### GitHubRepoPath[packageName] → String
ローカル GitHub 作業フォルダのパス（`$packageDirectory/GithubRepositories/packageName`）を返す。

### GitHubEnsureLocalRepo[packageName, opts]
ローカル GitHub 作業フォルダを作成して返す。
→ String
Options: LocalRepoPath -> Automatic (保存先パスを明示指定)

### GitHubRefreshLocalPackage[packageName, opts]
$packageDirectory/packageName.wl をローカル GitHub 作業フォルダへコピーする（単一ファイル用後方互換）。グループアップロードには GitHubRefreshLocalPackageGroup を使う。
→ String | Failure
Options: LocalRepoPath -> Automatic, PackageFile -> Automatic (元ファイルパスを明示指定)

### GitHubRefreshLocalPackageGroup[packageName, opts]
upload_manifest.json に基づき対象ファイル・ディレクトリをローカル GitHub 作業フォルダへコピーする。_info/docs/README.md があればトップレベル README.md として配置する。
→ Association | Failure
Options: LocalRepoPath -> Automatic

## マニフェスト管理

### GitHubReadManifest[packageName] → Association
packageName_info/upload_manifest.json を読み込みファイル・ディレクトリ一覧を返す。ファイルが存在しない場合は自動生成してディスクに保存する。パッケージ種別（.wl/パクレット）が変わった場合も自動更新する。

### GitHubValidateManifest[packageName] → Association
upload_manifest.json を検査し `<|Status, FileCount, PresentFileCount, MissingFiles, Directories, ExcludePatterns, Issues|>` を返す。Status は `"OK"` または `"Issues"`。files[] の実在・secret/token/credential らしきファイルの混入・除外パターンを確認する。

## リポジトリ操作

### GitHubCreateRepository[packageName, opts]
GitHub 上に新規リポジトリを作成する。upload_manifest.json が存在すれば対象ファイル群をまとめてコミットする。作成後 API から参照可能になるまで待機し結果 Association を返す。
→ Association | Failure
Options: Repository -> Automatic, Public -> False (True で公開リポジトリ), Description -> "" (リポジトリ説明), Homepage -> None, AutoInit -> True (README 付き初期化), GitignoreTemplate -> None, LicenseTemplate -> None, LocalRepoPath -> Automatic, IncludePackageFile -> True (作成時にファイルをコミット), PackageFile -> Automatic, ExtraDirectories -> {} (manifest の directories に永続追加するディレクトリリスト), Fallback -> False

### GitHubReadFile[packageName, path, opts]
GitHub 上のファイルを読み取る。
→ String | ByteArray | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, ReturnType -> "Text" ("Text" | "ByteArray" | "Bytes"), Fallback -> False

### GitHubReadLocalFile[packageName] または GitHubReadLocalFile[packageName, path] → String
ローカルファイルを常に UTF-8 でデコードして返す。path 省略時はパッケージの .wl ファイルを読む。$CharacterEncoding に依存しないため日本語環境でも文字化けしない。

### GitHubPull[packageName, opts]
指定ブランチのリポジトリ内容をローカル GitHub 作業フォルダへ取得する。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, Clean -> False (True で既存ローカルファイルを先に削除)

### GitHubCommit[packageName, message, opts]
ローカル GitHub 作業フォルダの内容を GitHub の指定ブランチへコミットする。blob/tree/commit/ref 更新の流れで複数ファイルをまとめて反映する。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic (Automatic でリポジトリの default branch を自動使用), CreateBranch -> Automatic (Automatic かつ Branch≠BaseBranch なら True), LocalRepoPath -> Automatic, IncludePackageFile -> True, PackageFile -> Automatic, DeleteMissing -> False (True でローカルに存在しないリモート blob を削除), Force -> False (fast-forward 制約を無視), Author -> Automatic (`<|"name"->..., "email"->...|>`), Committer -> Automatic, Fallback -> False

### GitHubRefreshAndCommit[packageName, message, opts]
upload_manifest.json に基づきファイルをローカル作業フォルダへコピーして GitHub へコミットする。_info/docs/README.md が変更されていればトップレベル README.md も自動更新する。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, CreateBranch -> Automatic, LocalRepoPath -> Automatic, IncludePackageFile -> True, PackageFile -> Automatic, DeleteMissing -> False, Force -> False, Author -> Automatic, Committer -> Automatic, ExtraDirectories -> {}, Fallback -> False

### GitHubCreatePullRequest[packageName, title, opts]
プルリクエストを作成する。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, Head -> Automatic (head branch; Automatic なら Branch を使用), Body -> "" (PR 本文), Draft -> False, MaintainerCanModify -> True, Fallback -> False

### GitHubSubmitPullRequest[packageName, title, message, opts]
refresh → branch 作成 → commit → pull request 作成を一括実行する。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, LocalRepoPath -> Automatic, Head -> Automatic, Body -> "", Draft -> False, MaintainerCanModify -> True, ExtraDirectories -> {}, Fallback -> False

## リポジトリ名データベース

### GitHubRepoDB[] → Association
GithubRepositories/repo_database.json を読み込み全レコードを返す。

### GitHubRepoDBSet[packageName, repoName] または GitHubRepoDBSet[packageName, repoName, owner]
パッケージ名と GitHub リポジトリ名（および owner）の対応を DB に登録する。日本語パッケージ名に英語リポジトリ名を対応付ける場合に使う。
→ String

### GitHubRepoDBLookup[packageName] → String
DB からリポジトリ名を解決する。未登録なら packageName をそのまま返す。

## パッケージインストール・更新

### GitHubInstallPackage[packageName, opts] または GitHubInstallPackage[packageName, url, opts]
GitHub から $packageDirectory にパッケージを初回ダウンロードする。url を指定すると他者のリポジトリからインストールする。インストール後は packageName だけで GitHubUpdatePackage/GitHubCommitDataset 等が動作する。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, Fallback -> False
例: `GitHubInstallPackage["pkg", "https://github.com/user/repo"]`

### GitHubUpdatePackage[packageName, opts]
既存パッケージを GitHub の最新版に更新する。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, Fallback -> False

## プルリクエスト管理

### GitHubListPullRequests[packageName, opts]
オープンな PR 一覧を緊急度・依存関係でソートして返す（labels から urgent/critical/high/low/breaking/security/bug/feature を参照）。
→ List | Failure
Options: Owner -> Automatic, Repository -> Automatic, Fallback -> False

### GitHubPullRequestDataset[packageName, opts]
PR 一覧を Review/Pull/Merge/Close ボタン付き Grid で表示する。
→ Grid | Failure
Options: Owner -> Automatic, Repository -> Automatic, Fallback -> False

### GitHubMergePullRequest[packageName, prNumber, reason] → Association | Failure
PR をマージする。

### GitHubClosePullRequest[packageName, prNumber, reason] → Association | Failure
PR をクローズする。

### GitHubReviewPullRequest[packageName, prNumber] → _
PR のコードをダウンロードしレビュー用コードをノートブックに出力する。

## コミット履歴

### GitHubListCommits[packageName, opts]
リポジトリのコミット履歴を取得してリストで返す。
→ List | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, MaxItems -> 30 (取得コミット数上限), Fallback -> False

### GitHubCommitDataset[packageName, opts]
コミット履歴を Review/Pull/Revert ボタン付き Grid で表示する。起動時に現在の作業状態をローカルスナップショット（GithubRepositories/_local_snapshot/packageName/）として保存する。#0 行の Pull でスナップショットに復元可能。
→ Grid | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, MaxItems -> 30, Fallback -> False

### GitHubReviewCommit[packageName, sha] → _
指定コミットの詳細・差分をノートブックに表示する。

### GitHubRevertCommit[packageName, sha, opts] → Association | Failure
指定コミットの変更を元に戻すリバートコミットを作成する。
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, Fallback -> False

## オプションシンボル

### Owner → Automatic
GitHub の所有者（ユーザー名/組織名）。Automatic なら認証トークンの所有ユーザーを使用。

### Repository → Automatic
GitHub のリポジトリ名。Automatic なら packageName を使用。

### Public → False
新規リポジトリを公開にするか。False でプライベートリポジトリを作成。

### Description → ""
新規リポジトリ作成時の説明文。

### Homepage → None
新規リポジトリ作成時のホームページ URL。

### AutoInit → True
新規リポジトリ作成時に README 付きで初期化するか。

### GitignoreTemplate → None
GitHub の .gitignore テンプレート名。

### LicenseTemplate → None
GitHub のライセンステンプレート名。

### Branch → Automatic
操作対象ブランチ。Automatic なら BaseBranch を使用。

### BaseBranch → Automatic
既定ブランチまたは PR の base branch。Automatic でリポジトリの default branch を API から自動取得。

### CreateBranch → Automatic
GitHubCommit 時に対象ブランチが存在しなければ BaseBranch から新規作成するか。Automatic なら Branch≠BaseBranch のとき True。

### LocalRepoPath → Automatic
ローカル GitHub 作業フォルダを明示指定する。

### PackageFile → Automatic
元の packageName.wl のパスを明示指定する。

### IncludePackageFile → True
GitHubCommit/GitHubCreateRepository の前に packageName.wl をローカル作業フォルダへコピーするか。

### ReturnType → "Text"
GitHubReadFile の戻り値型。`"Text"` | `"ByteArray"` | `"Bytes"`。

### Clean → False
GitHubPull 時に既存のローカルファイルを先に削除するか。

### Force → False
ref 更新時に fast-forward 制約を無視するか。

### DeleteMissing → False
GitHubCommit 時にローカルに存在しないリモート blob を削除対象として tree に含めるか。

### Head → Automatic
PR の head branch。Automatic なら Branch を使用。

### Body → ""
PR の本文。

### Draft → False
PR を draft として作成するか。

### MaintainerCanModify → True
PR で maintainers に head branch の編集を許可するか。

### Author → Automatic
コミット author を `<|"name" -> ..., "email" -> ...|>` の形で指定する。

### Committer → Automatic
コミット committer を `<|"name" -> ..., "email" -> ...|>` の形で指定する。

### ExtraDirectories → {}
GitHubCreateRepository/GitHubRefreshAndCommit で upload_manifest.json の directories に永続追加するディレクトリのリスト。
例: `ExtraDirectories -> {"Claude Directives"}`

### MaxItems → 30
GitHubListCommits/GitHubCommitDataset で取得するコミット数の上限。

## 変数

### $GitHubLicenseHolder
型: String, 初期値: ""
MIT ライセンスの著作権者名。空文字列 `""` の場合、ライセンスセクションは README.md に挿入されない。
例: `$GitHubLicenseHolder = "Katsunobu Imai"`