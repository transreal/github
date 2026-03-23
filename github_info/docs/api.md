# GitHubREST` パッケージ API リファレンス

## 概要

GitHub REST API ユーティリティ。NBAccess.wl および claudecode.wl と連携動作する。認証は `NBAccess`NBGetAPIKey["github"]` に委譲。

依存: [NBAccess](https://github.com/transreal/NBAccess), [claudecode](https://github.com/transreal/claudecode)

## 定数

### $GitHubLicenseHolder
型: String, 初期値: ""
MIT ライセンスの著作権者名。空文字列の場合 README.md にライセンスセクションは挿入されない。
例: `$GitHubLicenseHolder = "Katsunobu Imai"`

## パッケージ URL 取得

### GitHubPackageURL[packageName, opts]
`$packageDirectory` 内のパッケージの GitHub URL を返す。
→ String | $Failed
Options: Owner -> Automatic (ユーザー名/組織名。Automatic なら API トークンから取得), Repository -> Automatic (リポジトリ名。Automatic なら packageName を使用), Fallback -> False

### GitHubPackageURLs[]
`$packageDirectory` 内の全パッケージの `<|name -> url, ...|>` を返す。
→ Association

## ローカルリポジトリ管理

### GitHubRepoPath[packageName]
ローカル GitHub 作業フォルダのパスを返す。`FileNameJoin[{$packageDirectory, "GithubRepositories", packageName}]`
→ String

### GitHubEnsureLocalRepo[packageName, opts]
ローカル GitHub 作業フォルダを作成して返す。
→ String (ディレクトリパス)
Options: LocalRepoPath -> Automatic

### GitHubRefreshLocalPackage[packageName, opts]
`$packageDirectory/packageName.wl` をローカル GitHub 作業フォルダへコピーする。単一ファイル用後方互換。グループアップロードには `GitHubRefreshLocalPackageGroup` を使う。
→ String (コピー先パス) | Failure
Options: LocalRepoPath -> Automatic, PackageFile -> Automatic

### GitHubReadManifest[packageName]
`packageName_info/upload_manifest.json` を読み Association で返す。ファイルが存在しない場合は自動生成してディスクに保存。パッケージ種別 (.wl/パクレット) が変わった場合も自動更新する。
→ Association

### GitHubRefreshLocalPackageGroup[packageName, opts]
`upload_manifest.json` に基づき対象ファイル・ディレクトリをローカル GitHub 作業フォルダへコピーする。`_info/docs/README.md` が存在すればトップレベル `README.md` として配置する。
→ Association | Failure
Options: LocalRepoPath -> Automatic

## リポジトリ作成・読み取り

### GitHubCreateRepository[packageName, opts]
GitHub 上に新規リポジトリを作成する。`upload_manifest.json` が存在すれば対象ファイル群をまとめてコミット。`_info/docs/README.md` があればトップレベル `README.md` として配置。作成後リポジトリが API から参照可能になるまで待機し、結果 Association を返す。
→ Association | Failure
Options: Repository -> Automatic, Public -> False, Description -> "", Homepage -> None, AutoInit -> True, GitignoreTemplate -> None, LicenseTemplate -> None, LocalRepoPath -> Automatic, IncludePackageFile -> True, PackageFile -> Automatic, ExtraDirectories -> {} (manifest の directories に永続追加するディレクトリリスト), Fallback -> False
例: `GitHubCreateRepository["fact", Public -> False, ExtraDirectories -> {"Claude Directives"}]`

### GitHubReadFile[packageName, path, opts]
GitHub 上のファイルを読み取る。
→ String | ByteArray | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, ReturnType -> "Text" ("Text" | "ByteArray" | "Bytes"), Fallback -> False

### GitHubReadLocalFile[packageName, path]
ローカルファイルを常に UTF-8 でデコードして読み取る。`path` 省略時はパッケージの .wl ファイルを読む。`ReadString` と異なり日本語環境で文字化けしない。
→ String | Failure

## プル・コミット・PR

### GitHubPull[packageName, opts]
指定ブランチのリポジトリ内容をローカル GitHub 作業フォルダへ取得する。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, Clean -> False (取得前に既存ローカルファイルを削除するか)

### GitHubCommit[packageName, message, opts]
ローカル GitHub 作業フォルダの内容を GitHub の指定ブランチへコミットする。複数ファイルを blob/tree/commit/ref 更新の流れでまとめて反映する。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic (Automatic でリポジトリの default branch を自動使用), CreateBranch -> Automatic (Automatic は Branch ≠ BaseBranch なら True), LocalRepoPath -> Automatic, IncludePackageFile -> True, PackageFile -> Automatic, Author -> Automatic (<|"name"->..., "email"->...|>), Committer -> Automatic, Force -> False (ref 更新時に fast-forward 制約を無視するか), DeleteMissing -> False (ローカルに存在しないリモート blob を削除対象として tree に含めるか), Fallback -> False

### GitHubCreatePullRequest[packageName, title, opts]
Pull Request を作成する。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, Head -> Automatic (Automatic は Branch を使用), Body -> "", Draft -> False, MaintainerCanModify -> True, Fallback -> False

### GitHubRefreshAndCommit[packageName, message, opts]
`upload_manifest.json` に基づき対象ファイル群をローカル GitHub 作業フォルダへコピーし、GitHub へコミットする。`_info/docs/README.md` が変更されていればトップレベル `README.md` も自動更新する。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, CreateBranch -> Automatic, LocalRepoPath -> Automatic, IncludePackageFile -> True, PackageFile -> Automatic, ExtraDirectories -> {}, Author -> Automatic, Committer -> Automatic, Force -> False, DeleteMissing -> False, Fallback -> False

### GitHubSubmitPullRequest[packageName, title, message, opts]
refresh → ブランチ作成 → commit → PR 作成を一発で実行する。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, CreateBranch -> Automatic, Body -> "", Draft -> False, MaintainerCanModify -> True, LocalRepoPath -> Automatic, IncludePackageFile -> True, PackageFile -> Automatic, ExtraDirectories -> {}, Author -> Automatic, Committer -> Automatic, Force -> False, DeleteMissing -> False, Fallback -> False
例: `GitHubSubmitPullRequest["fact", "Fix bug", "バグ修正", Body -> "詳細説明", Branch -> "feature/fix"]`

## インストール・更新

### GitHubInstallPackage[packageName, opts]
GitHub から `$packageDirectory` にパッケージを初回ダウンロードする。インストール後は `GitHubUpdatePackage` / `GitHubCommitDataset` / `GitHubSubmitPullRequest` 等がパッケージ名だけでリモートリポジトリに対して動作する。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, Fallback -> False

### GitHubInstallPackage[packageName, url, opts]
他者のリポジトリ URL からインストールする。
例: `GitHubInstallPackage["ResistorBuilder", "https://github.com/dzhang314/ResistorBuilder"]`
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, Fallback -> False

### GitHubUpdatePackage[packageName, opts]
既存パッケージを GitHub の最新に更新する。
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, Fallback -> False

## リポジトリ名データベース

### GitHubRepoDB[]
`GithubRepositories/repo_database.json` を読み込み、全レコードを Association で返す。
→ Association

### GitHubRepoDBSet[packageName, repoName]
パッケージ名と GitHub リポジトリ名の対応を DB に登録する。日本語パッケージ名に英語リポジトリ名を指定するときに使う。
→ String (DB ファイルパス)

### GitHubRepoDBSet[packageName, repoName, owner]
owner も含めて登録する。
→ String

### GitHubRepoDBLookup[packageName]
DB からリポジトリ名を解決する。未登録なら packageName をそのまま返す。
→ String

## PR 管理

### GitHubListPullRequests[packageName, opts]
オープンな PR 一覧を緊急度・依存関係でソートして返す。
→ List | Failure
Options: Owner -> Automatic, Repository -> Automatic, Fallback -> False

### GitHubPullRequestDataset[packageName, opts]
PR 一覧を Review/Pull/Merge/Close ボタン付き Dataset (Grid) で返す。ノートブック上でインタラクティブ操作可能。
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
→ Null | Failure

## コミット履歴

### GitHubListCommits[packageName, opts]
リポジトリのコミット履歴をリストで返す。
→ List | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, MaxItems -> 30, Fallback -> False

### GitHubCommitDataset[packageName, opts]
コミット履歴を Review/Pull/Revert ボタン付き Grid で表示する。起動時に現在の作業状態をローカル最新版スナップショットとして保存する。#0 行の Pull でスナップショットに復元可能。
→ Grid | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, MaxItems -> 30, Fallback -> False

### GitHubReviewCommit[packageName, sha]
指定コミットの詳細・差分をノートブックに表示する。
→ Null | Failure

### GitHubRevertCommit[packageName, sha]
指定コミットの変更を元に戻すリバートコミットを作成する。
→ Association | Failure

## オプション一覧

| オプション | 既定値 | 説明 |
|---|---|---|
| Owner | Automatic | GitHub ユーザー名/組織名。Automatic は API トークンから取得 |
| Repository | Automatic | リポジトリ名。Automatic は packageName を使用 |
| Public | False | リポジトリを公開にするか |
| Description | "" | リポジトリの説明 |
| Homepage | None | リポジトリの homepage URL |
| AutoInit | True | README 付きで初期化するか |
| GitignoreTemplate | None | GitHub の gitignore テンプレート名 |
| LicenseTemplate | None | GitHub のライセンステンプレート名 |
| Branch | Automatic | 操作対象ブランチ。Automatic は BaseBranch を使用 |
| BaseBranch | Automatic | 基底ブランチ。Automatic はリポジトリの default branch を API から取得 |
| CreateBranch | Automatic | ブランチが存在しなければ BaseBranch から新規作成するか。Automatic は Branch ≠ BaseBranch なら True |
| LocalRepoPath | Automatic | ローカル GitHub 作業フォルダの明示指定 |
| PackageFile | Automatic | packageName.wl のパスを明示指定 |
| IncludePackageFile | True | コミット前に packageName.wl をローカル作業フォルダへコピーするか |
| ReturnType | "Text" | GitHubReadFile の戻り値型。"Text" \| "ByteArray" \| "Bytes" |
| Clean | False | GitHubPull 時に既存ローカルファイルを先に削除するか |
| Force | False | ref 更新時に fast-forward 制約を無視するか |
| DeleteMissing | False | ローカルに存在しないリモート blob を削除対象として tree に含めるか |
| Head | Automatic | PR の head ブランチ。Automatic は Branch を使用 |
| Body | "" | PR 本文 |
| Draft | False | PR を draft として作成するか |
| MaintainerCanModify | True | PR で maintainers に head branch の編集を許可するか |
| Author | Automatic | コミット author `<\|"name"->..., "email"->...\|>` |
| Committer | Automatic | コミット committer `<\|"name"->..., "email"->...\|>` |
| ExtraDirectories | {} | manifest の directories に永続追加するディレクトリリスト |
| MaxItems | 30 | GitHubListCommits / GitHubCommitDataset で取得するコミット数の上限 |
| Fallback | False | True の場合 Claude Code 利用不可時に代替モデルを試行する |

## 使用パターン

```mathematica
(* ロード *)
Block[{$CharacterEncoding = "UTF-8"}, Needs["GitHubREST`", "github.wl"]]

