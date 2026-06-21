# GitHubREST` 使用例

## 1. パッケージの GitHub URL を取得する

```mathematica
Needs["GitHubREST`", "github.wl"];
GitHubPackageURL["claudecode"]
```

**出力例:** `"https://github.com/transreal/claudecode"`

---

```mathematica
GitHubPackageURLs[]
```

**出力例:** `<|"claudecode" -> "https://github.com/transreal/claudecode", "NBAccess" -> "https://github.com/transreal/NBAccess", ...|>`

---

## 2. 新規リポジトリを作成してファイルを初回コミットする

```mathematica
GitHubCreateRepository["mypackage", Public -> True,
  Description -> "My Wolfram package"]
```

**出力例:** `<|"Package" -> "mypackage", "Owner" -> "transreal", "DefaultBranch" -> "main", ...|>`

`upload_manifest.json` が存在すれば、対象ファイル群をまとめて初回コミットします。`_info/docs/README.md` があればトップレベル `README.md` として自動配置されます。

### 2-1. ExtraDirectories で追加ディレクトリを含める

```mathematica
GitHubCreateRepository["mypackage", Public -> False,
  ExtraDirectories -> {"Claude Directives"}]
```

`ExtraDirectories` で指定したディレクトリは `upload_manifest.json` に永続的に追加され、以降の `GitHubRefreshAndCommit` でも自動的にアップロード対象になります。

---

## 3. パッケージファイルを更新して GitHub へコミットする

```mathematica
GitHubRefreshAndCommit["mypackage", "fix: バグ修正"]
```

**出力例:** `<|"Action" -> "RefreshAndCommit", "CommitSHA" -> "a1b2c3d4...", ...|>`

`upload_manifest.json` に基づいて対象ファイル群をローカル GitHub 作業フォルダへコピーし、GitHub へコミットします。`_info/docs/README.md` が変更されていればトップレベル `README.md` も自動更新されます。

### 3-1. ブランチを指定してコミットする

```mathematica
GitHubRefreshAndCommit["mypackage", "feat: 新機能",
  Branch -> "feature/new-feature", CreateBranch -> True]
```

`Branch` で別ブランチにコミットできます。`CreateBranch -> True` でブランチが存在しなければ `BaseBranch` から自動作成します。

### 3-2. ExtraDirectories で一時的にディレクトリを追加する

```mathematica
GitHubRefreshAndCommit["mypackage", "add: ドキュメント追加",
  ExtraDirectories -> {"Claude Directives"}]
```

---

## 4. GitHub からローカル作業フォルダへ内容を取得する

```mathematica
GitHubPull["mypackage"]
```

**出力例:** `<|"Package" -> "mypackage", "LocalRepoPath" -> "/path/to/GithubRepositories/mypackage", "FilesPulled" -> 5, ...|>`

### 4-1. Clean オプションで既存ファイルを削除してから取得する

```mathematica
GitHubPull["mypackage", Clean -> True]
```

`Clean -> True` を指定すると、ローカル作業フォルダの既存ファイルをすべて削除してからファイルを取得します。

---

## 5. パッケージをインストール／更新する

### 5-1. 自分のパッケージを初回インストール

```mathematica
(* 自分の GitHub アカウントに紐づいたパッケージをダウンロード *)
GitHubInstallPackage["NBAccess"]
```

**出力例:** `<|"Package" -> "NBAccess", "InstalledTo" -> "/path/to/$packageDirectory", "Items" -> {"NBAccess.wl", "NBAccess_info/"}, ...|>`

### 5-2. 他人のリポジトリを URL 指定でインストール

```mathematica
(* GitHub URL を直接指定して他人のリポジトリをインストール *)
GitHubInstallPackage["ResistorBuilder", "https://github.com/dzhang314/ResistorBuilder"]
```

**出力例:** `<|"Package" -> "ResistorBuilder", "Owner" -> "dzhang314", "Repository" -> "ResistorBuilder", "InstalledTo" -> "/path/to/$packageDirectory", ...|>`

インストール後は `GitHubUpdatePackage`・`GitHubCommitDataset`・`GitHubSubmitPullRequest` 等がパッケージ名だけで動作します。

外部パッケージ（`_info` フォルダを持たないもの）をインストールした場合、`.wl` ファイルは `$packageDirectory` に直接配置され、それ以外のファイル（README.md 等）は `パッケージ名_info/originals/` に振り分けられます。

```mathematica
(* インストール済みパッケージを最新版に更新 *)
GitHubUpdatePackage["ResistorBuilder"]
```

**出力例:** `<|"Package" -> "ResistorBuilder", "InstalledTo" -> "/path/to/$packageDirectory", ...|>`

---

## 6. Pull Request を作成する

### 6-1. 一括実行（推奨）

```mathematica
GitHubSubmitPullRequest["mypackage",
  "feat: 新機能追加",
  "詳細な変更内容をここに記述する。",
  Body -> "PR 本文（マークダウン対応）",
  Branch -> "feature/new-feature"]
