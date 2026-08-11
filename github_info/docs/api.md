# GitHubREST` API リファレンス

NBAccess.wl と claudecode.wl と連携する GitHub REST ヘルパー。認証は `NBAccess`NBGetAPIKey["github"]` に委譲。パッケージ名でリモートリポジトリを操作する。多くの関数は第1引数に packageName_String を取り、`$packageDirectory` 内の `.wl`/Paclet を対象とする。日本語パッケージ名は repo_database.json 経由で英語リポジトリ名に解決される。失敗時は `$Failed` または `Failure[...]` を返す。

共通オプション解決規則: `Owner -> Automatic` は認証トークンの所有ユーザー、`Repository -> Automatic` は packageName(RepoDB 解決後)、`BaseBranch -> Automatic` はリポジトリの default branch、`Branch -> Automatic` は BaseBranch。`Fallback -> True` で Claude Code エラー時のフォールバック(リポジトリ名翻訳など)を許可。ほぼ全公開関数に `Fallback -> False` オプションがある。

非公開コード関所: ファイル先頭付近(4096バイト以内)の機械可読マーカー `(* :CodePrivacyLevel: 0.1 *)`(.md は `<!-- :CodePrivacyLevel: x -->`)で「ソースコード自体が非公開」を宣言できる(0 または無印 = 公開可)。manifest 対象(files + directories 配下の .wl/.m/.wls/.md/.txt)に CodePrivacyLevel > 0 のファイルが含まれると、GitHubRefreshLocalPackageGroup / GitHubRefreshAndCommit / GitHubCreateRepository の内部リフレッシュ処理は何もコピーせず `Failure["PrivateCodeBlocked", ...]` を返し fail-closed で遮断する(部分反映を作らない)。GitHubValidateManifest でも同じ違反を事前検出できる。

Markdown 先頭 `---` ガード: ミラーリフレッシュ時、すべての `.md` ファイルに対し先頭の独立した `---` 行(YAML front matter でないもの)を自動除去する。GitHub はこれを front matter としてパースし本文全体が消えるため。閉じ `---` と `key: value` 行を持つ本物の front matter(Claude Directives の rules/*.md / SKILL.md など)はそのまま通過する。

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
Options: LocalRepoPath -> Automatic, PackageFile -> Automatic (元 .wl パスを明示指定)

## マニフェスト
upload_manifest.json は `<pkg>_info/upload_manifest.json`。`files`(basename)・`directories`(相対パス)・`excludePatterns` を持つ。

### GitHubReadManifest[packageName] → Association
upload_manifest.json を読む。無ければ自動生成しディスク保存。種別(.wl/Paclet)変化時も自動更新。`<|packageName, files, directories, excludePatterns|>`

### GitHubValidateManifest[packageName] → Association
配布前検査。files の実在、secret/token/credential/.pid/.heartbeat/.log らしきファイル混入、除外パターン、非公開コード(CodePrivacyLevel > 0)混入を確認
→ `<|Status ("OK"|"Issues"|"Error"), PackageName, FileCount, PresentFileCount, MissingFiles, Directories, ExcludePatterns, Issues|>`
Issues の Issue 種別: "MissingFiles", "SuspectSecretFiles", "PrivateCodeFiles"(CodePrivacyLevel > 0。upload_manifest.json から外すこと)

### GitHubRefreshLocalPackageGroup[packageName, opts]
manifest に基づき対象ファイル・ディレクトリをローカル作業フォルダへコピー。`_info/docs/README.md` をトップ README.md として配置。コピー後すべての `.md` ファイルの先頭偽 front matter `---` を自動除去(本物の front matter は保持)。CodePrivacyLevel > 0 のファイルが manifest 対象に含まれる場合は何もコピーせず `Failure["PrivateCodeBlocked", ...]` を返す
→ Association(リフレッシュ結果) | Failure
Options: LocalRepoPath -> Automatic

## リポジトリ作成
### GitHubCreateRepository[packageName, opts]
GitHub 上に新規リポジトリを作成。既定 private。manifest があれば対象ファイル群をまとめて初回コミット(非公開コード関所は GitHubRefreshLocalPackageGroup と同様に適用)。`_info/docs/README.md` をトップ README.md に配置。作成後 API 反映を待機
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
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, LocalRepoPath -> Automatic, Clean -> False (取得前に既存ローカルファイルを削除), Fallback -> False

### GitHubCommit[packageName, message, opts]
ローカル作業フォルダの内容を blob/tree/commit/ref 更新で GitHub の指定ブランチへまとめてコミット
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, CreateBranch -> Automatic (Automatic は Branch =!= BaseBranch なら True), LocalRepoPath -> Automatic, IncludePackageFile -> True, PackageFile -> Automatic, DeleteMissing -> False (ローカルに無いリモート blob を tree から削除), Force -> False (ref 更新で fast-forward 制約を無視), Author -> Automatic (`<|"name"->..,"email"->..|>`), Committer -> Automatic, Fallback -> False

### GitHubCreatePullRequest[packageName, title, opts]
pull request を作成
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, Head -> Automatic (Automatic は Branch), BaseBranch -> Automatic, Body -> "", Draft -> False, MaintainerCanModify -> True, Fallback -> False

### GitHubRefreshAndCommit[packageName, message, opts]
manifest に基づき対象ファイル群をローカルへコピーし GitHub へコミット。コピー時に `.md` ファイルの先頭偽 front matter `---` を自動除去。`_info/docs/README.md` 変更時はトップ README.md も自動更新。CodePrivacyLevel > 0 のファイルが manifest 対象に含まれる場合はコピー・コミットとも行わず `Failure["PrivateCodeBlocked", ...]` を返す。コミット失敗時はローカルミラー(GithubRepositories/<pkg>)を refresh 前の状態へ自動ロールバックする(次回の差分計算が前回コミット基準からずれないように)
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, CreateBranch -> Automatic, LocalRepoPath -> Automatic, DeleteMissing -> False, Force -> False, Author -> Automatic, Committer -> Automatic, ExtraDirectories -> {}, Fallback -> False

### GitHubSubmitPullRequest[packageName, title, message, opts]
refresh → branch 作成 → commit → pull request 作成を一括実行
→ Association | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, LocalRepoPath -> Automatic, DeleteMissing -> False, Force -> False, Author -> Automatic, Committer -> Automatic, Body -> "", Draft -> False, MaintainerCanModify -> True, Fallback -> False

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

### GitHubUpdatePackage[packageName, opts] → Association | Failure
既存パッケージを GitHub の最新に更新。実体は GitHubInstallPackage への委譲
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, Fallback -> False

## プルリクエスト管理
### GitHubListPullRequests[packageName, opts]
オープンな PR 一覧を緊急度(urgent/critical/hotfix < high < 通常 < low)・重要度(breaking/security < bug/fix < feature < 他)でソートして返す
→ List | Failure
Options: Owner -> Automatic, Repository -> Automatic, Fallback -> False

### GitHubPullRequestDataset[packageName, opts]
PR 一覧を Review/Pull/Merge/Close ボタン付き Grid で表示
→ Grid | {} | Failure
Options: Owner -> Automatic, Repository -> Automatic, Fallback -> False

### GitHubMergePullRequest[packageName, prNumber, reason, opts] → Association | Failure
PR をマージ
Options: Owner -> Automatic, Repository -> Automatic, Fallback -> False

### GitHubClosePullRequest[packageName, prNumber, reason, opts] → Association | Failure
PR をクローズ
Options: Owner -> Automatic, Repository -> Automatic, Fallback -> False

### GitHubReviewPullRequest[packageName, prNumber, opts]
PR のコードをダウンロードし、レビュー用コードをノートブックに出力
Options: Owner -> Automatic, Repository -> Automatic, Fallback -> False

## コミット履歴
### GitHubCommitLog[packageName, opts]
コミット履歴を日付範囲付きで取得しコンパクト形式で返す。読み取り専用・リポジトリ無変更のため**承認不要 (AutoPermit)**。「いつ何が追加/変更されたか」「6/20 以降の変更は?」のような更新履歴・changelog の質問はまずこれを使う (GithubRepositories/ は .git を持たないミラーなので、git log の代わりに常にこの関数を使う)。`"Since"`/`"Until"` の日付は `TimeZoneConvert` で正確に UTC 変換する(JST 環境で mtime ずれを起こす旧実装バグ修正済み)
→ {<|"SHA", "Date" (DateObject), "Author", "Message"|>..} | Failure
Options: MaxItems -> 50, "Since" -> None ("2026-06-20" 形式文字列 or DateObject), "Until" -> None, Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, Fallback -> False
例: GitHubCommitLog["SourceVault", "Since" -> "2026-06-20"]

### GitHubListCommits[packageName, opts]
リポジトリのコミット履歴を GitHub API の生レスポンスのまま返す (読み取り専用・承認不要)
→ List | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, MaxItems -> 30, Fallback -> False

### GitHubCommitDataset[packageName, opts]
コミット履歴を Review/Pull/Revert ボタン付き Grid で表示。起動時に現在の作業状態をローカルスナップショットとして保存し、#0 行から復元可能
→ Grid | {} | Failure
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, MaxItems -> 30, Fallback -> False

### GitHubReviewCommit[packageName, sha, opts]
指定コミットの詳細・差分をノートブックに表示
Options: Owner -> Automatic, Repository -> Automatic, Fallback -> False

### GitHubRevertCommit[packageName, sha, reason, opts] → Association | Failure
指定コミットの変更を元に戻すリバートコミットを作成
Options: Owner -> Automatic, Repository -> Automatic, Branch -> Automatic, BaseBranch -> Automatic, Fallback -> False

## GitHub Issues API (読み取り専用)
すべて GET のみでリポジトリを一切変更しない読み取り専用操作。SourceVault の汎用イシューDB取込 (SourceVaultIssueIngestGitHub) の供給元。GitHubIssueAddComment のみ書き込みのため承認ゲート対象。GitHub API は PR も issues エンドポイントで返すため、正規化 issue には `"IsPullRequest"` を保持する。

### GitHubListIssues[packageName, opts]
リポジトリの Issue を取得し正規化リストで返す
→ {<|"Package", "Owner", "Repository", "Number", "Title", "Body", "State", "Labels", "Author", "AuthorAssociation", "CreatedAt", "UpdatedAt", "CommentCount", "URL", "IsPullRequest"|>..} | Failure
Options: Owner -> Automatic, Repository -> Automatic, MaxItems -> 50, "State" -> "open", "IncludePullRequests" -> False (既定で PR を除外)
例: GitHubListIssues["claudecode"]

### GitHubIssueGet[packageName, number, opts] → Association | Failure
指定番号の Issue 1 件を正規化 Association で返す
Options: Owner -> Automatic, Repository -> Automatic

### GitHubIssueComments[packageName, number, opts]
Issue のコメント一覧を返す
→ {<|"Author", "AuthorAssociation", "Body", "CreatedAt", "URL"|>..} | Failure
Options: Owner -> Automatic, Repository -> Automatic, MaxItems -> 50

### GitHubIssueAuthorProfile[login] → Association | Failure
GitHub ユーザーの公開プロファイルを返す。Issue 作成者の信頼度推定(アカウント年齢・フォロワー数など)に使う
→ `<|"Login", "Name", "CreatedAt", "Followers", "Following", "PublicRepos", "Bio", "Company", "HTMLURL"|>`

### GitHubManagedRepositories[] → List
github.wl 管理下のリポジトリ一覧を返す。`GithubRepositories/` ミラーフォルダと repo_database.json の和集合。ローカル情報のみでネットワークに触れない
→ {<|"Package", "Repository", "Owner"|>..} (Owner は DB 登録があればその値、無ければ Automatic)

### GitHubAllOpenIssues[opts] → Association
管理下全リポジトリの Open Issue を集約。リポジトリ単位で fail-soft(未作成リポジトリ等はスキップし Errors に記録)。SourceVault の汎用イシューDB取込の供給元
→ `<|"Issues" -> {正規化 issue..}, "RepoCount", "Errors" -> {<|"Package", "Failure"|>..}|>`
Options: MaxItems -> 50 (リポジトリ毎), "IncludePullRequests" -> False

### GitHubIssueAddComment[packageName, number, body, opts] → Association | Failure
Issue へコメントを投稿する。公開リポジトリへの書き込みのため承認ゲート対象(trusted head 非登録)。呼び出し側で内容の秘匿情報(ローカルパス等)を除去してから渡すこと。SourceVaultIssueNotifyGitHub (解決通知) の送信層
Options: Owner -> Automatic, Repository -> Automatic

## GitHub 稼働状況
### GitHubServiceStatus[] / GitHubServiceStatus[key]
GitHub 稼働状況 (githubstatus.com の公開 Statuspage API、認証不要・GitHub API トークン不使用) を取得する。5xx でコミットが失敗したとき、コード側の不具合か GitHub 側の障害かを切り分けるために使う。読み取り専用でリポジトリは変更しない。key 指定時は該当キーのみ返す
→ `<|"Healthy", "Indicator", "Description", "CommitAffected", "Components", "Degraded", "Incidents", "CheckedAt"|>` | 単一値 | Failure
Options: "Timeout" -> 20
例: GitHubServiceStatus["CommitAffected"] (PackageCommit / GitHubCommit が依存する "API Requests"・"Git Operations" のいずれかが operational でないとき True)

## 自動コミット駆動 (旧 PackageAutoCommit)
GitHubRefreshAndCommit の前段。docs 鮮度ゲート → 前回コミット差分 → コミットメッセージ案 → DryRun 既定駆動。

### PackageDocsFreshnessGate[packageName] → Association
`<pkg>_info/docs` 配下の api.md / api_*.md が対応 .wl 以降に更新されているか検査。対応規則: api.md↔`<pkg>.wl`、api_<sfx>.md↔`<pkg>_<sfx>.wl`。補助ソース(.wl)の内容ハッシュが `.aux_source_hashes.json` に記録済みの場合は内容基準で判定(Dropbox 同期等による mtime 揺れを無視)し、未記録時のみ mtime にフォールバック。1つでも古ければ Proceed -> False。docs 無しは Proceed -> True
→ `<|Status, Package, Proceed, Checked, StaleDocs (各 <|Doc,Wl,DocDate,WlDate|>), DocsDir|>`

### PackageCommitDiff[packageName] → Association
現ソースと前回コミットスナップショット(`GithubRepositories/<pkg>`)を ReadOnly に内容比較。manifest を直接 Import(GitHubReadManifest は呼ばない)。リフレッシュ前に呼ぶこと
→ `<|Status, Package, SnapshotDir, SnapshotExists, Added, Changed, Removed, UnchangedCount, ChangeCount, ChangedDetail, Summary|>`

### PackageCommitPlan[packageName, opts] → Association
鮮度ゲート → 差分 → メッセージ案 を ReadOnly に組み立て(実コミットなし)。docs 古ければ Status -> Blocked、差分無しは Status -> NoChange、README の「## 謝辞」節が前回コミットから消える場合も既定で Status -> Blocked(AllowAckRemoval で解除可)、すべて OK で Status -> OK + CommitMessage
→ `<|Status, Package, Proceed, (StaleDocs | AckLossFiles | Diff | CommitMessage), ...|>`
Options: "MessageGenerator" -> Automatic (Automatic は $PackageCommitModel で分岐。固定文字列 | fn[diffAssoc]->String も可), "SkipDocsGate" -> False (True で鮮度ゲート無視、OK 結果に StaleDocs 警告 + DocsGateSkipped), "AllowAckRemoval" -> False (True で README の「## 謝辞」節消失によるブロックを解除)

### PackageCommit[packageName, opts] → Association
メイン駆動関数。PackageCommitPlan 実行後、Status -> OK のとき GitHubRefreshAndCommit を呼ぶ
→ `<|Status (DryRun|Committed|Blocked|NoChange|Failed), Committed, CommitMessage, ...|>`
Options: "DryRun" -> True (既定。実コミットせず計画とメッセージ案を返す), "MessageGenerator" -> Automatic, "SkipDocsGate" -> False (True は DryRun プレビュー専用。実コミット (DryRun -> False) では SkipDocsGate に関わらず docs 古ければ Blocked で停止), "DeleteMissing" -> False (True で GitHubRefreshAndCommit へ転送しリモート残骸を削除。実行前に PackageCommitDeletionPreview で削除候補を必ず確認すること), "AllowAckRemoval" -> False (README の「## 謝辞」節が消えるコミットは既定で Blocked。意図的削除時のみ True)
例: PackageCommit["github", "DryRun" -> False, "MessageGenerator" -> PackageLLMMessageGenerator[$iModelSonnet]]

### PackageCommitDeletionPreview[packageName] → Association
PackageCommit[..., "DeleteMissing" -> True] で削除されるリモートファイル(リモート tree にあってローカルミラーに無い blob)を実行せずに列挙する読み取り専用プレビュー。DeleteMissing -> True の前に必ず実行して確認すること
→ `<|"WouldDelete" -> {path..}, "RemoteCount", "LocalCount"|>`

### PackageLLMMessageGenerator[queryFn, opts] → Function
LLM でコミットメッセージを生成する MessageGenerator 関数 (diffAssoc -> String) を返す。PackageCommit/PackageCommitPlan の "MessageGenerator" に渡す。queryFn は prompt->String の関数。モデル指定子(tuple {provider,model} 例 $iModelSonnet、またはモデル名 String)を渡すと `ClaudeCode`ClaudeQueryBg[prompt, Model->spec]` で自動ラップ(要 claudecode)。既定 "IncludeContent"->True は変更行(- 削除/+ 追加、ChangedDetail から計算)をプロンプトに含めるためソース変更行が model に送られる(信頼できる model を使う)。queryFn が String を返さない/空なら決定論メッセージにフォールバック
Options: "MaxChars" -> 80, "IncludeContent" -> True (False でファイル名のみ・低 privacy), "MaxContentChars" -> 4000, "MaxPerFileChars" -> 1500