(* 新規リポジトリ作成 *)
GitHubCreateRepository["fact", Public -> False]

(* 更新コミット *)
GitHubRefreshAndCommit["fact", "Update fact"]

(* PR 作成 *)
GitHubSubmitPullRequest["fact", "Fix bug", "バグ修正", Branch -> "feature/fix"]

(* 他者リポジトリからインストール *)
GitHubInstallPackage["ResistorBuilder", "https://github.com/dzhang314/ResistorBuilder"]

(* 日本語パッケージ名のリポジトリ名登録 *)
GitHubRepoDBSet["掛け算", "multiplication-table"]

(* コミット履歴インタラクティブ表示 *)
GitHubCommitDataset["fact"]

(* PR 一覧インタラクティブ表示 *)
GitHubPullRequestDataset["fact"]
```

## 認証

```mathematica
NBAccess`NBGetAPIKey["github"]  (* GitHub アクセストークン取得 *)
```

## ローカルフォルダ構成

```
$packageDirectory/
  packageName.wl                          ← パッケージ本体
  packageName_info/
    upload_manifest.json                  ← アップロード対象ファイル・ディレクトリ一覧
    docs/README.md                        ← GitHub トップ README.md に自動同期
  GithubRepositories/
    packageName/                          ← ローカル GitHub 作業フォルダ
    _local_snapshot/packageName/          ← GitHubCommitDataset 起動時スナップショット
    repo_database.json                    ← 日本語パッケージ名 → 英語リポジトリ名 DB