```

**出力例:** `<|"Action" -> "SubmitPullRequest", "PullRequest" -> <|"Number" -> 3, "URL" -> "https://github.com/transreal/mypackage/pull/3", ...|>, ...|>`

`GitHubSubmitPullRequest` はグループリフレッシュ → ブランチ作成 → コミット → PR 作成を一括で行います。`Branch` を省略すると `pr/パッケージ名/日時-タイトル` 形式のブランチ名が自動生成されます。

### 6-2. 手動で段階的に実行する

```mathematica
(* ステップ 1: 別ブランチにコミット *)
GitHubRefreshAndCommit["mypackage", "feat: 新機能",
  Branch -> "feature/xxx", CreateBranch -> True]

(* ステップ 2: PR を作成 *)
GitHubCreatePullRequest["mypackage", "feat: 新機能追加",
  Branch -> "feature/xxx", Body -> "PR 本文"]
```

**注意:** `GitHubCreatePullRequest` は `head` と `base` が同じブランチの場合にエラーを返します。必ず別ブランチを指定してください。

---

## 7. Pull Request 一覧を確認してマージする

```mathematica
GitHubPullRequestDataset["mypackage"]
```

**出力例:** Review/Pull/Merge/Close ボタン付きの Grid が表示されます。PR は緊急度・重要度で自動ソートされます。

```mathematica
GitHubMergePullRequest["mypackage", 3, "スカッシュマージ"]
```

**出力例:** `<|"Action" -> "Merged", "PR" -> 3, "Package" -> "mypackage", "Reason" -> "スカッシュマージ", ...|>`

```mathematica
GitHubClosePullRequest["mypackage", 3, "不要になったため"]
```

**出力例:** `<|"Action" -> "Closed", "PR" -> 3, ...|>`

### 7-1. PR のコードレビュー

```mathematica
GitHubReviewPullRequest["mypackage", 3]
```

PR の差分・変更ファイル一覧がノートブックに CellGroup として出力されます。Pull・Merge・Close のアクションボタンも含まれます。

---

## 8. コミット履歴を確認する

### 8-1. コミット一覧の取得

```mathematica
GitHubListCommits["mypackage"]
```

**出力例:** コミット情報の Association のリストが返ります。

```mathematica
GitHubListCommits["mypackage", MaxItems -> 10]
```

`MaxItems` で取得するコミット数の上限を指定できます（既定値: 30）。

### 8-2. インタラクティブなコミット履歴表示

```mathematica
GitHubCommitDataset["mypackage"]
```

Review/Pull/Revert ボタン付きの Grid がノートブックに出力されます。

- **#0 行（ローカル最新版）:** 起動時に SHA-256 ハッシュ付きスナップショットが自動保存されます。過去コミットに Pull で巻き戻した後、#0 行の Pull ボタンでローカル最新版に復元できます。
- **Review ボタン:** コミットの詳細・差分をノートブックに表示します。
- **Pull ボタン:** 確認ダイアログの後、そのコミット時点のファイルをローカル作業フォルダと `$packageDirectory` の両方に取得します。スナップショットが未保存なら自動保存されます。
- **Revert ボタン:** リバート理由を入力して、そのコミットの変更を元に戻す新しいコミットを作成します。

### 8-3. コミット詳細のレビュー

```mathematica
GitHubReviewCommit["mypackage", "a1b2c3d4e5f6"]
```

コミットの差分・変更ファイル（最大 15 ファイル、各 2000 文字まで）がノートブックに表示され、Pull・Revert のアクションボタンも含まれます。

### 8-4. コミットのリバート

```mathematica
GitHubRevertCommit["mypackage", "a1b2c3d4e5f6", "バグが含まれていたため"]
```

**出力例:** `<|"Action" -> "Revert", "RevertedCommit" -> "a1b2c3d", "NewCommit" -> "f7e8d9c", "Branch" -> "main", ...|>`

指定コミットの親の tree を使い、現在の HEAD を親として新しいリバートコミットを作成します。

---

## 9. リポジトリ名データベースを管理する（日本語パッケージ名の対応）

### 9-1. リポジトリ名のみ登録（2引数版）

```mathematica
(* 日本語パッケージ名に英語リポジトリ名を登録 *)
GitHubRepoDBSet["情報工学科時間割", "jouhou-timetable"]
GitHubRepoDBLookup["情報工学科時間割"]
```

**出力例:** `"jouhou-timetable"`

### 9-2. owner を含めて登録（3引数版）

他人のリポジトリを管理する場合は owner も一緒に登録できます。

```mathematica
(* owner を含めて登録することで、以降の操作で owner を自動解決できる *)
GitHubRepoDBSet["ResistorBuilder", "ResistorBuilder", "dzhang314"]
GitHubRepoDBLookup["ResistorBuilder"]
```

**出力例:** `"ResistorBuilder"`

```mathematica
GitHubRepoDB[]
```

**出力例:** `<|"情報工学科時間割" -> <|"repository" -> "jouhou-timetable", "packageName" -> "情報工学科時間割", ...|>, "ResistorBuilder" -> <|"repository" -> "ResistorBuilder", "owner" -> "dzhang314", ...|>, ...|>`

### 9-3. 日本語パッケージ名の自動翻訳

日本語パッケージ名で `GitHubCreateRepository` 等を使用すると、Claude API を使って意味のある英語リポジトリ名が自動生成されます。重複チェックも自動で行われ、既存のリポジトリ名と衝突しない名前が選ばれます。`Fallback -> True` を指定していない場合、API エラー時は処理を停止してエラーを返します。

---

## 10. GitHub 上のファイルを直接読み取る

```mathematica
GitHubReadFile["mypackage", "README.md"]
```

**出力例:** README.md の内容が文字列で返ります。

```mathematica
(* バイナリファイルを ByteArray として取得 *)
GitHubReadFile["mypackage", "image.png", ReturnType -> "ByteArray"]
```

`ReturnType` は `"Text"`（既定）、`"ByteArray"`、`"Bytes"` から指定できます。

### 10-2. ローカルファイルを UTF-8 で読み取る

```mathematica
GitHubReadLocalFile["mypackage", "mypackage.wl"]
```

**出力例:** ローカルの `mypackage.wl` の内容が UTF-8 でデコードされた文字列で返ります。

```mathematica
(* path を省略するとパッケージの .wl ファイルを読む *)
GitHubReadLocalFile["mypackage"]
```

`ReadString` と異なり `$CharacterEncoding` に依存せず常に UTF-8 でデコードするため、日本語 Windows 環境でも文字化けしません。`GitHubReadFile` で取得したリモート内容との差分確認に利用できます。

---

## 11. ローカル作業フォルダとマニフェストの管理

### 11-1. ローカル作業フォルダのパス確認・作成

```mathematica
GitHubRepoPath["mypackage"]
```

**出力例:** `"C:\\Users\\...\\$packageDirectory\\GithubRepositories\\mypackage"`

```mathematica
GitHubEnsureLocalRepo["mypackage"]
```

ローカル作業フォルダが存在しなければ作成して、パスを返します。

### 11-2. アップロードマニフェストの確認

```mathematica
GitHubReadManifest["mypackage"]
```

**出力例:** `<|"packageName" -> "mypackage", "files" -> {"mypackage.wl"}, "directories" -> {"mypackage_info"}, "excludePatterns" -> {"mypackage_info/history/", "mypackage_info/references/"}|>`

マニフェストが存在しない場合は、パッケージ種別（`.wl` / パクレット）に基づいてデフォルト構成が返されます。パッケージ種別が変わった場合（例: `.wl` → パクレット変換後）は自動的に更新されます。

### 11-3. マニフェストに基づくグループリフレッシュ

```mathematica
GitHubRefreshLocalPackageGroup["mypackage"]
```

**出力例:** `<|"Package" -> "mypackage", "CopiedFiles" -> {"mypackage.wl"}, "CopiedDirectoryFiles" -> {...}, "DeletedFiles" -> {}, "DeletedDirFiles" -> {}, "READMESynced" -> "/path/to/README.md", ...|>`

`upload_manifest.json` に基づいて対象ファイル群をローカル GitHub 作業フォルダへコピーします。`_info/docs/README.md` が存在すればトップレベル `README.md` として配置します。`_info/originals/` のファイルはリポジトリ内の元の位置に自動的に書き戻されます。

ソース側で削除されたファイルはローカル作業フォルダからも自動的に削除されます。削除されたファイルのパスは `"DeletedFiles"`（個別ファイル）および `"DeletedDirFiles"`（ディレクトリ配下のファイル）として返り値に含まれます。

### 11-4. 単一ファイルのコピー（後方互換）

```mathematica
GitHubRefreshLocalPackage["mypackage"]
```

単一の `.wl` ファイルをローカル作業フォルダへコピーします。グループアップロードには `GitHubRefreshLocalPackageGroup` を使用してください。

### 11-5. マニフェストの検証

```mathematica
GitHubValidateManifest["mypackage"]
```

**出力例:** `<|"Status" -> "OK", "FileCount" -> 5, "MissingFiles" -> {}, "ExcludePatterns" -> {"mypackage_info/history/"}, "Directories" -> {"mypackage_info"}, "Issues" -> {}|>`

`upload_manifest.json` を検査し、以下の項目を確認します。

- `files[]` に列挙されたファイルがローカルに実在するか
- `secret`・`token`・`credential`・`.pid`・`.log` 等の名前を含むファイルが混入していないか
- 除外パターンの設定内容

`Issues` フィールドには検出された問題が列挙されます。

| Issue タグ | 内容 |
|---|---|
| `"MissingFiles"` | manifest に記載されているがローカルに存在しないファイルが見つかった場合。`"Files"` キーに対象パスが含まれます。 |
| `"SuspectSecretFiles"` | secret・token 等の名前を持つ疑わしいファイルが検出された場合。`"Files"` キーに対象パスが含まれます。 |

配布前の「成果が抜けていないか」「秘密が混入していないか」の確認に使用します。

---

## 12. 低レベル操作: GitHubCommit

```mathematica
GitHubCommit["mypackage", "fix: バグ修正",
  Branch -> "main",
  DeleteMissing -> True]
