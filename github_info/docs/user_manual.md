# GitHubREST パッケージ ユーザーマニュアル

GitHub REST API を Wolfram Language から操作するパッケージです。
認証は [NBAccess](https://github.com/transreal/NBAccess) の `NBGetAPIKey["github"]` に委譲されます。

---

## 読み込み

```mathematica
Needs["GitHubREST`", FileNameJoin[{$packageDirectory, "github_fixed.wl"}]]
```

---

## 1. URL・リポジトリ情報

### `GitHubPackageURL`
`$packageDirectory` 内のパッケージの GitHub URL を返します。

```mathematica
GitHubPackageURL["claudecode"]
(* -> "https://github.com/transreal/claudecode" *)
```

オプション `Owner -> "myorg"` でオーナーを明示指定できます。`Fallback -> True` で Claude API 利用不可時にフォールバックモデルを使用します。

---

### `GitHubPackageURLs`
`$packageDirectory` 内の全パッケージの `<|name -> url, ...|>` を返します。

```mathematica
GitHubPackageURLs[]
(* -> <|"claudecode" -> "https://...", "NBAccess" -> "https://...", ...|> *)
```

---

## 2. ローカルリポジトリ管理

### `GitHubRepoPath`
ローカル作業フォルダのパスを返します（作成はしません）。

```mathematica
GitHubRepoPath["mypackage"]
(* -> ".../GithubRepositories/mypackage" *)
```

---

### `GitHubEnsureLocalRepo`
ローカル作業フォルダを作成して返します。

```mathematica
GitHubEnsureLocalRepo["mypackage"]
(* フォルダが存在しなければ作成してパスを返す *)
```

`LocalRepoPath -> "/custom/path"` で保存先を変更できます。

---

### `GitHubReadManifest`
`packageName_info/upload_manifest.json` を読み、アップロード対象ファイル一覧を返します。ファイルが存在しない場合は自動生成します。パッケージ種別（`.wl` / パクレット）が変更された場合も自動的にマニフェストを更新します。

```mathematica
GitHubReadManifest["mypackage"]
(* -> <|"files" -> {"mypackage.wl", ...}, "directories" -> {...},
       "excludePatterns" -> {...}|> *)
```

---

### `GitHubRefreshLocalPackageGroup`
`upload_manifest.json` に基づき対象ファイル群をローカル作業フォルダへコピーします。`_info/docs/README.md` が存在すればトップレベル `README.md` として配置します。また `_info/originals/` に保存されているファイルをリポジトリフォルダへ書き戻します。

```mathematica
GitHubRefreshLocalPackageGroup["mypackage"]
```

---

### `GitHubRefreshLocalPackage`
単一 `.wl` ファイルをローカル作業フォルダへコピーします（後方互換用）。

```mathematica
GitHubRefreshLocalPackage["mypackage"]
```

---

## 3. リモートリポジトリ操作

### `GitHubCreateRepository`
GitHub 上に新規リポジトリを作成します。デフォルトは private。`upload_manifest.json` があればファイル群を初回コミットします。

```mathematica
GitHubCreateRepository["mypackage", Public -> True, Description -> "My WL package"]
(* -> <|"Package" -> ..., "DefaultBranch" -> "main", ...|> *)
```

`ExtraDirectories` オプションで `upload_manifest.json` の `directories` に追加のディレクトリを永続的に登録できます。

```mathematica
GitHubCreateRepository["mypackage",
  ExtraDirectories -> {"Claude Directives"}]
```

主なオプション: `Public`, `Description`, `Homepage`, `AutoInit`, `GitignoreTemplate`, `LicenseTemplate`, `ExtraDirectories`, `Fallback`

---

### `GitHubReadFile`
GitHub 上のファイルを読み取ります。

```mathematica
GitHubReadFile["mypackage", "README.md"]
GitHubReadFile["mypackage", "data.bin", ReturnType -> "ByteArray"]
```

`ReturnType` に `"Text"` (既定)・`"ByteArray"`・`"Bytes"` を指定可能です。

---

### `GitHubPull`
リモートの内容をローカル作業フォルダへ取得します。

```mathematica
GitHubPull["mypackage"]
GitHubPull["mypackage", Branch -> "dev", Clean -> True]
```

`Clean -> True` で既存ローカルファイルを先に削除します。

---

### `GitHubCommit`
ローカル作業フォルダの内容を GitHub へコミットします。複数ファイルをまとめて反映します。

```mathematica
GitHubCommit["mypackage", "fix: update algorithm"]
GitHubCommit["mypackage", "feat: new feature", Branch -> "dev", CreateBranch -> True]
```

主なオプション: `Branch`, `BaseBranch`, `CreateBranch`, `Force`, `DeleteMissing`, `Author`, `Committer`, `IncludePackageFile`, `Fallback`

---

### `GitHubRefreshAndCommit`
`upload_manifest.json` に基づきファイルをコピーしてからコミットまで一括実行します。

```mathematica
GitHubRefreshAndCommit["mypackage", "chore: sync files"]
```

`ExtraDirectories` オプションで `upload_manifest.json` の `directories` に追加のディレクトリを永続的に登録できます。

```mathematica
GitHubRefreshAndCommit["mypackage", "sync",
  ExtraDirectories -> {"Claude Directives"}]
```

主なオプション: `Owner`, `Repository`, `Branch`, `BaseBranch`, `CreateBranch`, `DeleteMissing`, `Force`, `Author`, `Committer`, `ExtraDirectories`, `Fallback`

---

## 4. プルリクエスト管理

### `GitHubCreatePullRequest`
プルリクエストを作成します。`head` と `base` が同じブランチの場合はエラーを返し、`GitHubSubmitPullRequest` の使用を提案します。

```mathematica
GitHubCreatePullRequest["mypackage", "Add new feature",
  Head -> "dev", Body -> "詳細説明", Draft -> True]
```

---

### `GitHubSubmitPullRequest`
リフレッシュ → ブランチ作成 → コミット → PR 作成を一括実行します。ブランチ名は `pr/packageName/日時-タイトル` の形式で自動生成されます。

```mathematica
GitHubSubmitPullRequest["mypackage", "PR タイトル", "コミットメッセージ"]
```

---

### `GitHubListPullRequests`
オープンな PR 一覧を緊急度・重要度・依存関係でソートして返します。ラベル（`urgent`, `critical`, `hotfix`, `high`, `low`, `breaking`, `security`, `bug`, `feature` 等）に基づいて優先度を判定します。

```mathematica
GitHubListPullRequests["mypackage"]
(* -> {{prNumber, title, ...}, ...} *)
```

---

### `GitHubPullRequestDataset`
PR 一覧を Review / Pull / Merge / Close ボタン付きの Grid で返します。

```mathematica
GitHubPullRequestDataset["mypackage"]
```

**ボタンの動作:**
- **Review**: PR のコードを取得し、レビュー用コードをノートブックに出力します
- **Pull**: PR ブランチをローカルに取得し、パッケージを再読み込みするコードを出力します
- **Merge**: マージ理由を入力して PR をマージします
- **Close**: クローズ理由を入力して PR をクローズします

---

### `GitHubMergePullRequest`
PR をマージします。理由が指定されている場合、PR にコメントとして残します。

```mathematica
GitHubMergePullRequest["mypackage", 42, "実装確認済み"]
```

---

### `GitHubClosePullRequest`
PR をクローズします。理由が指定されている場合、PR にコメントとして残します。

```mathematica
GitHubClosePullRequest["mypackage", 42, "方針変更によりクローズ"]
```

---

### `GitHubReviewPullRequest`
PR のコードをダウンロードし、レビュー用コードをノートブックに出力します。PR 情報（タイトル、ブランチ、作者、ファイル数、本文）と変更ファイルの差分（最大 10 ファイル、各最大 2000 文字）を CellGroup として表示します。

```mathematica
GitHubReviewPullRequest["mypackage", 42]
```

---

## 5. コミット履歴管理

### `GitHubListCommits`
リポジトリのコミット履歴を取得してリストで返します。

```mathematica
GitHubListCommits["mypackage"]
GitHubListCommits["mypackage", MaxItems -> 50, Branch -> "dev"]
```

オプション: `Owner`, `Repository`, `Branch`, `BaseBranch`, `MaxItems`（既定値 30）, `Fallback`

---

### `GitHubCommitDataset`
コミット履歴を Review / Pull / Revert ボタン付き Grid で表示します。

```mathematica
GitHubCommitDataset["mypackage"]
```

**起動時の自動スナップショット保存:** 呼び出し時に、既存のスナップショットを削除してから、現在の `$packageDirectory` の作業ファイルをローカルスナップショットとして自動保存します。各ファイルの SHA-256 ハッシュも `_snapshot_hashes.json` に記録されます。

**`#0` 行（ローカル最新版）:** Grid の先頭行にローカル最新版への復元行が表示されます。過去コミットを Pull した後でも、この行の Pull ボタンでスナップショット保存時の状態に戻せます。

**変更検出と警告:** Pull ボタン押下時に、スナップショット保存後にファイルが変更されていないか SHA-256 ハッシュで検出します。変更済みファイルがある場合は、変更ファイル一覧と「すべてローカル最新版に置き換える」「キャンセル」ボタンを含む警告セルグループを Grid の直後に挿入します。変更がない場合は通常の確認ダイアログを表示します。

**コミット行の Pull ボタン:** 過去コミットの Pull ボタンを押すと、最初の Pull 時にのみスナップショットを自動保存し、`GithubRepositories` と `$packageDirectory` の両方にコミットのファイルを展開します。既にスナップショットがある場合は温存されます。

オプション: `Owner`, `Repository`, `Branch`, `BaseBranch`, `MaxItems`, `Fallback`

---

### `GitHubReviewCommit`
指定コミットの詳細・差分をノートブックに表示します。コミット情報（SHA、作者、日付、ファイル数、メッセージ）と変更ファイルの差分（最大 15 ファイル、各最大 2000 文字）を CellGroup として出力します。Pull（ローカルに取得）・Revert ボタンも生成されます。

```mathematica
GitHubReviewCommit["mypackage", "a1b2c3d"]
```

---

### `GitHubRevertCommit`
指定コミットの変更を元に戻すリバートコミットを作成します。親コミットの tree を使い、現在の HEAD を親とする新しいコミットを作成してブランチを更新します。

```mathematica
GitHubRevertCommit["mypackage", "a1b2c3d", "誤った変更のリバート"]
```

---

## 6. パッケージインストール・更新

### `GitHubInstallPackage`
GitHub から `$packageDirectory` へパッケージをダウンロードします。

**1引数版（自分のリポジトリ）:**

```mathematica
GitHubInstallPackage["claudecode"]
GitHubInstallPackage["mypackage", Owner -> "myorg", Branch -> "main"]
```

**2引数版（他人のリポジトリ URL を指定）:**

```mathematica
GitHubInstallPackage["pkg", "https://github.com/alice/repo"]
```

URL を指定すると、owner と repository 名を自動的にパースして `repo_database.json` に登録します。以降は `GitHubUpdatePackage["pkg"]`・`GitHubCommitDataset["pkg"]`・`GitHubSubmitPullRequest["pkg", ...]` などをパッケージ名だけで操作できます。

**インストール時のコピー動作:**

インストール先のファイル構成に応じて、以下の 3 パターンで `$packageDirectory` へファイルをコピーします。

| パターン | 条件 | 動作 |
|---|---|---|
| A（自分のリポジトリ） | RepoDB に owner 登録なし | 全ファイル・全フォルダをそのままコピー（`.gitignore` は除外）。`excludePatterns` に該当する既存ファイルは保護されます |
| B（リモート + `_info` あり） | RepoDB に owner 登録あり かつ `_info` フォルダが存在 | `README.md` を除く全ファイル・全フォルダをコピー（`excludePatterns` に該当する既存ファイルは保護） |
| C（リモート + `_info` なし） | RepoDB に owner 登録あり かつ `_info` フォルダが存在しない | `.wl` ファイルのみ `$packageDirectory` へ、その他は `_info/originals/` に振り分け |

パターン C では、非 `.wl` ファイルの配置情報が `_info/references/doc_options.json` の `Originals` フィールドに保存されます。次回コミット時に `GitHubRefreshLocalPackageGroup` が `_info/originals/` から元の位置へ自動的に書き戻します。

---

### `GitHubUpdatePackage`
既存パッケージを GitHub の最新版に更新します。内部的には `GitHubInstallPackage` と同じ動作です。

```mathematica
GitHubUpdatePackage["claudecode"]
```

---

## 7. リポジトリ名データベース

日本語など ASCII 以外のパッケージ名と GitHub リポジトリ名のマッピングを管理します。

日本語パッケージ名のリポジトリ名を未登録のまま操作すると、Claude API を使って意味のある英語リポジトリ名を自動生成（3 候補）し、GitHub 上の重複も自動チェックします。全候補が既に存在する場合はサフィックス（`-2` 〜 `-20`、または日付）を付けて重複を回避します。`Fallback -> False`（既定）の場合、Claude Code が利用できなければエラーを返して処理を停止します。`Fallback -> True` の場合はフォールバックモデルを試行し、それも失敗した場合は `Transliterate` によるローマ字変換にフォールバックします。

### `GitHubRepoDB`
全レコードを Association で返します。

```mathematica
GitHubRepoDB[]
(* -> <|"情報工学科時間割" -> <|"repository" -> "timetable-cs-dept", ...|>, ...|> *)
```

---

### `GitHubRepoDBSet`
パッケージ名とリポジトリ名の対応を DB に登録します。

**2引数版:**

```mathematica
GitHubRepoDBSet["情報工学科時間割", "timetable-cs-dept"]
```

**3引数版（owner も含めて登録）:**

他人のリポジトリをインストールする際など、owner を明示して登録する場合に使用します。`GitHubInstallPackage[packageName, url]` は内部でこの 3 引数版を自動的に呼び出します。

```mathematica
GitHubRepoDBSet["pkg", "repo-name", "alice"]
```

---

### `GitHubRepoDBLookup`
DB からリポジトリ名を解決します。未登録なら `packageName` をそのまま返します。

```mathematica
GitHubRepoDBLookup["情報工学科時間割"]
(* -> "timetable-cs-dept" *)
```

---

## 8. グローバル変数

### `$GitHubLicenseHolder`
README.md に挿入する MIT ライセンスの著作権者名を設定します。空文字列 `""` の場合、ライセンスセクションは README.md に挿入されません。

```mathematica
$GitHubLicenseHolder = "Katsunobu Imai"
```

既定値は `""`（ライセンス挿入なし）です。

---

## 9. 他人のリポジトリを使う流れ

```mathematica
(* 1. 初回インストール: URL を指定して owner/repo を自動登録 *)
GitHubInstallPackage["pkg", "https://github.com/alice/repo"]

(* 2. 以降はパッケージ名だけで操作可能 *)
GitHubUpdatePackage["pkg"]                              (* 最新を pull *)
GitHubCommitDataset["pkg"]                              (* コミット履歴を確認 *)
GitHubSubmitPullRequest["pkg", "Fix", "Bug fix"]        (* PR 送信 *)
```

---

## 10. Undo 再評価防止ガード

`GitHubReviewPullRequest`、`GitHubReviewCommit`、および各 Grid のボタン操作には Undo 再評価防止ガードが組み込まれています。ノートブックの Undo 操作により同じアクションが二重に実行されることを防ぎます。ガードは `WithCleanup` で正常終了・異常終了のいずれの場合も自動的に解除されます。

---

## 11. 主要オプション一覧

| オプション | 既定値 | 説明 |
|---|---|---|
| `Owner` | `Automatic` | GitHub オーナー名（Automatic でトークンから取得、RepoDB に登録があればそちらを優先） |
| `Repository` | `Automatic` | リポジトリ名（Automatic で packageName を使用、RepoDB に登録があればそちらを優先） |
| `Branch` | `Automatic` | 操作対象ブランチ |
| `BaseBranch` | `Automatic` | ベースブランチ（デフォルトブランチを自動取得） |
| `CreateBranch` | `Automatic` | ブランチが存在しなければ作成するか（Automatic の場合 Branch ≠ BaseBranch なら True） |
| `Public` | `False` | リポジトリを公開にするか |
| `AutoInit` | `True` | 初期化時に README を含めるか |
| `Clean` | `False` | Pull 時にローカルを先に削除するか |
| `Force` | `False` | ref 更新を強制するか |
| `DeleteMissing` | `False` | Commit 時にリモート専用ファイルを削除するか |
| `ReturnType` | `"Text"` | `GitHubReadFile` の戻り値型（`"Text"` / `"ByteArray"` / `"Bytes"`） |
| `LocalRepoPath` | `Automatic` | ローカル作業フォルダのパス |
| `Author` | `Automatic` | コミット author `<\|"name"->..., "email"->...\|>` |
| `Committer` | `Automatic` | コミット committer `<\|"name"->..., "email"->...\|>` |
| `Draft` | `False` | Draft PR として作成するか |
| `MaintainerCanModify` | `True` | PR で maintainers に head branch の編集を許可するか |
| `MaxItems` | `30` | `GitHubListCommits` / `GitHubCommitDataset` で取得するコミット数の上限 |
| `ExtraDirectories` | `{}` | `GitHubCreateRepository` / `GitHubRefreshAndCommit` で upload_manifest.json の directories に永続追加するディレクトリのリスト |
| `Fallback` | `False` | Claude API 利用不可時にフォールバックモデルを使用するか。`True` にすると `$ClaudeFallbackModels` のモデルを順次試行します |
| `IncludePackageFile` | `True` | `GitHubCommit` / `GitHubCreateRepository` の前にマニフェストに基づくファイルリフレッシュを行うか |
| `Head` | `Automatic` | PR の head ブランチ（Automatic の場合 Branch を使用） |
| `Body` | `""` | PR 本文 |
| `Description` | `""` | 新規リポジトリの説明 |
| `Homepage` | `None` | 新規リポジトリの homepage URL |
| `GitignoreTemplate` | `None` | GitHub の gitignore テンプレート名 |
| `LicenseTemplate` | `None` | GitHub の license テンプレート名 |
| `PackageFile` | `Automatic` | 元の packageName.wl のパスを明示指定 |

---

## 関連パッケージ

- [NBAccess](https://github.com/transreal/NBAccess) — API キー管理・ノートブック操作
- [claudecode](https://github.com/transreal/claudecode) — Claude AI との連携（日本語パッケージ名の英語リポジトリ名自動生成にも使用）