## 変数
### $GitHubLicenseHolder
型: String, 初期値: ""
MIT ライセンスの著作権者名。空文字列の場合ライセンスセクションは README.md に挿入されない
例: $GitHubLicenseHolder = "Katsunobu Imai"

### $PackageCommitModel
型: Automatic | None | モデル指定子({provider,model} 例 $iModelSonnet、またはモデル名 String) | (prompt->String 関数), 初期値: Automatic
PackageCommit / PackageCommitPlan の既定コミットメッセージモデル。既定 Automatic では claudecode がロード済みなら周囲の既定モデルで差分内容を要約した LLM メッセージを生成し、未ロード/失敗時は決定論的なファイル名列挙にフォールバックする。特定モデルを使うにはモデル指定子か prompt->文字列 関数を代入する。None を代入すると LLM を呼ばず決定論メッセージに固定する。再ロードで値を保持する
例: $PackageCommitModel = $iModelSonnet; PackageCommit["claudecode", "DryRun" -> True]["CommitMessage"]

## オプションシンボル一覧
Owner, Repository, Public, Description, Homepage, AutoInit, GitignoreTemplate, LicenseTemplate, Branch, BaseBranch, CreateBranch, LocalRepoPath, PackageFile, IncludePackageFile, ReturnType, Clean, Force, DeleteMissing, Head, Body, Draft, MaintainerCanModify, Author, Committer, ExtraDirectories, MaxItems, Fallback