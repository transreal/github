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
`$packageDirectory` 内のパッケージの GitHub URL を返す。

```mathematica
GitHubPackageURL["claudecode"]
(* -> "https://github.com/transreal/claudecode" *)
```

オプション `Owner -> "myorg"` でオーナーを明示指定できます。

---

### `GitHubPackageURLs`
`$packageDirectory` 内の全パッケージの `<|name -> url, ...|>` を返す。

```mathematica
GitHubPackageURLs[]
(* -> <|"claudecode" -> "https://...", "NBAccess" -> "https://...", ...|> *)
```

---

## 2. ローカルリポジトリ管理

### `GitHubRepoPath`
ローカル作業フォルダのパスを返す（作成はしない）。

```mathematica
GitHubRepoPath["mypackage"]
(* -> ".../GithubRepositories/mypackage" *)
```

---

### `GitHubEnsureLocalRepo`
ローカル作業フォルダを作成して返す。

```mathematica
GitHubEnsureLocalRepo["mypackage"]
(* フォルダが存在しなければ作成してパスを返す *)
```

`LocalRepoPath -> "/custom/path"` で保存先を変更できます。

---

### `GitHubReadManifest`
`packageName_info/upload_manifest.json` を読み、アップロード対象ファイル一覧を返す。ファイルが存在しない場合は自動生成します。

```mathematica
GitHubReadManifest["mypackage"]
(* -> <|"files" -> {"mypackage.wl", ...}, "dirs" -> {...}|> *)
```

---

### `GitHubRefreshLocalPackageGroup`
`upload_manifest.json` に基づき対象ファイル群をローカル作業フォルダへコピーします。`_info/docs/README.md` が存在すればトップレベル `README.md` として配置します。

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

主なオプション: `Public`, `Description`, `Homepage`, `AutoInit`, `GitignoreTemplate`, `LicenseTemplate`

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

主なオプション: `Branch`, `BaseBranch`, `CreateBranch`, `Force`, `DeleteMissing`, `Author`, `Committer`

---

### `GitHubRefreshAndCommit`
`upload_manifest.json` に基づきファイルをコピーしてからコミットまで一括実行します。

```mathematica
GitHubRefreshAndCommit["mypackage", "chore: sync files"]
```

---

## 4. プルリクエスト管理

### `GitHubCreatePullRequest`
プルリクエストを作成します。

```mathematica
GitHubCreatePullRequest["mypackage", "Add new feature",
  Head -> "dev", Body -> "詳細説明", Draft -> True]
```

---

### `GitHubSubmitPullRequest`
リフレッシュ → ブランチ作成 → コミット → PR 作成を一括実行します。

```mathematica
GitHubSubmitPullRequest["mypackage", "PR タイトル", "コミットメッセージ"]
```

---

### `GitHubListPullRequests`
オープンな PR 一覧を優先度・依存関係でソートして返します。

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

---

### `GitHubMergePullRequest`
PR をマージします。

```mathematica
GitHubMergePullRequest["mypackage", 42, "実装確認済み"]
```

---

### `GitHubClosePullRequest`
PR をクローズします。

```mathematica
GitHubClosePullRequest["mypackage", 42, "方針変更によりクローズ"]
```

---

### `GitHubReviewPullRequest`
PR のコードをダウンロードし、レビュー用コードをノートブックに出力します。

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

オプション: `Owner`, `Repository`, `Branch`, `BaseBranch`, `MaxItems`（既定値 30）

---

### `GitHubCommitDataset`
コミット履歴を Review / Pull / Revert ボタン付き Grid で表示します。

```mathematica
GitHubCommitDataset["mypackage"]
```

**起動時の自動スナップショット保存:** 呼び出し時に、現在の `$packageDirectory` の作業ファイルをローカルスナップショットとして自動保存します。

**`#0` 行（ローカル最新版）:** Grid の先頭行にローカル最新版への復元行が表示されます。過去コミットを Pull した後でも、この行の Pull ボタンでスナップショット保存時の状態に戻せます。変更済みファイルが検出された場合は確認ダイアログを表示します。

