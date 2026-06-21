# GitHubREST` API リファレンス

NBAccess.wl と claudecode.wl と連携する GitHub REST ヘルパー。認証は `NBAccess`NBGetAPIKey["github"]` に委譲。パッケージ名でリモートリポジトリを操作する。多くの関数は第1引数に packageName_String を取り、`$packageDirectory` 内の `.wl`/Paclet を対象とする。日本語パッケージ名は repo_database.json 経由で英語リポジトリ名に解決される。失敗時は `$Failed` または `Failure[...]` を返す。

共通オプション解決規則: `Owner -> Automatic` は認証トークンの所有ユーザー、`Repository -> Automatic` は packageName(RepoDB 解決後)、`BaseBranch -> Automatic` はリポジトリの default branch、`Branch -> Automatic` は BaseBranch。`Fallback -> True` で Claude Code エラー時のフォールバック(リポジトリ名翻訳など)を許可。

## URL 取得
### GitHubPackageURL[packageName, opts]
`$packageDirectory` 内パッケージの GitHub URL を返す
→ String | $Failed
Options: Owner -> Automatic, Repository -> Automatic, Fallback -> False

### GitHubPackageURLs[] → Association
`$packageDirectory` 内の全パッケージの `<|name -> url, ...|>` を返す

## ローカルリポジトリ管理
ローカル作業フォルダは `$packageDirectory/GithubRepositories/<packageName>`。

### GitHubRepoPath[packageName] → String
ローカル GitHub 作業フォルダのパスを返す(作成はしない)

### GitHubEnsureLocalRepo[packageName, opts]
ローカル作業フォルダを作成して返す
→ String(ディレクトリパス)
Options: LocalRepoPath -> Automatic (保存先を明示指定)

### GitHubRefreshLocalPackage[packageName, opts]
`<pkg>.wl` をローカル作業フォルダへコピー(後方互換・単一ファイル用)。グループには GitHubRefreshLocalPackageGroup を使う
→ String(コピー先パス) | Failure
Options: LocalRepoPath -> Automatic, PackageFile -> Automatic (元 .wl パスを明示)

## マニフェスト
upload_manifest.json は `<pkg>_info/upload_manifest.json`。`files`(basename)・`directories`(相対パス)・`excludePatterns` を持つ。

### GitHubReadManifest[packageName] → Association
upload_manifest.json を読む。無ければ自動生成しディスク保存。種別(.wl/Paclet)変化時も自動更新。`<|packageName, files, directories, excludePatterns|>`

### GitHubValidateManifest[packageName] → Association
配布前検査。files の実在、secret/token/credential/.pid/.heartbeat/.log らしきファイル混入、除外パターンを確認
→ `<|Status ("OK"|"Issues"|"Error"), PackageName, FileCount, PresentFileCount, MissingFiles, Directories, ExcludePatterns, Issues|>`

### GitHubRefreshLocalPackageGroup[packageName, opts]
manifest に基づき対象ファイル・ディレクトリをローカル作業フォルダへコピー。`_info/docs/README.md` をトップ README.md として配置
→ Association(リフレッシュ結果)
Options: LocalRepoPath -> Automatic

## リポジトリ作成
### GitHubCreateRepository[packageName, opts]
GitHub 上に新規リポジトリを作成。既定 private。manifest があれば対象ファイル群をまとめて初回コミット。`_info/docs/README.md` をトップ README.md に配置。作成後 API 反映を待機
→ `<|Package, Owner, Repository, DefaultBranch, LocalRepoPath, RefreshResult, Response|>` | Failure
Options: Repository -> Automatic, Public -> False, Description -> "", Homepage -> None, AutoInit -> True, GitignoreTemplate -> None, LicenseTemplate -> None, LocalRepoPath -> Automatic, IncludePackageFile -> True (作成前に manifest ファイルをコピー), PackageFile -> Automatic, ExtraDirectories -> {} (manifest の directories に永続追加), Fallback -> False
例: GitHubCreateRepository["claudecode", Public -> True, ExtraDirectories -> {"Claude Directives"}]

## ファイル読み取り
### GitHubReadFile[packageName, path, opts]
GitHub 上のファイルを読む
→ String | ByteArray | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, ReturnType -> "Text" ("Text"|"ByteArray"|"Bytes"), Fallback -> False

### GitHubReadLocalFile[packageName, path] → String
ローカルファイルを常に UTF-8 でデコードして読む(GitHubReadFile との比較用、日本語環境で文字化けしない)。path 省略時はパッケージの `.wl` を読む

## Pull / Commit / PR
### GitHubPull[packageName, opts]
指定ブランチのリポジトリ内容をローカル作業フォルダへ取得
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, Clean -> False (取得前に既存ローカルファイルを削除)

### GitHubCommit[packageName, message, opts]
ローカル作業フォルダの内容を blob/tree/commit/ref 更新で GitHub の指定ブランチへまとめてコミット
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, CreateBranch -> Automatic (Automatic は Branch =!= BaseBranch なら True), LocalRepoPath -> Automatic, IncludePackageFile -> True, DeleteMissing -> False (ローカルに無いリモート blob を tree から削除), Force -> False (ref 更新で fast-forward 制約を無視), Author -> Automatic (`<|"name"->..,"email"->..|>`), Committer -> Automatic

### GitHubCreatePullRequest[packageName, title, opts]
pull request を作成
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Head -> Automatic (Automatic は Branch), BaseBranch -> Automatic, Body -> "", Draft -> False, MaintainerCanModify -> Automatic

### GitHubRefreshAndCommit[packageName, message, opts]
manifest に基づき対象ファイル群をローカルへコピーし GitHub へコミット。`_info/docs/README.md` 変更時はトップ README.md も自動更新
→ Association | Failure
Options: GitHubCommit 系 + ExtraDirectories -> {}

### GitHubSubmitPullRequest[packageName, title, message]
refresh → branch 作成 → commit → pull request 作成を一括実行
→ Association | Failure

## リポジトリ名 DB
日本語パッケージ名 → 英語リポジトリ名の対応表 (`GithubRepositories/repo_database.json`)。

### GitHubRepoDB[] → Association
全レコードを返す

### GitHubRepoDBSet[packageName, repoName] / GitHubRepoDBSet[packageName, repoName, owner] → String
パッケージ名と GitHub リポジトリ名(任意で owner)の対応を登録。日本語パッケージ名に英語リポジトリ名を割り当てる用途

### GitHubRepoDBLookup[packageName] → String
DB からリポジトリ名を解決。未登録なら packageName をそのまま返す

## インストール / 更新
### GitHubInstallPackage[packageName, opts] / GitHubInstallPackage[packageName, url, opts]
GitHub から `$packageDirectory` へ初回ダウンロード。url 指定で他人のリポジトリからインストール。インストール後は packageName だけで以降の操作が可能。リモート判定により自分/リモート+_info/リモート単純の3パターンでコピー
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, Fallback -> False
例: GitHubInstallPackage["pkg", "https://github.com/user/repo"]

### GitHubUpdatePackage[packageName] → Association | Failure
既存パッケージを GitHub の最新に更新

## プルリクエスト管理
### GitHubListPullRequests[packageName, opts]
オープンな PR 一覧を緊急度(urgent/critical/hotfix < high < 通常 < low)・重要度(breaking/security < bug/fix < feature < 他)でソートして返す
→ List | Failure
Options: Owner -> Automatic, Repository -> Automatic, Fallback -> False

### GitHubPullRequestDataset[packageName, opts]
PR 一覧を Review/Pull/Merge/Close ボタン付き Grid で表示
→ Grid | {} | Failure
Options: Owner -> Automatic, Repository -> Automatic, Fallback -> False

### GitHubMergePullRequest[packageName, prNumber, reason] → Association | Failure
PR をマージ

### GitHubClosePullRequest[packageName, prNumber, reason] → Association | Failure
PR をクローズ

### GitHubReviewPullRequest[packageName, prNumber]
PR のコードをダウンロードし、レビュー用コードをノートブックに出力

## コミット履歴
### GitHubListCommits[packageName, opts]
リポジトリのコミット履歴をリストで返す
→ List | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, MaxItems -> 30, Fallback -> False

### GitHubCommitDataset[packageName, opts]
コミット履歴を Review/Pull/Revert ボタン付き Grid で表示。起動時に現在の作業状態をローカルスナップショットとして保存し、#0 行から復元可能
→ Grid | {} | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, MaxItems -> 30, Fallback -> False

### GitHubReviewCommit[packageName, sha]
指定コミットの詳細・差分をノートブックに表示

### GitHubRevertCommit[packageName, sha] → Association | Failure
指定コミットの変更を元に戻すリバートコミットを作成

## 自動コミット駆動 (旧 PackageAutoCommit)
GitHubRefreshAndCommit の前段。docs 鮮度ゲート → 前回コミット差分 → コミットメッセージ案 → DryRun 既定駆動。

### PackageDocsFreshnessGate[packageName] → Association
`<pkg>_info/docs` 配下の api.md / api_*.md が対応 .wl 以降に更新されているか検査。対応規則: api.md↔`<pkg>.wl`、api_<sfx>.md↔`<pkg>_<sfx>.wl`。1つでも古ければ Proceed -> False。docs 無しは Proceed -> True
→ `<|Status, Package, Proceed, Checked, StaleDocs (各 <|Doc,Wl,DocDate,WlDate|>), DocsDir|>`

### PackageCommitDiff[packageName] → Association
現ソースと前回コミットスナップショット(`GithubRepositories/<pkg>`)を ReadOnly に内容比較。manifest を直接 Import(GitHubReadManifest は呼ばない)。リフレッシュ前に呼ぶこと
→ `<|Status, Package, SnapshotDir, SnapshotExists, Added, Changed, Removed, UnchangedCount, ChangeCount, ChangedDetail, Summary|>`

### PackageCommitPlan[packageName, opts] → Association
鮮度ゲート → 差分 → メッセージ案 を ReadOnly に組み立て(実コミットなし)。docs 古ければ Status -> Blocked、差分無しは Status -> NoChange、両 OK で Status -> OK + CommitMessage
→ `<|Status, Package, Proceed, (StaleDocs | Diff | CommitMessage), ...|>`
Options: "MessageGenerator" -> Automatic (差分からの決定論的単文 | "固定文字列" | fn[diffAssoc]->String), "SkipDocsGate" -> False (True で鮮度ゲート無視、OK 結果に StaleDocs 警告 + DocsGateSkipped)

### PackageCommit[packageName, opts] → Association
メイン駆動関数。PackageCommitPlan 実行後、Status -> OK のとき GitHubRefreshAndCommit を呼ぶ
→ `<|Status (DryRun|Committed|Blocked|NoChange|Failed), Committed, CommitMessage, ...|>`
Options: "DryRun" -> True (既定。実コミットせず計画とメッセージ案を返す), "MessageGenerator" -> Automatic, "SkipDocsGate" -> False (True は DryRun プレビュー専用。実コミット (DryRun -> False) では SkipDocsGate に関わらず docs 古ければ Blocked で停止)
例: PackageCommit["github", "DryRun" -> False, "MessageGenerator" -> PackageLLMMessageGenerator[$iModelSonnet]]

### PackageLLMMessageGenerator[queryFn, opts] → Function
LLM でコミットメッセージを生成する MessageGenerator 関数 (diffAssoc -> String) を返す。PackageCommit/PackageCommitPlan の "MessageGenerator" に渡す。queryFn は prompt->String の関数。モデル指定子(tuple {provider,model} 例 $iModelSonnet、またはモデル名 String)を渡すと `ClaudeCode`ClaudeQueryBg[prompt, Model->spec]` で自動ラップ(要 claudecode)。既定 "IncludeContent"->True は変更行(- 削除/+ 追加、ChangedDetail から計算)をプロンプトに含めるためソース変更行が model に送られる(信頼できる model を使う)。queryFn が String を返さない/空なら決定論メッセージにフォールバック
Options: "MaxChars" -> 80, "IncludeContent" -> True (False でファイル名のみ・低 privacy), "MaxContentChars" -> 4000, "MaxPerFileChars" -> 1500

## 変数
### $GitHubLicenseHolder
型: String, 初期値: ""
MIT ライセンスの著作権者名。空文字列の場合ライセンスセクションは README.md に挿入されない
例: $GitHubLicenseHolder = "Katsunobu Imai"

## オプションシンボル一覧
Owner, Repository, Public, Description, Homepage, AutoInit, GitignoreTemplate, LicenseTemplate, Branch, BaseBranch, CreateBranch, LocalRepoPath, PackageFile, IncludePackageFile, ReturnType, Clean, Force, DeleteMissing, Head, Body, Draft, MaintainerCanModify, Author, Committer, ExtraDirectories, MaxItems