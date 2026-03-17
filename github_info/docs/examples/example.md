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

---

## 3. パッケージファイルを更新して GitHub へコミットする

```mathematica
GitHubRefreshAndCommit["mypackage", "fix: バグ修正"]
```

**出力例:** `<|"sha" -> "a1b2c3d4...", "url" -> "https://api.github.com/...", ...|>`

---

## 4. GitHub からローカル作業フォルダへ内容を取得する

```mathematica
GitHubPull["mypackage"]
```

**出力例:** `<|"Package" -> "mypackage", "LocalRepoPath" -> "/path/to/GithubRepositories/mypackage", "FilesPulled" -> 5, ...|>`

---

## 5. パッケージをインストール／更新する

### 5-1. 自分のパッケージを初回インストール

```mathematica
(* 自分の GitHub アカウントに紐づいたパッケージをダウンロード *)
GitHubInstallPackage["NBAccess"]
```

**出力例:** `<|"Package" -> "NBAccess", "InstalledTo" -> "/path/to/$packageDirectory", "Items" -> {"NBAccess.wl", "NBAccess_info/"}, ...|>`

### 5-2. 他人のリポジトリを URL 指定でインストール（新機能）

```mathematica
(* GitHub URL を直接指定して他人のリポジトリをインストール *)
GitHubInstallPackage["ResistorBuilder", "https://github.com/dzhang314/ResistorBuilder"]
```

**出力例:** `<|"Package" -> "ResistorBuilder", "Owner" -> "dzhang314", "Repository" -> "ResistorBuilder", "InstalledTo" -> "/path/to/$packageDirectory", ...|>`

インストール後は `GitHubUpdatePackage`・`GitHubCommitDataset`・`GitHubSubmitPullRequest` 等がパッケージ名だけで動作します。

```mathematica
(* インストール済みパッケージを最新版に更新 *)
GitHubUpdatePackage["ResistorBuilder"]
```

**出力例:** `<|"Package" -> "ResistorBuilder", "InstalledTo" -> "/path/to/$packageDirectory", ...|>`

---

## 6. Pull Request を作成する

```mathematica
GitHubSubmitPullRequest["mypackage",
  "feat: 新機能追加",
  "詳細な変更内容をここに記述する。",
  Branch -> "feature/new-feature"]
```

**出力例:** `<|"number" -> 3, "html_url" -> "https://github.com/transreal/mypackage/pull/3", ...|>`

---

## 7. Pull Request 一覧を確認してマージする

```mathematica
GitHubPullRequestDataset["mypackage"]
```

**出力例:** Dataset（PR番号・タイトル・状態・Review/Merge/Close ボタン付き）

```mathematica
GitHubMergePullRequest["mypackage", 3, "スカッシュマージ"]
```

**出力例:** `<|"sha" -> "d4e5f6...", "merged" -> True, "message" -> "Pull Request successfully merged"|>`

---

## 8. リポジトリ名データベースを管理する（日本語パッケージ名の対応）

### 8-1. リポジトリ名のみ登録（2引数版）

```mathematica
(* 日本語パッケージ名に英語リポジトリ名を登録 *)
GitHubRepoDBSet["情報工学科時間割", "jouhou-timetable"]
GitHubRepoDBLookup["情報工学科時間割"]
```

**出力例:** `"jouhou-timetable"`

### 8-2. owner を含めて登録（3引数版・新機能）

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

---

## 9. 他人のリポジトリを使う典型的な流れ

```mathematica
(* 1. URL を指定して初回インストール（owner と repository が自動登録される） *)
GitHubInstallPackage["ResistorBuilder", "https://github.com/dzhang314/ResistorBuilder"]

(* 2. 最新版に更新 *)
GitHubUpdatePackage["ResistorBuilder"]

(* 3. コミット履歴を確認（Review/Pull/Revert ボタン付き） *)
GitHubCommitDataset["ResistorBuilder"]

(* 4. 変更提案を Pull Request として送信 *)
GitHubSubmitPullRequest["ResistorBuilder", "Fix: バグ修正", "詳細な変更内容"]