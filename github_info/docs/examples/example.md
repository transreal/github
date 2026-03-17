以下が `examples/example.md` の内容です（ファイル書き込みの許可をいただければ保存します）:

---

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

**出力例:** `"main"`（作成後の default branch 名）

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

**出力例:** `"/path/to/GithubRepositories/mypackage"`（ローカルパス）

---

## 5. パッケージをインストール／更新する

```mathematica
(* 初回インストール *)
GitHubInstallPackage["NBAccess", Owner -> "transreal"]
```

**出力例:** `"/path/to/$packageDirectory/NBAccess.wl"`

```mathematica
(* 最新版に更新 *)
GitHubUpdatePackage["NBAccess"]
```

**出力例:** `"/path/to/$packageDirectory/NBAccess.wl"`

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

```mathematica
(* 日本語パッケージ名に英語リポジトリ名を登録 *)
GitHubRepoDBSet["情報工学科時間割", "pkg-094d20d0"]
GitHubRepoDBLookup["情報工学科時間割"]
```

**出力例:** `"pkg-094d20d0"`

```mathematica
GitHubRepoDB[]
```

**出力例:** `<|"情報工学科時間割" -> "pkg-094d20d0", "模範解答" -> "pkg-32114038", ...|>`