```

**出力例:** `<|"Package" -> "mypackage", "CommitSHA" -> "a1b2c3d4...", "Branch" -> "main", ...|>`

ローカル作業フォルダの内容を GitHub の指定ブランチへコミットします。`DeleteMissing -> True` を指定すると、ローカルに存在しないリモートファイルを削除対象として tree に含めます。`Force -> True` で ref 更新時の fast-forward 制約を無視できます。

通常は `GitHubRefreshAndCommit` や `GitHubSubmitPullRequest` の利用を推奨します。

**422 競合の自動リトライ:** 並列実行等で head SHA がずれた場合（HTTP 422 エラー）、head SHA を再取得して最大 3 回まで自動的にリトライします。リトライ上限に達した場合は `"並列実行を避けるか、時間をおいて再試行してください。"` というメッセージを含む `Failure` が返ります。

### 12-1. エラーハンドリング

`GitHubCommit` は blob 作成時のエラーを `Catch/Throw` パターンで確実に伝播します。個別ファイルの blob 作成中にエラーが発生した場合、残りのファイル処理を即座に中断し、エラーの `Failure` オブジェクトを返します。

発生しうる主なエラー:

| タグ | 説明 |
|------|------|
| `"MissingBlobSHA"` | blob 作成後に SHA を取得できなかった場合。エラーデータに対象ファイルパスが含まれます。 |
| `"EmptyEntries"` | すべての blob 作成が失敗し、コミット対象のエントリが空の場合。エラーデータにローカルファイル数が含まれます。 |
| `"MissingNewTreeSHA"` | 新しい tree SHA を取得できなかった場合。エラーデータに tree レスポンスの詳細が含まれます。 |
| `"LocalFileReadFailed"` | ローカルファイルの読込に失敗した場合。 |

---

## 13. 他人のリポジトリを使う典型的な流れ

```mathematica
(* 1. URL を指定して初回インストール（owner と repository が自動登録される） *)
GitHubInstallPackage["ResistorBuilder", "https://github.com/dzhang314/ResistorBuilder"]