オプション: `Owner`, `Repository`, `Branch`, `BaseBranch`, `MaxItems`

---

### `GitHubReviewCommit`
指定コミットの詳細・差分をノートブックに表示します。Pull（ローカルに取得）・Revert ボタンも生成されます。

```mathematica
GitHubReviewCommit["mypackage", "a1b2c3d"]
```

---

### `GitHubRevertCommit`
指定コミットの変更を元に戻すリバートコミットを作成します。

```mathematica
GitHubRevertCommit["mypackage", "a1b2c3d", "誤った変更のリバート"]
```

---

## 6. パッケージインストール・更新

### `GitHubInstallPackage`
GitHub から `$packageDirectory` へパッケージを初回ダウンロードします。

```mathematica
GitHubInstallPackage["claudecode"]
GitHubInstallPackage["mypackage", Owner -> "myorg", Branch -> "main"]
```

---

### `GitHubUpdatePackage`
既存パッケージを GitHub の最新版に更新します。

```mathematica
GitHubUpdatePackage["claudecode"]
```

---

## 7. リポジトリ名データベース

日本語など ASCII 以外のパッケージ名と GitHub リポジトリ名のマッピングを管理します。

日本語パッケージ名のリポジトリ名を未登録のまま操作すると、Claude API を使って意味のある英語リポジトリ名を自動生成（3 候補）し、GitHub 上の重複も自動チェックします。Fallback -> False（既定）の場合、Claude Code が利用できなければエラーを返して処理を停止します。

### `GitHubRepoDB`
全レコードを Association で返します。

```mathematica
GitHubRepoDB[]
(* -> <|"情報工学科時間割" -> <|"repository" -> "timetable-cs-dept", ...|>, ...|> *)
```

---

### `GitHubRepoDBSet`
パッケージ名とリポジトリ名の対応を DB に登録します。

```mathematica
GitHubRepoDBSet["情報工学科時間割", "timetable-cs-dept"]
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
(* 例: $GitHubLicenseHolder = "Katsunobu Imai" *)
```

既定値は `""`（ライセンス挿入なし）です。

---

## 9. 主要オプション一覧

| オプション | 既定値 | 説明 |
|---|---|---|
| `Owner` | `Automatic` | GitHub オーナー名（Automatic でトークンから取得） |
| `Repository` | `Automatic` | リポジトリ名（Automatic で packageName を使用） |
| `Branch` | `Automatic` | 操作対象ブランチ |
| `BaseBranch` | `Automatic` | ベースブランチ（デフォルトブランチを自動取得） |
| `CreateBranch` | `Automatic` | ブランチが存在しなければ作成するか |
| `Public` | `False` | リポジトリを公開にするか |
| `AutoInit` | `True` | 初期化時に README を含めるか |
| `Clean` | `False` | Pull 時にローカルを先に削除するか |
| `Force` | `False` | ref 更新を強制するか |
| `DeleteMissing` | `False` | Commit 時にリモート専用ファイルを削除するか |
| `ReturnType` | `"Text"` | `GitHubReadFile` の戻り値型 |
| `LocalRepoPath` | `Automatic` | ローカル作業フォルダのパス |
| `Author` | — | コミット author `<\|"name"->..., "email"->...\|>` |
| `Committer` | — | コミット committer `<\|"name"->..., "email"->...\|>` |
| `Draft` | `False` | Draft PR として作成するか |
| `MaintainerCanModify` | `True` | PR で maintainers に head branch の編集を許可するか |
| `MaxItems` | `30` | `GitHubListCommits` / `GitHubCommitDataset` で取得するコミット数の上限 |

---

## 関連パッケージ

- [NBAccess](https://github.com/transreal/NBAccess) — API キー管理・ノートブック操作
- [claudecode](https://github.com/transreal/claudecode) — Claude AI との連携（日本語パッケージ名の英語リポジトリ名自動生成にも使用）