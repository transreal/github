# GitHubREST` — API リファレンス

パッケージ: [github](https://github.com/transreal/github)
依存: [NBAccess](https://github.com/transreal/NBAccess)（API キー取得に使用）

## 関数一覧

### URL / パス解決

| シグネチャ | 戻り値 | 説明 |
|---|---|---|
| `GitHubPackageURL[name]` | `String` | `$packageDirectory` 内パッケージの GitHub URL を返す。オプション: `Owner`, `Repository`, `Fallback` |
| `GitHubPackageURLs[]` | `Association` | 全パッケージの `<\|name -> url\|>` を返す |
| `GitHubRepoPath[name]` | `String` | ローカル作業フォルダのパスを返す (`$packageDirectory/GithubRepositories/name`) |
| `GitHubEnsureLocalRepo[name]` | `String` | ローカル作業フォルダを作成して返す。オプション: `LocalRepoPath` |

### マニフェスト / ローカル同期

| シグネチャ | 戻り値 | 説明 |
|---|---|---|
| `GitHubReadManifest[name]` | `Association` | `_info/upload_manifest.json` を読む。不在時は自動生成。パッケージ種別 (.wl/パクレット) 変更時も自動更新 |
| `GitHubRefreshLocalPackageGroup[name]` | `Association` | マニフェストに従いファイルをローカル作業フォルダへコピー。`_info/docs/README.md` があればトップレベル `README.md` として配置。`_info/originals/` のファイルも元の位置へ書き戻す。オプション: `LocalRepoPath` |
| `GitHubRefreshLocalPackage[name]` | `String` | `name.wl` 単体をローカルへコピー（後方互換用）。オプション: `LocalRepoPath`, `PackageFile` |

### リポジトリ操作

| シグネチャ | 戻り値 | 説明 |
|---|---|---|
| `GitHubCreateRepository[name]` | `Association` | GitHub に新規リポジトリを作成し、`upload_manifest.json` に基づくファイル群をコミットする。戻り値に `"DefaultBranch"`, `"Owner"`, `"Repository"` 等を含む |
| `GitHubReadFile[name, path]` | `String\|ByteArray` | GitHub 上のファイルを読み取る |
| `GitHubPull[name]` | `Association` | リモートの内容をローカル作業フォルダへ取得。戻り値に `"FilesPulled"` を含む |
| `GitHubCommit[name, message]` | `Association` | ローカル作業フォルダの内容を GitHub へ一括コミット。戻り値に `"CommitSHA"`, `"Branch"` 等を含む |
| `GitHubRefreshAndCommit[name, message]` | `Association` | リフレッシュ → コミットを一括実行。戻り値に `"RefreshResult"` と `"CommitSHA"` 等を含む |

### プルリクエスト

| シグネチャ | 戻り値 | 説明 |
|---|---|---|
| `GitHubCreatePullRequest[name, title]` | `Association` | PR を作成する。head と base が同一ブランチの場合はエラーを返す |
| `GitHubSubmitPullRequest[name, title, message]` | `Association` | refresh → branch 作成 → commit → PR 作成を一括実行。ブランチ名は `pr/name/YYYYMMDD-HHmmss-slug` 形式で自動生成 |
| `GitHubListPullRequests[name]` | `List` | オープン PR 一覧を緊急度・重要度・依存関係でソートして返す |
| `GitHubPullRequestDataset[name]` | `Grid` | PR 一覧を Review/Pull/Merge/Close ボタン付き Grid で返す |
| `GitHubMergePullRequest[name, prNumber, reason]` | `Association` | PR をマージする。`reason` は省略可（既定 `""`）。理由はコメントとして残る |
| `GitHubClosePullRequest[name, prNumber, reason]` | `Association` | PR をクローズする。`reason` は省略可（既定 `""`）。理由はコメントとして残る |
| `GitHubReviewPullRequest[name, prNumber]` | `Association` | PR のコード差分をノートブックに CellGroup として出力する。Merge/Close ボタン付き |

### コミット履歴

| シグネチャ | 戻り値 | 説明 |
|---|---|---|
| `GitHubListCommits[name]` | `List` | リポジトリのコミット履歴を取得してリストで返す |
| `GitHubCommitDataset[name]` | — | コミット履歴を Review/Pull/Revert ボタン付き Grid でノートブックに出力する。起動時に現在の作業状態を `GithubRepositories/_local_snapshot/name/` へ SHA-256 ハッシュ付きで自動スナップショット保存する。#0 行（ローカル最新版）の Pull ボタンで復元可能。復元時にスナップショット後の変更を検出し警告を表示する |
| `GitHubReviewCommit[name, sha]` | `Association` | 指定コミットの詳細・差分をノートブックに CellGroup として表示する。Pull/Revert ボタン付き。Pull は `GithubRepositories` と `$packageDirectory` の両方に反映する |
| `GitHubRevertCommit[name, sha, reason]` | `Association` | 指定コミットの親の tree を使いリバートコミットを作成する。`reason` は省略可（既定 `""`） |

### リポジトリ名 DB

| シグネチャ | 戻り値 | 説明 |
|---|---|---|
| `GitHubRepoDB[]` | `Association` | `GithubRepositories/repo_database.json` の全レコードを返す |
| `GitHubRepoDBSet[name, repoName]` | `Association` | パッケージ名 → リポジトリ名の対応を DB に登録する |
| `GitHubRepoDBSet[name, repoName, owner]` | `Association` | パッケージ名 → リポジトリ名 + owner を DB に登録する。`GitHubInstallPackage[name, url]` でインストールした際に自動呼び出される |
| `GitHubRepoDBLookup[name]` | `String` | DB からリポジトリ名を解決（未登録なら `name` をそのまま返す） |

非 ASCII パッケージ名で `Repository -> Automatic` の場合、Claude API (`iTranslateToEnglishRepoName`) を呼び出して意味のある英語リポジトリ名を自動生成し DB に登録する。GitHub 上の重複も自動回避する（候補を3つ生成し、存在しないものを採用。全て存在する場合はサフィックス `-2` 〜 `-20` を試行）。`Fallback -> True` を指定すると Claude Code が利用できない場合に `Transliterate` にフォールバックする。

### パッケージ管理

| シグネチャ | 戻り値 | 説明 |
|---|---|---|
| `GitHubInstallPackage[name]` | `Association` | GitHub から `$packageDirectory` へ初回ダウンロード。自分のリポジトリ（RepoDB に owner 未登録）の場合は全ファイルをそのままコピー |
| `GitHubInstallPackage[name, url]` | `Association` | 他人のリポジトリ URL からインストール。URL をパースして owner/repo を RepoDB に登録し、以降は `name` だけで操作できる。非 `.wl` ファイルは `name_info/originals/` に振り分けられ、コミット時に元の位置へ書き戻される |
| `GitHubUpdatePackage[name]` | `Association` | 既存パッケージを GitHub 最新版に更新（内部的に `GitHubInstallPackage` と同一） |

`GitHubInstallPackage` のコピー先振り分けルール:
- **パターン A（自分のリポジトリ）**: RepoDB に `owner` が未登録。全ファイル・全フォルダを `$packageDirectory` へそのままコピー。`excludePatterns` に該当する既存ファイルは保護
- **パターン B（リモート + `_info` フォルダあり）**: `README.md` をスキップし、それ以外を `$packageDirectory` へコピー。`excludePatterns` に該当する既存ファイルは保護
- **パターン C（リモート + `_info` フォルダなし）**: `.wl` は `$packageDirectory` へ直接コピー、その他は `name_info/originals/` へ格納し `doc_options.json` にマッピングを保存

### グローバル変数

| シグネチャ | 型 | 説明 |
|---|---|---|
| `$GitHubLicenseHolder` | `String` | MIT ライセンスの著作権者名。空文字列 `""` の場合は README.md にライセンスセクションを挿入しない。例: `$GitHubLicenseHolder = "Katsunobu Imai"` |

## オプション一覧

### リポジトリ識別

| オプション | 既定値 | 対象関数 | 説明 |
|---|---|---|---|
| `Owner` | `Automatic` | `GitHubCreateRepository` 以外の全公開関数 | GitHub オーナー名。Automatic → RepoDB に owner 登録があればそちらを優先、なければトークンから自動取得 |
| `Repository` | `Automatic` | 全般 | リポジトリ名。Automatic → DB に英語名があればそちらを使用、なければ `packageName`。非 ASCII 名は自動翻訳 |
| `Branch` | `Automatic` | Commit/Pull/PR/Revert/ListCommits/CommitDataset/Install/Update | 操作対象ブランチ。Automatic → `BaseBranch` と同じ |
| `BaseBranch` | `Automatic` | Commit/Pull/PR/Revert/ListCommits/CommitDataset/Install/Update | ベースブランチ。Automatic → リポジトリの default branch を API から自動取得 |
| `MaxItems` | `30` | `GitHubListCommits` / `GitHubCommitDataset` | 取得するコミット数の上限（最大 100） |

### リポジトリ作成

| オプション | 既定値 | 説明 |
|---|---|---|
| `Public` | `False` | `True` にすると公開リポジトリを作成 |
| `Description` | `""` | リポジトリの説明文 |
| `Homepage` | `None` | ホームページ URL |
| `AutoInit` | `True` | README 付きで初期化するか |
| `GitignoreTemplate` | `None` | GitHub の gitignore テンプレート名 |
| `LicenseTemplate` | `None` | GitHub の license テンプレート名 |

### コミット制御

| オプション | 既定値 | 対象関数 | 説明 |
|---|---|---|---|
| `CreateBranch` | `Automatic` | `GitHubCommit` / `GitHubRefreshAndCommit` | ブランチ不在時に `BaseBranch` から作成するか。Automatic → `Branch ≠ BaseBranch` なら True |
| `Force` | `False` | `GitHubCommit` / `GitHubRefreshAndCommit` | ref 更新時に fast-forward 制約を無視するか |
| `DeleteMissing` | `False` | `GitHubCommit` / `GitHubRefreshAndCommit` / `GitHubSubmitPullRequest` | ローカルに無いリモート blob を削除するか |
| `Author` | `Automatic` | `GitHubCommit` / `GitHubRefreshAndCommit` / `GitHubSubmitPullRequest` | コミット author `<\|"name"->…, "email"->…\|>` |
| `Committer` | `Automatic` | `GitHubCommit` / `GitHubRefreshAndCommit` / `GitHubSubmitPullRequest` | コミット committer |
| `ExtraDirectories` | `{}` | `GitHubCreateRepository` / `GitHubRefreshAndCommit` | `upload_manifest.json` の `directories` に永続追加するディレクトリのリスト。例: `ExtraDirectories -> {"Claude Directives"}` |

### ローカルパス / ファイル

| オプション | 既定値 | 対象関数 | 説明 |
|---|---|---|---|
| `LocalRepoPath` | `Automatic` | `GitHubEnsureLocalRepo` / `GitHubRefreshLocalPackageGroup` / `GitHubRefreshLocalPackage` / `GitHubCreateRepository` / `GitHubCommit` / `GitHubRefreshAndCommit` / `GitHubSubmitPullRequest` / `GitHubPull` | ローカル作業フォルダのパスを明示指定 |
| `PackageFile` | `Automatic` | `GitHubRefreshLocalPackage` / `GitHubCreateRepository` / `GitHubCommit` | `packageName.wl` のパスを明示指定 |
| `IncludePackageFile` | `True` | `GitHubCommit` / `GitHubCreateRepository` | コミット前にマニフェストに基づくグループリフレッシュを実行するか |
| `Clean` | `False` | `GitHubPull` | Pull 前に既存ローカルファイルを削除するか |

### ファイル読み取り / PR

| オプション | 既定値 | 対象関数 | 説明 |
|---|---|---|---|
| `ReturnType` | `"Text"` | `GitHubReadFile` | `"Text"` / `"ByteArray"` / `"Bytes"` |
| `Head` | `Automatic` | `GitHubCreatePullRequest` | PR の head ブランチ。Automatic → `Branch` |
| `Body` | `""` | `GitHubCreatePullRequest` / `GitHubSubmitPullRequest` | PR 本文 |
| `Draft` | `False` | `GitHubCreatePullRequest` / `GitHubSubmitPullRequest` | ドラフト PR として作成するか |
| `MaintainerCanModify` | `True` | `GitHubCreatePullRequest` / `GitHubSubmitPullRequest` | maintainer による head 編集を許可するか |

### エラーハンドリング / フォールバック

| オプション | 既定値 | 対象関数 | 説明 |
|---|---|---|---|
| `Fallback` | `False` | 全公開関数 | `True` にすると Claude Code が利用不可の場合にフォールバック処理を有効化する。リポジトリ名の自動翻訳（非 ASCII パッケージ名）等で Claude API を呼ぶ際に、代替モデルや `Transliterate` へのフォールバックを許可する。`False`（既定）の場合は API エラー時に `Failure` を返して処理を停止する |

## 内部実装メモ

ファイルパス操作は `FileNameSplit` / `FileNameJoin` を使用し、OS 依存の `$PathnameSeparator` や `"\\"` による文字列置換を行わない。Git パス（スラッシュ区切り）への変換は `iNormalizeGitPath` が `FileNameSplit` + `"/"` 結合で処理する。これにより Windows / macOS / Linux 間でのパス不整合を防止している。

JSON 出力では `iForceASCIIJSON` により非 ASCII 文字を `\uXXXX` エスケープに変換し、Windows 環境の ShiftJIS エンコーディング問題を回避している。`iEncodeJSONBody` は `ExportString[..., "RawJSON"]` の出力を検査し、UTF-8 バイト列として再デコードしてから `\uXXXX` エスケープを適用する。

ボタン評価の二重実行防止には `$iGitHubEvalGuard` を使用し、`WithCleanup` で確実にガードを解除する。

ローカルスナップショットは `GithubRepositories/_local_snapshot/name/` に保存され、各ファイルの SHA-256 ハッシュを `_snapshot_hashes.json` に記録する。`GitHubCommitDataset` の #0 行から復元する際、スナップショット時点からの変更を検出し、変更ファイルがあれば上書き前に警告を表示する。