(* 2. 最新版に更新 *)
GitHubUpdatePackage["ResistorBuilder"]

(* 3. コミット履歴を確認（Review/Pull/Revert ボタン付き） *)
GitHubCommitDataset["ResistorBuilder"]

(* 4. 変更提案を Pull Request として送信 *)
GitHubSubmitPullRequest["ResistorBuilder", "Fix: バグ修正", "詳細な変更内容"]
```

---

## 14. ライセンス設定

```mathematica
$GitHubLicenseHolder = "Katsunobu Imai"
```

`$GitHubLicenseHolder` を設定すると、`ClaudeCreateDocumentation` の `License -> ""` オプションと連携して、README.md に MIT ライセンスセクションが自動挿入されます。空文字列（既定値）の場合、ライセンスセクションは挿入されません。

---

## 15. Fallback オプション

API 利用制限に達した場合の挙動を制御します。

```mathematica
(* Fallback なし（既定）: エラー時は処理を停止して Failure を返す *)
GitHubCreateRepository["mypackage"]

(* Fallback あり: 代替モデルを順次試行する *)
GitHubCreateRepository["mypackage", Fallback -> True]
```

`Fallback -> True` を明示的に指定しない限り、API エラー時は処理を即停止します。すべての主要関数で `Fallback` オプションが利用可能です。

---

## 16. パッケージ自動コミット（docs 鮮度ゲート・差分・コミットメッセージ案）

`GitHubRefreshAndCommit` の前段を担うヘルパー群です。ドキュメントの鮮度チェック・前回コミットとの差分計算・コミットメッセージ案の生成（決定論または LLM）を行い、安全にコミットを駆動します。すべて既定では ReadOnly（差分・計画のみ）で動作します。

### 16-1. ドキュメント鮮度ゲートの検査

```mathematica
PackageDocsFreshnessGate["github"]
```

**出力例:** `<|"Status" -> "OK", "Package" -> "github", "Proceed" -> True, "Checked" -> 1, "StaleDocs" -> {}, "DocsDir" -> "/path/to/github_info/docs"|>`

`packageName_info/docs` 配下の `api.md` / `api_*.md` が対応する `.wl` ファイル以降に更新されているか（鮮度）を検査します。対応規則は `api.md` ↔ `<pkg>.wl`、`api_<suffix>.md` ↔ `<pkg>_<suffix>.wl` です。

api ドキュメントが対応 `.wl` より古い（= `.wl` 更新後にドキュメントが未更新）ものが 1 つでもあれば `"Proceed" -> False` となり、`"StaleDocs"` に `<|Doc, Wl, DocDate, WlDate|>` が列挙されます。

```mathematica
(* 古いドキュメントがある場合 *)
PackageDocsFreshnessGate["github"]
(* <|"Status" -> "OK", "Proceed" -> False,
     "StaleDocs" -> {<|"Doc" -> "api.md", "Wl" -> "github.wl",
        "DocDate" -> DateObject[...], "WlDate" -> DateObject[...]|>}, ...|> *)
