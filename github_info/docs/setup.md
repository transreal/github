# github (GitHubREST`) セットアップガイド

## 要件

| 項目 | 内容 |
|------|------|
| Mathematica | 13.0 以上推奨 |
| 依存パッケージ | [NBAccess](https://github.com/transreal/NBAccess) |
| 外部サービス | GitHub アカウント・Personal Access Token |
| 連携パッケージ (任意) | [claudecode](https://github.com/transreal/claudecode) — 日本語パッケージ名の自動翻訳に使用 |

macOS/Linux ではパス区切りやシェルコマンドを適宜読み替えてください。

---

## 1. 依存パッケージの確認

`GitHubREST` は [NBAccess](https://github.com/transreal/NBAccess) に依存します。
先に NBAccess が `$packageDirectory` に配置済みであることを確認してください。

```wolfram
FileExistsQ[FileNameJoin[{$packageDirectory, "NBAccess.wl"}]]
(* True であれば OK *)
```

日本語パッケージ名から英語リポジトリ名を自動生成する機能を使う場合は、[claudecode](https://github.com/transreal/claudecode) も必要です。

---

## 2. パッケージのインストール

`github.wl` を `$packageDirectory` にコピーします。

```
$packageDirectory の場所を確認:
```

```wolfram
$packageDirectory
```

`github.wl` を上記フォルダへ配置してください。

---

## 3. パッケージの読み込み

```wolfram
Block[{$CharacterEncoding = "UTF-8"},
  Needs["GitHubREST`", "github.wl"]];
```

---

## 4. GitHub API キーの設定

認証は [NBAccess](https://github.com/transreal/NBAccess) の `NBGetAPIKey["github"]` に委譲されます。

### 4-1. Personal Access Token の取得

1. GitHub → Settings → Developer settings → Personal access tokens
2. **Fine-grained tokens** または **Classic tokens** を生成
3. 必要スコープ: `repo`（リポジトリの読み書き）、`workflow`（任意）

### 4-2. NBAccess へのキー登録

```wolfram
Block[{$CharacterEncoding = "UTF-8"},
  Needs["NBAccess`", "NBAccess.wl"]];

NBSetAPIKey["github", "ghp_xxxxxxxxxxxxxxxxxxxx"]
```

登録後は永続化されるため、再設定不要です。

### 4-3. キーの確認

```wolfram
NBGetAPIKey["github"]
(* "ghp_xxxx..." が返れば OK *)
```

---

## 5. 動作確認

### 5-1. 自分のリポジトリ URL を取得

```wolfram
GitHubPackageURL["github"]
(* "https://github.com/<owner>/github" など *)
```

### 5-2. $packageDirectory 内の全パッケージ URL を一覧

```wolfram
GitHubPackageURLs[]
(* <|"packageName" -> "https://github.com/...", ...|> *)
```

---

## 6. 基本的な使い方

### リポジトリの新規作成

```wolfram
GitHubCreateRepository["myPackage"]
(* GitHub 上に private リポジトリを作成し、manifest に基づくファイル群をコミット *)
```

公開リポジトリにする場合:

```wolfram
GitHubCreateRepository["myPackage", Public -> True]
```

追加ディレクトリを含める場合:

```wolfram
GitHubCreateRepository["myPackage", ExtraDirectories -> {"Claude Directives"}]
```

### ファイルをコミット

```wolfram
(* upload_manifest.json に基づくファイル群を local repo へコピーし GitHub へコミット *)
GitHubRefreshAndCommit["myPackage", "Update package"]
```

### プルリクエストの一括作成 (refresh → branch → commit → PR)

```wolfram
GitHubSubmitPullRequest["myPackage", "Fix: ...", "コミットメッセージ",
  Body -> "PR 本文"]
```

### PR の個別作成 (既存ブランチから)

```wolfram
GitHubRefreshAndCommit["myPackage", "commit msg",
  Branch -> "feature/xxx", CreateBranch -> True]
GitHubCreatePullRequest["myPackage", "PR タイトル",
  Branch -> "feature/xxx", Body -> "PR 本文"]
```

### オープン中の PR 一覧

```wolfram
GitHubListPullRequests["myPackage"]
```

### インタラクティブな PR 管理

```wolfram
GitHubPullRequestDataset["myPackage"]
(* Review / Pull / Merge / Close ボタン付きの Grid が表示されます *)
```

### PR のマージ・クローズ

```wolfram
GitHubMergePullRequest["myPackage", 1, "マージ理由"]
GitHubClosePullRequest["myPackage", 1, "クローズ理由"]
```

### PR のコードレビュー

```wolfram
GitHubReviewPullRequest["myPackage", 1]
(* PR の差分・変更ファイルをノートブックに表示し、Merge/Close ボタンを提供 *)
```

### GitHub 上のファイルを読み取る

```wolfram
GitHubReadFile["myPackage", "README.md"]
(* バイナリ取得: ReturnType -> "ByteArray" *)
```

---

## 7. リポジトリ名データベース（日本語パッケージ名対応）

日本語名のパッケージと英語リポジトリ名の対応を登録します。
日本語パッケージ名を初めて使用する際は、[claudecode](https://github.com/transreal/claudecode) の Claude API を利用して意味のある英語リポジトリ名を自動生成し、重複チェックを行ったうえで登録します。

### 2引数版（リポジトリ名のみ登録）

```wolfram
GitHubRepoDBSet["情報工学科時間割", "jouhou-timetable"]
GitHubRepoDBLookup["情報工学科時間割"]
(* "jouhou-timetable" *)
```

### 3引数版（owner も含めて登録）

他人のリポジトリをパッケージ名で管理する場合は、`owner` も合わせて登録します。
登録後は `GitHubInstallPackage` などがパッケージ名だけでリモートリポジトリを参照できるようになります。

```wolfram
GitHubRepoDBSet["ResistorBuilder", "ResistorBuilder", "dzhang314"]
GitHubRepoDBLookup["ResistorBuilder"]
(* "ResistorBuilder" *)
```

### データベース全体の確認

```wolfram
GitHubRepoDB[]
(* <|"packageName" -> <|"repository" -> ..., "owner" -> ..., ...|>, ...|> *)
```

---

## 8. パッケージのインストール・更新

### 自分のパッケージをダウンロード

```wolfram
(* GitHub から $packageDirectory へ初回ダウンロード *)
GitHubInstallPackage["fact"]

(* 既存パッケージを最新版に更新 *)
GitHubUpdatePackage["fact"]
```

### 他人のリポジトリをインストール

URL を直接指定して他人のリポジトリをインストールできます。
インストール時に `owner` と `repository` がリポジトリ名データベースへ自動登録されるため、以降は `GitHubUpdatePackage`・`GitHubCommitDataset`・`GitHubSubmitPullRequest` などをパッケージ名だけで操作できます。

```wolfram
GitHubInstallPackage["ResistorBuilder", "https://github.com/dzhang314/ResistorBuilder"]
```

インストール後の操作例:

```wolfram
(* 最新版に更新 *)
GitHubUpdatePackage["ResistorBuilder"]

(* コミット履歴を確認 *)
GitHubCommitDataset["ResistorBuilder"]

(* PR を送信 *)
GitHubSubmitPullRequest["ResistorBuilder", "Fix", "Bug fix"]
```

### 外部パッケージのファイル配置について

外部パッケージ（`_info` フォルダを持たないリポジトリ）をインストールした場合、ファイルは次のように振り分けられます。

| ファイル種別 | 配置先 |
|---|---|
| `.wl` ファイル | `$packageDirectory` 直下 |
| その他のファイル・フォルダ | `$packageDirectory/<pkg>_info/originals/` |

この `originals/` に保存されたファイルは、次回 `GitHubRefreshAndCommit` 実行時にリポジトリへ自動的に書き戻されます。`_info/originals/` と元のリポジトリパスの対応は `_info/references/doc_options.json` の `Originals` フィールドに記録されます。

---

## 9. コミット履歴管理

### コミット履歴の一覧取得

```wolfram
GitHubListCommits["myPackage"]
(* コミット一覧をリストで返す。既定で最新 30 件。 *)

GitHubListCommits["myPackage", MaxItems -> 50]
```

### インタラクティブなコミット履歴表示

```wolfram
GitHubCommitDataset["myPackage"]
```

`GitHubCommitDataset` はコミット履歴を Review / Pull / Revert ボタン付きの Grid としてノートブックに出力します。

**先頭行 (#0) はローカル最新版**として表示されます。`GitHubCommitDataset` の呼び出し時に、現在の作業ファイルが SHA-256 ハッシュ付きで自動的にスナップショットとして保存されます。過去コミットを Pull した後、#0 行の Pull ボタンでこのスナップショットに復元できます。

| ボタン | 動作 |
|--------|------|
| Review | コミットの詳細・差分をノートブックに表示する |
| Pull | 指定コミットのファイルをローカルおよび `$packageDirectory` に取得する（初回のみスナップショット自動保存） |
| Revert | 指定コミットを打ち消すリバートコミットを作成する |

### スナップショットの変更検出

過去コミットに Pull した後でファイルを編集していた場合、#0 行の「Pull」ボタンをクリックすると、スナップショット時から変更されたファイルの一覧が表示されます。確認ダイアログで「すべてローカル最新版に置き換える」か「キャンセル」を選択できます。

### コミットの詳細確認

```wolfram
GitHubReviewCommit["myPackage", "a1b2c3d"]
(* 指定 SHA のコミット詳細・差分をノートブックに表示する *)
(* Pull (ローカルに取得) / Revert (コミットを戻す) ボタン付き *)
```

### コミットのリバート

```wolfram
GitHubRevertCommit["myPackage", "a1b2c3d", "誤ったコミットを元に戻す"]
(* 指定コミットの変更を打ち消すリバートコミットを GitHub に作成する *)
```

---

## 10. upload_manifest.json によるファイル管理

`GitHubREST` はパッケージの種類（単一 `.wl` またはパクレット）を自動検出し、`upload_manifest.json` を生成してアップロード対象を管理します。

### マニフェストの確認

```wolfram
GitHubReadManifest["myPackage"]
(* <|"packageName" -> "myPackage",
     "files" -> {"myPackage.wl"},
     "directories" -> {"myPackage_info"},
     "excludePatterns" -> {"myPackage_info/history/", "myPackage_info/references/"}|> *)
```

### ローカル作業フォルダへのファイルコピー

```wolfram
GitHubRefreshLocalPackageGroup["myPackage"]
(* manifest に基づき $packageDirectory のファイル群を GithubRepositories/myPackage/ へコピー *)
```

### ローカル作業フォルダのパス確認

```wolfram
GitHubRepoPath["myPackage"]
(* FileNameJoin[{$packageDirectory, "GithubRepositories", "myPackage"}] *)
```

### ローカル作業フォルダの作成

```wolfram
GitHubEnsureLocalRepo["myPackage"]
```

### ExtraDirectories による追加ディレクトリの永続登録

`ExtraDirectories` オプションで指定したディレクトリは `upload_manifest.json` に永続追加されます。

```wolfram
GitHubRefreshAndCommit["myPackage", "Update",
  ExtraDirectories -> {"Claude Directives"}]
```

### README.md の自動同期

`_info/docs/README.md` が存在する場合、`GitHubRefreshAndCommit` や `GitHubCreateRepository` の実行時にリポジトリトップレベルの `README.md` として自動的にコピーされます。

---

## 11. ライセンス保持者の設定

README.md に MIT ライセンスセクションを自動挿入する場合は、パッケージ読み込み前または後に以下を設定してください。

```wolfram
$GitHubLicenseHolder = "Katsunobu Imai"
```

空文字列 `""` のままにしておくと、ライセンスセクションは README.md に挿入されません（既定値は `""`）。

---

## 主要オプション一覧

| オプション | 既定値 | 説明 |
|-----------|--------|------|
| `Owner` | `Automatic` | GitHub ユーザー名（省略時は API トークンから自動取得、RepoDB に owner 登録済みならそちらを優先） |
| `Repository` | `Automatic` | リポジトリ名（省略時は packageName、RepoDB に登録済みならそちらを使用） |
| `Branch` | `Automatic` | 操作対象ブランチ（省略時は BaseBranch を使用） |
| `BaseBranch` | `Automatic` | デフォルトブランチ（API から自動取得） |
| `Public` | `False` | `True` で公開リポジトリ作成 |
| `CreateBranch` | `Automatic` | ブランチ不在時に自動作成するか（`Automatic` の場合、Branch ≠ BaseBranch なら `True`） |
| `DeleteMissing` | `False` | ローカルに無いリモートファイルを削除するか |
| `MaxItems` | `30` | `GitHubListCommits` / `GitHubCommitDataset` で取得するコミット数の上限 |
| `ExtraDirectories` | `{}` | `upload_manifest.json` の directories に永続追加するディレクトリのリスト |
| `Fallback` | `False` | `True` にすると Claude API 利用不可時に代替モデルへフォールバック |
| `Force` | `False` | ref 更新時に fast-forward 制約を無視するか |
| `Clean` | `False` | `GitHubPull` 時に既存のローカルファイルを先に削除するか |
| `ReturnType` | `"Text"` | `GitHubReadFile` の戻り値型（`"Text"` / `"ByteArray"` / `"Bytes"`） |
| `Author` | `Automatic` | コミットの author（`<\|"name" -> ..., "email" -> ...\|>` 形式） |
| `Committer` | `Automatic` | コミットの committer（`<\|"name" -> ..., "email" -> ...\|>` 形式） |
| `Body` | `""` | pull request 本文 |
| `Draft` | `False` | pull request を draft として作成するか |
| `MaintainerCanModify` | `True` | PR で maintainer に head branch の編集を許可するか |
| `LocalRepoPath` | `Automatic` | ローカル GitHub 作業フォルダを明示指定 |
| `IncludePackageFile` | `True` | コミット前にパッケージファイルをローカル作業フォルダへコピーするか |
| `PackageFile` | `Automatic` | 元の packageName.wl のパスを明示指定 |
| `Description` | `""` | 新規リポジトリ作成時の description |
| `Homepage` | `None` | 新規リポジトリ作成時の homepage URL |
| `AutoInit` | `True` | 新規リポジトリ作成時に README 付きで初期化するか |
| `GitignoreTemplate` | `None` | GitHub の gitignore template 名 |
| `LicenseTemplate` | `None` | GitHub の license template 名 |
| `Head` | `Automatic` | pull request の head（省略時は Branch を使用） |

---

## トラブルシューティング

| 症状 | 対処 |
|------|------|
| `NBGetAPIKey["github"]` が `$Failed` | `NBSetAPIKey["github", "トークン"]` で再登録 |
| 403 エラー | トークンの `repo` スコープを確認 |
| 文字化け | `Block[{$CharacterEncoding="UTF-8"}, ...]` で読み込む |
| リポジトリが見つからない | `GitHubRepoDBSet` で名前対応を登録 |
| 日本語パッケージ名のリポジトリ名自動生成が失敗する | [claudecode](https://github.com/transreal/claudecode) が利用可能か確認するか、`GitHubRepoDBSet` で手動登録する。`Fallback -> True` オプションで代替モデルを試行することもできます |
| 他人のリポジトリをインストール後に操作できない | `GitHubRepoDBSet["pkg", "repo", "owner"]` で owner を含めて登録する |
| 過去コミットに巻き戻した後、元の作業ファイルに戻したい | `GitHubCommitDataset` の #0 行「Pull」ボタンでローカル最新版スナップショットに復元する |
| Fine-grained PAT で新規リポジトリにアクセスできない (404) | Fine-grained PAT の対象リポジトリ設定が新しいリポジトリを含んでいない可能性があります。「All repositories」に設定するか、classic token を使用してください |
| `head` と `base` が同じブランチで PR を作成できない | `GitHubSubmitPullRequest` を使うか、`Branch` オプションで別ブランチを指定してください |