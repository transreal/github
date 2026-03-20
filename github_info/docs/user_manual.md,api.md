# GitHub パッケージ ユーザーマニュアル・API リファレンス

## ユーザーマニュアル

### 概要

GitHub パッケージは、Mathematica/Wolfram Language から GitHub REST API を利用するためのヘルパーパッケージです。このパッケージを使用することで、パッケージの GitHub リポジトリへのアップロード、プルリクエストの管理、コミット履歴の確認などを簡単に行うことができます。

### 前提条件

- [NBAccess](https://github.com/transreal/NBAccess) パッケージ（認証に使用）
- [claudecode](https://github.com/transreal/claudecode) パッケージ（推奨）
- GitHub API トークン（NBAccess で管理）

### 基本セットアップ

1. **認証設定**
   ```mathematica
   (* GitHub API トークンを NBAccess に設定 *)
   NBAccess`NBSetAPIKey["github", "your_github_token_here"]
   ```

2. **パッケージの読み込み**
   ```mathematica
   Needs["GitHubREST`"]
   ```

### 基本的なワークフロー

#### 新規リポジトリの作成とパッケージのアップロード

```mathematica
(* 1. アップロード対象の設定（マニフェスト自動生成） *)
GitHubReadManifest["パッケージ名"]

(* 2. GitHub に新規リポジトリを作成してパッケージをアップロード *)
GitHubCreateRepository["パッケージ名"]
```

#### 既存パッケージの更新

```mathematica
(* 1. ローカルファイルをリフレッシュしてコミット *)
GitHubRefreshAndCommit["パッケージ名", "更新内容の説明"]

(* または、プルリクエストとして提出 *)
GitHubSubmitPullRequest["パッケージ名", "PR タイトル", "更新内容の説明"]
```

#### 他のリポジトリからのパッケージインストール

```mathematica
(* GitHub からパッケージを初回ダウンロード *)
GitHubInstallPackage["新しいパッケージ名", "https://github.com/user/repo"]

(* 既存パッケージの更新 *)
GitHubUpdatePackage["パッケージ名"]
```

### アップロードマニフェストの管理

パッケージのアップロード時に、どのファイル・ディレクトリを含めるかは `upload_manifest.json` で管理されます。

```mathematica
(* マニフェストの確認・自動生成 *)
manifest = GitHubReadManifest["パッケージ名"]

(* 追加ディレクトリを指定してリポジトリ作成 *)
GitHubCreateRepository["パッケージ名", 
  ExtraDirectories -> {"Claude Directives", "docs"}]
```

### プルリクエストの管理

```mathematica
(* プルリクエスト一覧の表示（インタラクティブ） *)
GitHubPullRequestDataset["パッケージ名"]

(* 特定の PR をレビュー *)
GitHubReviewPullRequest["パッケージ名", 1]

(* PR のマージ *)
GitHubMergePullRequest["パッケージ名", 1, "承認理由"]
```

### コミット履歴の管理

```mathematica
(* コミット履歴の表示（インタラクティブ） *)
GitHubCommitDataset["パッケージ名"]

(* 特定コミットの詳細レビュー *)
GitHubReviewCommit["パッケージ名", "commit_sha"]

(* コミットのリバート *)
GitHubRevertCommit["パッケージ名", "commit_sha"]
```

### トラブルシューティング

#### 認証エラーが発生する場合
```mathematica
(* API キーが正しく設定されているか確認 *)
NBAccess`NBGetAPIKey["github"]
```

#### リポジトリ名が日本語の場合
```mathematica
(* 英語リポジトリ名とのマッピングを登録 *)
GitHubRepoDBSet["日本語パッケージ名", "english-repo-name"]
```

#### ローカルファイルとリモートの同期
```mathematica
(* リモートから最新版を取得 *)
GitHubPull["パッケージ名"]
```

## API リファレンス

### パッケージ URL 管理

#### `GitHubPackageURL[packageName]`

指定されたパッケージの GitHub URL を返します。

**パラメータ:**
- `packageName`: パッケージ名（文字列）

**オプション:**
- `Owner`: GitHub ユーザー名/組織名（既定値: `Automatic`）

**使用例:**
```mathematica
GitHubPackageURL["claudecode"]
GitHubPackageURL["mypackage", Owner -> "myusername"]
```

#### `GitHubPackageURLs[]`

`$packageDirectory` 内のすべてのパッケージの URL を Association で返します。

### ローカルリポジトリ管理

#### `GitHubRepoPath[packageName]`

指定されたパッケージのローカル GitHub 作業フォルダのパスを返します。

**戻り値:** `FileNameJoin[{$packageDirectory, "GithubRepositories", packageName}]`

#### `GitHubEnsureLocalRepo[packageName]`

ローカル GitHub 作業フォルダを作成して返します。

**オプション:**
- `LocalRepoPath`: 保存先パス（既定値: `Automatic`）

### マニフェスト・リフレッシュ機能

#### `GitHubReadManifest[packageName]`

パッケージの `upload_manifest.json` を読み込みます。ファイルが存在しない場合は自動生成します。

**戻り値:** アップロード対象のファイル・ディレクトリ一覧の Association

#### `GitHubRefreshLocalPackageGroup[packageName]`

`upload_manifest.json` に基づいて対象ファイル・ディレクトリをローカル GitHub 作業フォルダへコピーします。

#### `GitHubRefreshLocalPackage[packageName]`

単一の `.wl` ファイルをローカル GitHub 作業フォルダへコピーします（後方互換性のため）。

### リポジトリ作成・操作

#### `GitHubCreateRepository[packageName]`

GitHub 上に新規リポジトリを作成し、パッケージファイルをアップロードします。

**オプション:**
- `Owner`: GitHub ユーザー名/組織名（既定値: `Automatic`）
- `Repository`: リポジトリ名（既定値: `Automatic`）
- `Public`: 公開リポジトリにするか（既定値: `False`）
- `Description`: リポジトリの説明
- `Homepage`: ホームページ URL
- `AutoInit`: README 付きで初期化するか（既定値: `True`）
- `GitignoreTemplate`: .gitignore テンプレート名
- `LicenseTemplate`: ライセンステンプレート名
- `ExtraDirectories`: 追加するディレクトリのリスト

#### `GitHubReadFile[packageName, path]`

GitHub 上のファイルを読み取ります。

**パラメータ:**
- `packageName`: パッケージ名
- `path`: ファイルパス

**オプション:**
- `ReturnType`: 戻り値の型（`"Text"`, `"ByteArray"`, `"Bytes"`）

#### `GitHubPull[packageName]`

指定ブランチのリポジトリ内容をローカル GitHub 作業フォルダへ取得します。

**オプション:**
- `Branch`: 対象ブランチ（既定値: `Automatic`）
- `Clean`: 既存ファイルを先に削除するか（既定値: `False`）

### コミット・プッシュ機能

#### `GitHubCommit[packageName, message]`

ローカル GitHub 作業フォルダの内容を GitHub の指定ブランチへコミットします。

**パラメータ:**
- `packageName`: パッケージ名
- `message`: コミットメッセージ

**オプション:**
- `Branch`: 対象ブランチ（既定値: `Automatic`）
- `BaseBranch`: ベースブランチ（既定値: `Automatic`）
- `CreateBranch`: ブランチを新規作成するか（既定値: `Automatic`）
- `Force`: fast-forward 制約を無視するか（既定値: `False`）
- `DeleteMissing`: ローカルにないリモートファイルを削除するか（既定値: `False`）
- `Author`: コミット作成者情報
- `Committer`: コミッター情報
- `IncludePackageFile`: パッケージファイルを含めるか（既定値: `True`）

#### `GitHubRefreshAndCommit[packageName, message]`

リフレッシュとコミットを一度に行います。

### プルリクエスト管理

#### `GitHubCreatePullRequest[packageName, title]`

プルリクエストを作成します。

**パラメータ:**
- `packageName`: パッケージ名
- `title`: PR タイトル

**オプション:**
- `Head`: PR の head ブランチ（既定値: `Automatic`）
- `BaseBranch`: ベースブランチ（既定値: `Automatic`）
- `Body`: PR の本文
- `Draft`: ドラフト PR として作成するか
- `MaintainerCanModify`: メンテナーの編集を許可するか

#### `GitHubSubmitPullRequest[packageName, title, message]`

リフレッシュ、ブランチ作成、コミット、プルリクエスト作成を一括で行います。

#### `GitHubListPullRequests[packageName]`

オープンな PR 一覧を緊急度・依存関係でソートして返します。

#### `GitHubPullRequestDataset[packageName]`

PR 一覧を Review/Pull/Merge/Close ボタン付き Dataset で返します。

#### `GitHubMergePullRequest[packageName, prNumber, reason]`

指定された PR をマージします。

#### `GitHubClosePullRequest[packageName, prNumber, reason]`

指定された PR をクローズします。

#### `GitHubReviewPullRequest[packageName, prNumber]`

PR のコードをダウンロードし、レビュー用コードをノートブックに出力します。

### コミット履歴管理

#### `GitHubListCommits[packageName]`

リポジトリのコミット履歴を取得してリストで返します。

**オプション:**
- `MaxItems`: 取得するコミット数の上限（既定値: 30）
- `Branch`: 対象ブランチ

#### `GitHubCommitDataset[packageName]`

コミット履歴を Review/Pull/Revert ボタン付き Grid で表示します。

#### `GitHubReviewCommit[packageName, sha]`

指定コミットの詳細・差分をノートブックに表示します。

#### `GitHubRevertCommit[packageName, sha]`

指定コミットの変更を元に戻すリバートコミットを作成します。

### リポジトリ名データベース

#### `GitHubRepoDB[]`

`GithubRepositories/repo_database.json` を読み込み、全レコードを Association で返します。

#### `GitHubRepoDBSet[packageName, repoName]`
#### `GitHubRepoDBSet[packageName, repoName, owner]`

パッケージ名と GitHub リポジトリ名の対応を DB に登録します。日本語パッケージ名の場合に英語リポジトリ名を指定するのに使用します。

#### `GitHubRepoDBLookup[packageName]`

DB からリポジトリ名を解決します。未登録なら packageName をそのまま返します。

### パッケージインストール・更新

#### `GitHubInstallPackage[packageName]`
#### `GitHubInstallPackage[packageName, url]`

GitHub から `$packageDirectory` にパッケージを初回ダウンロードします。

**パラメータ:**
- `packageName`: パッケージ名
- `url`: リポジトリ URL（他人のリポジトリからインストールする場合）

**オプション:**
- `Owner`: GitHub ユーザー名/組織名
- `Repository`: リポジトリ名
- `Branch`: 対象ブランチ

#### `GitHubUpdatePackage[packageName]`

既存パッケージを GitHub の最新版に更新します。

### グローバル設定

#### `$GitHubLicenseHolder`

MIT ライセンスの著作権者名を指定します。空文字列 `""` の場合、ライセンスセクションは README.md に挿入されません。

**使用例:**
```mathematica
$GitHubLicenseHolder = "Katsunobu Imai"
```

### 共通オプション

以下のオプションは複数の関数で共通して使用されます：

- `Owner`: GitHub の所有者（ユーザー名/組織名）
- `Repository`: GitHub のリポジトリ名
- `Branch`: 操作対象ブランチ
- `BaseBranch`: ベースブランチまたは PR の base branch
- `Public`: 新規リポジトリを公開するかどうか
- `Description`: リポジトリの説明
- `Homepage`: ホームページ URL
- `AutoInit`: README 付きで初期化するかどうか
- `GitignoreTemplate`: GitHub の gitignore テンプレート名
- `LicenseTemplate`: GitHub の license テンプレート名
- `CreateBranch`: ブランチを新規作成するかどうか
- `LocalRepoPath`: ローカル GitHub 作業フォルダのパス
- `PackageFile`: 元の packageName.wl のパス
- `IncludePackageFile`: packageName.wl をコピーするかどうか
- `ReturnType`: GitHubReadFile の戻り値型
- `Clean`: GitHubPull 時の既存ファイル削除
- `Force`: ref 更新時の fast-forward 制約無視
- `DeleteMissing`: コミット時のリモートファイル削除
- `Head`: プルリクエストの head
- `Body`: プルリクエスト本文
- `Draft`: ドラフトプルリクエストとして作成
- `MaintainerCanModify`: メンテナーによる head branch 編集許可
- `Author`: コミット作成者情報
- `Committer`: コミッター情報
- `ExtraDirectories`: 追加するディレクトリのリスト
- `MaxItems`: 取得するアイテム数の上限