```

対応する `.wl` が存在しない api ドキュメントは検査対象外です。docs フォルダが無ければ `"Proceed" -> True` になります。

### 16-2. 前回コミットとの差分計算

```mathematica
PackageCommitDiff["github"]
```

**出力例:** `<|"Status" -> "OK", "Package" -> "github", "SnapshotDir" -> "/path/to/GithubRepositories/github", "SnapshotExists" -> True, "Added" -> {}, "Changed" -> {"github.wl"}, "Removed" -> {}, "UnchangedCount" -> 4, "ChangeCount" -> 1, "ChangedDetail" -> {...}, "Summary" -> "added 0, changed 1, removed 0"|>`

現ソースと前回コミットスナップショット（`GithubRepositories/<pkg>`）との差分を ReadOnly に計算します。`upload_manifest.json` を直接 Import し、`GitHubRefreshAndCommit` の前方マッピング（`files` = ベース名、`directories` = 相対パス + 除外パターン）を再現してソースとスナップショットを内容比較します。

**注意:** リフレッシュ前に呼んでください。リフレッシュ後はスナップショットが上書きされ差分が消えます。

### 16-3. コミット計画の組み立て

```mathematica
PackageCommitPlan["github"]
```

**出力例:** `<|"Status" -> "OK", "Package" -> "github", "Proceed" -> True, "Diff" -> <|...|>, "CommitMessage" -> "github.wl のコミット差分計算ヘルパーを追加", ...|>`

鮮度ゲート → 差分 → コミットメッセージ案 を ReadOnly に組み立てます。

- ゲートが `"Proceed" -> False`（docs が古い）なら `"Status" -> "Blocked"`
- 差分が無ければ `"Status" -> "NoChange"`
- 両方 OK なら `"Status" -> "OK"` で `"CommitMessage"` を返します（実コミットはしません）

```mathematica
(* メッセージ生成器を固定文字列にする *)
PackageCommitPlan["github", "MessageGenerator" -> "fix: 手動メッセージ"]

