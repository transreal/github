# GitHubREST` — API リファレンス

パッケージ: [github](https://github.com/transreal/github)  
依存: [NBAccess](https://github.com/transreal/NBAccess)（API キー取得に使用）

## 関数一覧

### URL / パス解決

| シグネチャ | 戻り値 | 説明 |
|---|---|---|
| `GitHubPackageURL[name]` | `String` | `$packageDirectory` 内パッケージの GitHub URL を返す |
| `GitHubPackageURLs[]` | `Association` | 全パッケージの `<\|name -> url\|>` を返す |
| `GitHubRepoPath[name]` | `String` | ローカル作業フォルダのパスを返す (`$packageDirectory/GithubRepositories/name`) |
| `GitHubEnsureLocalRepo[name]` | `String` | ローカル作業フォルダを作成して返す |

### マニフェスト / ローカル同期

| シグネチャ | 戻り値 | 説明 |
|---|---|---|
| `GitHubReadManifest[name]` | `Association` | `_info/upload_manifest.json` を読む。不在時は自動生成 |
| `GitHubRefreshLocalPackageGroup[name]` | — | マニフェストに従いファイルをローカル作業フォルダへコピー |
| `GitHubRefreshLocalPackage[name]` | — | `name.wl` 単体をローカルへコピー（後方互換用） |

### リポジトリ操作

| シグネチャ | 戻り値 | 説明 |
|---|---|---|
| `GitHubCreateRepository[name]` | `String` | GitHub に新規リポジトリを作成し、default branch を返す |
| `GitHubReadFile[name, path]` | `String\|ByteArray` | GitHub 上のファイルを読み取る |
| `GitHubPull[name]` | — | リモートの内容をローカル作業フォルダへ取得 |
| `GitHubCommit[name, message]` | — | ローカル作業フォルダの内容を GitHub へ一括コミット |
| `GitHubRefreshAndCommit[name, message]` | — | リフレッシュ → コミットを一括実行 |

### プルリクエスト

| シグネチャ | 戻り値 | 説明 |
|---|---|---|
| `GitHubCreatePullRequest[name, title]` | `Association` | PR を作成する |
| `GitHubSubmitPullRequest[name, title, message]` | — | refresh → branch 作成 → commit → PR 作成を一括実行 |
| `GitHubListPullRequests[name]` | `List` | オープン PR 一覧を優先度・依存関係でソートして返す |
| `GitHubPullRequestDataset[name]` | `Grid` | PR 一覧を Review/Pull/Merge/Close ボタン付き Grid で返す |
| `GitHubMergePullRequest[name, prNumber, reason]` | — | PR をマージする |
| `GitHubClosePullRequest[name, prNumber, reason]` | — | PR をクローズする |
| `GitHubReviewPullRequest[name, prNumber]` | — | PR のコードをダウンロードしてノートブックに出力する |

### コミット履歴

| シグネチャ | 戻り値 | 説明 |
|---|---|---|
| `GitHubListCommits[name]` | `List` | リポジトリのコミット履歴を取得してリストで返す。オプション: `Owner`, `Repository`, `Branch`, `MaxItems` |
| `GitHubCommitDataset[name]` | — | コミット履歴を Review/Pull/Revert ボタン付き Grid でノートブックに出力する。起動時に現在の作業状態を `GithubRepositories/_local_snapshot/name/` へ自動スナップショット保存し、#0 行（ローカル最新版）の Pull ボタンで復元できる |
| `GitHubReviewCommit[name, sha]` | `Association` | 指定コミットの詳細・差分をノートブックに表示する。Pull/Revert ボタン付き |
| `GitHubRevertCommit[name, sha, reason]` | `Association` | 指定コミットの親の tree を使いリバートコミットを作成する |

### リポジトリ名 DB

| シグネチャ | 戻り値 | 説明 |
|---|---|---|
| `GitHubRepoDB[]` | `Association` | `repo_database.json` の全レコードを返す |
| `GitHubRepoDBSet[name, repoName]` | — | パッケージ名 → リポジトリ名の対応を DB に登録する |
| `GitHubRepoDBSet[name, repoName, owner]` | — | パッケージ名 → リポジトリ名 + owner を DB に登録する。他人のリポジトリを `GitHubInstallPackage[name, url]` でインストールした際に自動呼び出される |
| `GitHubRepoDBLookup[name]` | `String` | DB からリポジトリ名を解決（未登録なら `name` をそのまま返す） |

非 ASCII パッケージ名で `Repository -> Automatic` の場合、Claude API (`iTranslateToEnglishRepoName`) を呼び出して意味のある英語リポジトリ名を自動生成し DB に登録する。GitHub 上の重複も自動回避する。`Fallback -> True` を指定すると Claude Code が利用できない場合に `Transliterate` にフォールバックする。

### パッケージ管理

| シグネチャ | 戻り値 | 説明 |
|---|---|---|
| `GitHubInstallPackage[name]` | — | GitHub から `$packageDirectory` へ初回ダウンロード。自分のリポジトリ（RepoDB に owner 未登録）の場合は全ファイルをそのままコピー |
| `GitHubInstallPackage[name, url]` | — | 他人のリポジトリ URL からインストール。URL をパースして owner/repo を RepoDB に登録し、以降は `name` だけで操作できる。非 `.wl` ファイルは `name_info/originals/` に振り分けられ、コミット時に元の位置へ書き戻される |
| `GitHubUpdatePackage[name]` | — | 既存パッケージを GitHub 最新版に更新 |

`GitHubInstallPackage` のコピー先振り分けルール:
- **パターン A（自分のリポジトリ）**: 全ファイル・全フォルダを `$packageDirectory` へそのままコピー
- **パターン B（リモート + `_info` フォルダあり）**: `README.md` をスキップし、それ以外を `$packageDirectory` へコピー
- **パターン C（リモート + `_info` フォルダなし）**: `.wl` は `$packageDirectory` へ直接コピー、その他は `name_info/originals/` へ格納し `doc_options.json` にマッピングを保存

### グローバル変数

| シグネチャ | 型 | 説明 |
|---|---|---|
| `$GitHubLicenseHolder` | `String` | MIT ライセンスの著作権者名。空文字列 `""` の場合は README.md にライセンスセクションを挿入しない。例: `$GitHubLicenseHolder = "Katsunobu Imai"` |

## オプション一覧

### リポジトリ識別

| オプション | 既定値 | 対象関数 | 説明 |
|---|---|---|---|
| `Owner` | `Automatic` | 全般 | GitHub オーナー名（Automatic → RepoDB に登録があればそちらを優先、なければトークンから自動取得） |
| `Repository` | `Automatic` | 全般 | リポジトリ名（Automatic → `packageName` または DB を使用） |
| `Branch` | `Automatic` | Commit/Pull/PR/Revert | 操作対象ブランチ |
| `BaseBranch` | `Automatic` | Commit/PR/Revert | ベースブランチ（Automatic → default branch） |
| `MaxItems` | `30` | `GitHubListCommits` / `GitHubCommitDataset` | 取得するコミット数の上限 |

### リポジトリ作成

| オプション | 既定値 | 説明 |
|---|---|---|
| `Public` | `False` | `True` にすると公開リポジトリを作成 |
| `Description` | `""` | リポジトリの説明文 |
| `Homepage` | `""` | ホームページ URL |
| `AutoInit` | `True` | README 付きで初期化するか |
| `GitignoreTemplate` | `None` | GitHub の gitignore テンプレート名 |
| `LicenseTemplate` | `None` | GitHub の license テンプレート名 |

### コミット制御

| オプション | 既定値 | 説明 |
|---|---|---|
| `CreateBranch` | `Automatic` | ブランチ不在時に `BaseBranch` から作成するか |
| `Force` | `False` | ref 更新時に fast-forward 制約を無視するか |
| `DeleteMissing` | `False` | ローカルに無いリモート blob を削除するか |
| `Author` | `Automatic` | コミット author `<\|"name"->…, "email"->…\|>` |
| `Committer` | `Automatic` | コミット committer |
| `ExtraDirectories` | `{}` | `GitHubCreateRepository` / `GitHubRefreshAndCommit` で `upload_manifest.json` の `directories` に永続追加するディレクトリのリスト。例: `ExtraDirectories -> {"Claude Directives"}` |

### ローカルパス / ファイル

| オプション | 既定値 | 説明 |
|---|---|---|
| `LocalRepoPath` | `Automatic` | ローカル作業フォルダのパスを明示指定 |
| `PackageFile` | `Automatic` | `packageName.wl` のパスを明示指定 |
| `IncludePackageFile` | `True` | コミット前に `.wl` をローカルへコピーするか |
| `Clean` | `False` | Pull 前に既存ローカルファイルを削除するか |

### ファイル読み取り / PR

| オプション | 既定値 | 対象関数 | 説明 |
|---|---|---|---|
| `ReturnType` | `"Text"` | `GitHubReadFile` | `"Text"` / `"ByteArray"` / `"Bytes"` |
| `Head` | `Automatic` | `GitHubCreatePullRequest` | PR の head ブランチ（Automatic → `Branch`） |
| `Body` | `""` | `GitHubCreatePullRequest` | PR 本文 |
| `Draft` | `False` | `GitHubCreatePullRequest` | ドラフト PR として作成するか |
| `MaintainerCanModify` | `True` | `GitHubCreatePullRequest` | maintainer による head 編集を許可するか |

### エラーハンドリング / フォールバック

| オプション | 既定値 | 対象関数 | 説明 |
|---|---|---|---|
| `Fallback` | `False` | 全公開関数 | `True` にすると Claude Code が利用不可の場合にフォールバック処理を有効化する。リポジトリ名の自動翻訳（非 ASCII パッケージ名）等で Claude API を呼ぶ際に、代替モデルや `Transliterate` へのフォールバックを許可する。`False`（既定）の場合は API エラー時に `Failure` を返して処理を停止する |

## 内部実装メモ（パス操作）

ファイルパス操作は `FileNameSplit` / `FileNameJoin` を使用し、OS 依存の `$PathnameSeparator` や `"\\"` による文字列置換を行わない。Git パス（スラッシュ区切り）への変換は `iNormalizeGitPath` が `FileNameSplit` + `"/"` 結合で処理する。これにより Windows / macOS / Linux 間でのパス不整合を防止している。