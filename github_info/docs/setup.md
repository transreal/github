# github (GitHubREST`) セットアップガイド

## 要件

| 項目 | 内容 |
|------|------|
| Mathematica | 13.0 以上推奨 |
| 依存パッケージ | [NBAccess](https://github.com/transreal/NBAccess) |
| 外部サービス | GitHub アカウント・Personal Access Token |

macOS/Linux ではパス区切りやシェルコマンドを適宜読み替えてください。

---

## 1. 依存パッケージの確認

`GitHubREST` は [NBAccess](https://github.com/transreal/NBAccess) に依存します。
先に NBAccess が `$packageDirectory` に配置済みであることを確認してください。

```wolfram
FileExistsQ[FileNameJoin[{$packageDirectory, "NBAccess.wl"}]]
(* True であれば OK *)
```

---

## 2. パッケージのインストール

`github_fixed.wl` を `$packageDirectory` にコピーします。

```
$packageDirectory の場所を確認:
```

```wolfram
$packageDirectory
```

`github_fixed.wl` を上記フォルダへ配置してください。

---

## 3. パッケージの読み込み

```wolfram
Block[{$CharacterEncoding = "UTF-8"},
  Needs["GitHubREST`", "github_fixed.wl"]];
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
(* GitHub 上に private リポジトリを作成し、default branch 名を返す *)
```

公開リポジトリにする場合:

```wolfram
GitHubCreateRepository["myPackage", Public -> True]
```

### ファイルをコミット

```wolfram
(* ローカル作業フォルダへコピー → GitHub へコミット *)
GitHubRefreshAndCommit["myPackage", "Update package"]
```

### プルリクエストの作成

```wolfram
GitHubSubmitPullRequest["myPackage", "Fix: ...", "詳細説明"]
```

### オープン中の PR 一覧

```wolfram
GitHubListPullRequests["myPackage"]
```

---

## 7. リポジトリ名データベース（日本語パッケージ名対応）

日本語名のパッケージと英語リポジトリ名の対応を登録します。
日本語パッケージ名を初めて使用する際は、Claude API を利用して意味のある英語リポジトリ名を自動生成し、重複チェックを行ったうえで登録します。

```wolfram
GitHubRepoDBSet["情報工学科時間割", "pkg-094d20d0"]
GitHubRepoDBLookup["情報工学科時間割"]
(* "pkg-094d20d0" *)
```

---

## 8. パッケージのインストール・更新

```wolfram
(* GitHub から $packageDirectory へ初回ダウンロード *)
GitHubInstallPackage["fact"]

(* 既存パッケージを最新版に更新 *)
GitHubUpdatePackage["fact"]
```

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

**先頭行 (#0) はローカル最新版**として表示されます。過去コミットに巻き戻す前に現在の作業ファイルが自動的にスナップショットとして保存され、#0 行の Pull ボタンで元の状態に戻すことができます。

| ボタン | 動作 |
|--------|------|
| Review | コミットの詳細・差分をノートブックに表示する |
| Pull | 指定コミットのファイルをローカルおよび `$packageDirectory` に取得する（初回のみスナップショット自動保存） |
| Revert | 指定コミットを打ち消すリバートコミットを作成する |

### コミットの詳細確認

```wolfram
GitHubReviewCommit["myPackage", "a1b2c3d"]
(* 指定 SHA のコミット詳細・差分をノートブックに表示する *)
```

### コミットのリバート

```wolfram
GitHubRevertCommit["myPackage", "a1b2c3d", "誤ったコミットを元に戻す"]
(* 指定コミットの変更を打ち消すリバートコミットを GitHub に作成する *)
```

---

## 10. ライセンス保持者の設定

README.md に MIT ライセンスセクションを自動挿入する場合は、パッケージ読み込み前または後に以下を設定してください。

```wolfram
$GitHubLicenseHolder = "Katsunobu Imai"
(* 例: $GitHubLicenseHolder = "Katsunobu Imai" *)
```

空文字列 `""` のままにしておくと、ライセンスセクションは README.md に挿入されません（既定値は `""`）。

---

## 主要オプション一覧

| オプション | 既定値 | 説明 |
|-----------|--------|------|
| `Owner` | `Automatic` | GitHub ユーザー名（省略時はトークンから自動取得） |
| `Repository` | `Automatic` | リポジトリ名（省略時は packageName） |
| `Branch` | `Automatic` | 操作対象ブランチ |
| `BaseBranch` | `Automatic` | デフォルトブランチ（API から自動取得） |
| `Public` | `False` | `True` で公開リポジトリ作成 |
| `CreateBranch` | `Automatic` | ブランチ不在時に自動作成するか |
| `DeleteMissing` | `False` | ローカルに無いリモートファイルを削除するか |
| `MaxItems` | `30` | `GitHubListCommits` / `GitHubCommitDataset` で取得するコミット数の上限 |

---

## トラブルシューティング

| 症状 | 対処 |
|------|------|
| `NBGetAPIKey["github"]` が `$Failed` | `NBSetAPIKey["github", "トークン"]` で再登録 |
| 403 エラー | トークンの `repo` スコープを確認 |
| 文字化け | `Block[{$CharacterEncoding="UTF-8"}, ...]` で読み込む |
| リポジトリが見つからない | `GitHubRepoDBSet` で名前対応を登録 |
| 日本語パッケージ名のリポジトリ名自動生成が失敗する | [claudecode](https://github.com/transreal/claudecode) が利用可能か確認するか、`GitHubRepoDBSet` で手動登録する |
| 過去コミットに巻き戻した後、元の作業ファイルに戻したい | `GitHubCommitDataset` の #0 行「Pull」ボタンでローカル最新版スナップショットに復元する |