(* 鮮度ゲートを無視して計画だけ確認する *)
PackageCommitPlan["github", "SkipDocsGate" -> True]
```

`"MessageGenerator"` には `Automatic`（差分からの決定論的単文）、固定文字列、または差分 Association を受け取り文字列を返す関数を指定できます。`"SkipDocsGate" -> True` は docs 鮮度ゲートを無視して進み、OK 結果に `StaleDocs` 警告と `"DocsGateSkipped"` を付加します。

### 16-4. 計画の実行（メイン駆動関数）

```mathematica
(* 既定は DryRun: 実コミットせず計画とメッセージ案を返す *)
PackageCommit["github"]
```

**出力例:** `<|"Status" -> "DryRun", "Committed" -> False, "CommitMessage" -> "github.wl のコミット差分計算ヘルパーを追加", ...|>`

```mathematica
(* 実際にコミットする *)
PackageCommit["github", "DryRun" -> False]
```

**出力例:** `<|"Status" -> "Committed", "Committed" -> True, "CommitMessage" -> "...", ...|>`

`PackageCommitPlan` を実行し、`"Status" -> "OK"` のときに `GitHubRefreshAndCommit[packageName, CommitMessage]` を呼びます。`Blocked`（docs が古い）・`NoChange`・`Failed` のときはコミットせず計画結果を返します。

`"Status"` の取り得る値は `DryRun` / `Committed` / `Blocked` / `NoChange` / `Failed` です。実コミット（`"DryRun" -> False`）では `"SkipDocsGate"` の指定に関わらず docs が古ければ `Blocked` で停止し `StaleDocs` を返します（`"SkipDocsGate" -> True` は DryRun プレビュー専用）。

### 16-5. LLM によるコミットメッセージ生成

```mathematica
(* claudecode の Sonnet モデルでメッセージを生成する *)
PackageCommit["github", "DryRun" -> False,
  "MessageGenerator" -> PackageLLMMessageGenerator[$iModelSonnet]]
```

`PackageLLMMessageGenerator[queryFn]` は LLM でコミットメッセージを生成する `MessageGenerator` 関数（差分 Association → 文字列）を返します。`queryFn` は `prompt -> 文字列` の関数です。モデル指定子（タプル `{provider, model}` 例 `$iModelSonnet`、またはモデル名 String）を渡すと `ClaudeCode`ClaudeQueryBg[prompt, Model -> spec]` で自動的にラップされます（claudecode が必要）。

既定（`"IncludeContent" -> True`）では、変更ファイルの実際の変更行（`-` 削除 / `+` 追加、`PackageCommitDiff` の `ChangedDetail` から計算）をプロンプトに含め、何が変わったかを要約させます。ソース変更行をモデルに送るため、信頼できるモデルを使ってください。`"IncludeContent" -> False` でファイル名のみ（低 privacy）に戻せます。

`queryFn[prompt]` が文字列を返さない、または空の場合は決定論メッセージにフォールバックします。

| オプション | 既定値 | 内容 |
|---|---|---|
| `"MaxChars"` | `80` | 生成メッセージの最大文字数 |
| `"IncludeContent"` | `True` | プロンプトに変更行を含めるか |
| `"MaxContentChars"` | `4000` | 変更行全体の最大文字数 |
| `"MaxPerFileChars"` | `1500` | 1 ファイルあたりの変更行の最大文字数 |

生成されるコミットメッセージは決定論的な簡潔単文（体言止め）で、配布前のレビューに利用できます。