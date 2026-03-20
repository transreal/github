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

**出力例:** `<|"Package" -> "mypackage", "CopiedFiles" -> {"mypackage.wl"}, "CopiedDirectoryFiles" -> {...}, "READMESynced" -> "/path/to/README.md", ...|>`

`upload_manifest.json` に基づいて対象ファイル群をローカル GitHub 作業フォルダへコピーします。`_info/docs/README.md` が存在すればトップレベル `README.md` として配置します。`_info/originals/` のファイルはリポジトリ内の元の位置に自動的に書き戻されます。

### 11-4. 単一ファイルのコピー（後方互換）

```mathematica
GitHubRefreshLocalPackage["mypackage"]
```

単一の `.wl` ファイルをローカル作業フォルダへコピーします。グループアップロードには `GitHubRefreshLocalPackageGroup` を使用してください。

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