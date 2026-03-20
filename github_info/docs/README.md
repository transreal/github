# github — 設計思想と実装の概要

GitHub REST API を Wolfram Language から操作するヘルパーパッケージ（コンテキスト: `GitHubREST``）

## なぜこのパッケージを作ったか

Wolfram Language（Mathematica）のパッケージ開発では、コードを書き上げた後に GitHub へアップロードする作業が手動になりがちです。`github`（`GitHubREST``）は、その一連の操作――リポジトリ作成・ファイル同期・コミット・プルリクエスト管理――をすべて Wolfram Language のセル内から完結させることを目的として設計されています。

## 認証の委譲設計

APIキーをコード中に直書きしない安全設計を採用しています。GitHub Personal Access Token の取得・保持はすべて [NBAccess](https://github.com/transreal/NBAccess) の `NBGetAPIKey["github"]` に委譲します。これにより、`github` パッケージ自身は認証情報を一切保持せず、複数パッケージ間で統一されたキー管理が実現されます。

## マニフェスト駆動のファイル管理

単純な `.wl` ファイル単体のアップロードだけでなく、パクレット（フォルダ型パッケージ）や付属ドキュメント群をまとめて同期するために、**マニフェスト**（`packageName_info/upload_manifest.json`）を導入しています。マニフェストにはアップロード対象ファイル・ディレクトリ・除外パターンを記述でき、パッケージ種別（`.wl` 単体 / パクレットフォルダ）を自動検出して初回は自動生成されます。パッケージ種別が変更された場合（`.wl` からパクレットへの変換など）もマニフェストは自動更新されます。`_info/docs/README.md` が存在する場合はリポジトリのトップレベル `README.md` として自動配置されるため、ドキュメント管理も一元化できます。

## Git 低レベル API によるコミット

GitHub Contents API の単純なファイル更新ではなく、Git の低レベル API（blob 作成 → tree 作成 → commit 作成 → ref 更新）を使っています。これにより複数ファイルを**一つのコミットにまとめて**反映でき、履歴が汚れません。blob 作成処理では `Catch`/`Throw` パターンを採用し、ファイル読み込みエラー・API エラー・SHA 取得失敗（空文字列を含む）のいずれも即座に検出・伝播します。エントリが空の場合は `"EmptyEntries"` エラーとして報告され、tree SHA の検証でも空文字列を不正値として扱うため、問題の原因を正確に特定できます。Windows 環境での UTF-8 エンコード問題は `iEncodeJSONBody` / `iForceASCIIJSON` で内部的に回避しており、日本語ファイル名・コミットメッセージも正しく送信できます。

## 日本語パッケージ名対応

GitHub リポジトリ名には ASCII 文字しか使えないため、日本語などの非 ASCII パッケージ名と英語リポジトリ名の対応を `GithubRepositories/repo_database.json` で管理する**リポジトリ名データベース**を内蔵しています。未登録の非 ASCII 名は [claudecode](https://github.com/transreal/claudecode) の Claude API を呼び出し、意味のある英語リポジトリ名を 3 候補生成し、GitHub 上の重複を確認した上で自動登録します。Claude API が利用できない場合は `Transliterate` によるフォールバックが行われます。`Fallback -> True` オプションを指定すると、API 制限時も代替モデルで継続処理されます。`Fallback -> True` が明示されていない場合はエラーを伝播して処理を停止し、不正なリポジトリ名が登録されることを防ぎます。

## ローカル作業フォルダの役割

`$packageDirectory/GithubRepositories/packageName` をローカル作業フォルダとして使います。GitHub からの Pull（取得）はこのフォルダへ展開され、Commit 時はこのフォルダの内容を GitHub へ送信します。中間フォルダを挟む設計により、`$packageDirectory` 本体を直接汚染せずに安全にバージョン管理できます。

## ローカルスナップショットによる安全なコミット巻き戻し

`GitHubCommitDataset` の「Pull」ボタンで過去コミットのファイルをローカルに取得する際、**初回のみ**現在の作業状態を `GithubRepositories/_local_snapshot/packageName/` にスナップショットとして自動保存します。各ファイルの SHA-256 ハッシュも `_snapshot_hashes.json` に記録され、スナップショット後に変更されたファイルを検出できます。`GitHubCommitDataset` の「#0 行」から「Pull」ボタンを押すことでローカル最新版へいつでも復元可能です。2 回目以降の過去コミットへの巻き戻しでは既存スナップショットを温存するため、最初の作業状態が失われません。

復元時に変更されたファイルが検出された場合は、ファイル一覧と確認ボタン（「すべてローカル最新版に置き換える」/「キャンセル」）を含む警告セルグループが Grid の直後に挿入されます。

## プルリクエストの対話的管理

`GitHubPullRequestDataset` は、オープン PR の一覧を Review / Pull / Merge / Close の**ボタン付き Grid** として返します。緊急度・ラベル・依存関係によるソートも行われるため、Mathematica のノートブック上でそのままコードレビューからマージまで完結できます。

## コミット履歴の対話的管理

`GitHubCommitDataset` は、コミット履歴を Review / Pull / Revert の**ボタン付き Grid** として表示します。表示時に既存スナップショットを削除して現在の作業状態を新規保存するため、常に最新のローカル状態が記録されます。特定コミットのファイルをローカルに取得して検証したり、変更を打ち消すリバートコミットを作成したりする操作がノートブック上で完結します。ボタンの二重実行は `$iGitHubEvalGuard` による再評価防止ガードで保護されています。

## 他人のリポジトリのインストール管理

`GitHubInstallPackage[packageName, url]` の 2 引数版を使うと、GitHub URL を直接指定して他者のリポジトリをインストールできます。インストール時に owner・repository 名が `repo_database.json` へ自動登録されるため、以後は `packageName` だけで `GitHubUpdatePackage` や `GitHubCommitDataset` などの操作が可能になります。

インストール先の振り分けはリポジトリの種別によって自動判定されます。

| パターン | 条件 | 動作 |
|---------|------|------|
| A (自分のリポジトリ) | RepoDB に owner が登録されていない | 全ファイル・全フォルダをそのまま `$packageDirectory` へコピー |
| B (リモート + `_info` あり) | RepoDB に owner 登録あり、`packageName_info/` フォルダが存在 | README.md を除く全ファイルを `$packageDirectory` へコピー |
| C (リモート + `_info` なし) | RepoDB に owner 登録あり、`_info` フォルダなし | `.wl` のみ `$packageDirectory` へ、それ以外は `_info/originals/` に保存 |

パターン C の場合、非 `.wl` ファイル（README 等）は `packageName_info/originals/` へ振り分けられ、`doc_options.json` にマッピングが保存されます。コミット時に `iRestoreOriginalsToRepo` が元の位置へ書き戻します。

## 詳細説明

### 動作環境

| 項目 | 内容 |
|------|------|
| Mathematica | 13.0 以上推奨 |
| OS | Windows 11 想定（macOS / Linux は未検証） |
| 依存パッケージ | [NBAccess](https://github.com/transreal/NBAccess)、[claudecode](https://github.com/transreal/claudecode)（日本語パッケージ名の自動翻訳に使用） |
| 外部サービス | GitHub アカウント・Personal Access Token（スコープ: `repo`） |

### インストール

#### 1. 依存パッケージの確認

本パッケージは [NBAccess](https://github.com/transreal/NBAccess) に依存します。先に `NBAccess.wl` が `$packageDirectory` に配置済みであることを確認してください。日本語パッケージ名の自動英語翻訳には [claudecode](https://github.com/transreal/claudecode) も必要です。

```wolfram
FileExistsQ[FileNameJoin[{$packageDirectory, "NBAccess.wl"}]]
(* True であれば OK *)
```

#### 2. パッケージファイルの配置

`github_fixed.wl` を `$packageDirectory` にコピーします。

```wolfram
(* $packageDirectory の場所を確認 *)
$packageDirectory
```

#### 3. パッケージの読み込み

ファイル名だけで指定できるのは、`$packageDirectory` が `$Path` に含まれているためです。Windows 環境での文字化けを防ぐため、必ず `$CharacterEncoding = "UTF-8"` を指定して読み込んでください。

```wolfram
Block[{$CharacterEncoding = "UTF-8"},
  Needs["GitHubREST`", "github_fixed.wl"]];
```

#### 4. GitHub API キーの設定

認証は [NBAccess](https://github.com/transreal/NBAccess) に委譲されます。以下の手順でトークンを登録してください。

**Personal Access Token の取得:**
1. GitHub → Settings → Developer settings → Personal access tokens
2. Fine-grained tokens または Classic tokens を生成
3. 必要スコープ: `repo`（リポジトリの読み書き）

**NBAccess へのキー登録:**

```wolfram
Block[{$CharacterEncoding = "UTF-8"},
  Needs["NBAccess`", "NBAccess.wl"]];

NBSetAPIKey["github", "ghp_xxxxxxxxxxxxxxxxxxxx"]
(* 登録後は永続化されるため、再設定不要 *)
```

#### 5. ライセンス保持者名の設定（任意）

`$GitHubLicenseHolder` を設定すると、`_info/docs/README.md` を GitHub へ同期する際に MIT ライセンスセクションが自動挿入されます。空文字列のままにするとライセンスセクションは挿入されません。

```wolfram
$GitHubLicenseHolder = "Katsunobu Imai"
```

### クイックスタート

以下の手順を順に実行するだけで、パッケージの GitHub リポジトリ管理が始められます。

```wolfram
(* 1. パッケージの読み込み *)
Block[{$CharacterEncoding = "UTF-8"},
  Needs["GitHubREST`", "github_fixed.wl"]];

(* 2. $packageDirectory 内のパッケージ URL 一覧を確認 *)
GitHubPackageURLs[]
(* -> <|"mypackage" -> "https://github.com/<owner>/mypackage", ...|> *)

(* 3. 新規リポジトリを作成してファイルを初回コミット
      (upload_manifest.json が自動生成され、対象ファイルが一括コミットされる) *)
GitHubCreateRepository["mypackage", Public -> False, Description -> "My WL package"]
(* -> <|"DefaultBranch" -> "main", ...|> *)

(* 4. ファイルを修正した後、リフレッシュ → コミットを一括実行 *)
GitHubRefreshAndCommit["mypackage", "fix: バグ修正"]
(* -> <|"CommitSHA" -> "a1b2c3...", "Branch" -> "main", ...|> *)

(* 5. プルリクエストを作成する場合 *)
GitHubSubmitPullRequest["mypackage",
  "feat: 新機能追加",
  "詳細な変更内容をここに記述する。"]
(* -> <|"PullRequest" -> <|"Number" -> 1, "URL" -> "https://github.com/.../pull/1"|>, ...|> *)

(* 6. オープン PR を一覧表示（ボタン付き Grid） *)
GitHubPullRequestDataset["mypackage"]

(* 7. コミット履歴を表示（ボタン付き Grid） *)
GitHubCommitDataset["mypackage"]

(* 8. 自分のパッケージをダウンロード *)
GitHubInstallPackage["fact", Owner -> "transreal"]

(* 9. 他人のリポジトリを URL 指定でインストール *)
GitHubInstallPackage["pkg", "https://github.com/alice/repo"]
(* -> owner と repository が repo_database.json に自動登録される *)
```

**主要オプション（既定値）:**

| オプション | 既定値 | 説明 |
|-----------|--------|------|
| `Owner` | `Automatic` | GitHub ユーザー名（省略時はトークンから自動取得、または RepoDB から解決） |
| `Repository` | `Automatic` | リポジトリ名（省略時は packageName、非 ASCII なら自動翻訳） |
| `Branch` | `Automatic` | 操作対象ブランチ |
| `BaseBranch` | `Automatic` | デフォルトブランチ（API から自動取得） |
| `Public` | `False` | `True` で公開リポジトリ作成 |
| `CreateBranch` | `Automatic` | ブランチ不在時に自動作成するか（`Branch =!= BaseBranch` なら `True`） |
| `DeleteMissing` | `False` | ローカルに無いリモートファイルを削除するか |
| `MaxItems` | `30` | `GitHubListCommits` / `GitHubCommitDataset` で取得するコミット数の上限 |
| `ExtraDirectories` | `{}` | マニフェストに永続追加するディレクトリのリスト（例: `{"Claude Directives"}`） |
| `Fallback` | `False` | `True` で API 制限時に代替モデルでの処理を有効化 |

### 主な機能

#### URL / リポジトリ情報

- **`GitHubPackageURL[name]`** — `$packageDirectory` 内パッケージの GitHub URL を返す
- **`GitHubPackageURLs[]`** — 全パッケージの `<|name -> url|>` を返す
- **`GitHubRepoPath[name]`** — ローカル作業フォルダのパスを返す
- **`GitHubEnsureLocalRepo[name]`** — ローカル作業フォルダを作成して返す

#### マニフェスト / ローカル同期

- **`GitHubReadManifest[name]`** — `packageName_info/upload_manifest.json` を読む（不在時は自動生成）。パッケージ種別変更時は自動更新
- **`GitHubRefreshLocalPackageGroup[name]`** — マニフェストに従いファイルをローカル作業フォルダへコピー。`_info/originals/` の内容を元のリポジトリパスへ書き戻す処理（`iRestoreOriginalsToRepo`）も実行する
- **`GitHubRefreshLocalPackage[name]`** — `.wl` 単体をローカルへコピー（後方互換用）

#### リポジトリ操作

- **`GitHubCreateRepository[name]`** — GitHub に新規リポジトリを作成し、ファイルを初回コミット。`ExtraDirectories` でマニフェストにディレクトリを追加可能
- **`GitHubReadFile[name, path]`** — GitHub 上のファイルを読み取る
- **`GitHubPull[name]`** — リモートの内容をローカル作業フォルダへ取得
- **`GitHubCommit[name, message]`** — ローカル作業フォルダの内容を GitHub へ一括コミット。blob 作成時のエラーは `Catch`/`Throw` パターンで確実に伝播され、エントリ空・SHA 欠落・空文字列も検出する
- **`GitHubRefreshAndCommit[name, message]`** — リフレッシュ → コミットを一括実行。`ExtraDirectories` でマニフェストにディレクトリを追加可能

#### プルリクエスト管理

- **`GitHubSubmitPullRequest[name, title, message]`** — refresh → branch 作成 → commit → PR 作成を一括実行。ブランチ名は `pr/packageName/日時-slugified-title` で自動生成
- **`GitHubListPullRequests[name]`** — オープン PR 一覧を優先度・依存関係でソートして返す
- **`GitHubPullRequestDataset[name]`** — PR 一覧を Review / Pull / Merge / Close ボタン付き Grid で返す
- **`GitHubMergePullRequest[name, prNumber, reason]`** — PR をマージする（理由をコメントとして記録）
- **`GitHubClosePullRequest[name, prNumber, reason]`** — PR をクローズする（理由をコメントとして記録）
- **`GitHubReviewPullRequest[name, prNumber]`** — PR のコードをダウンロードしてノートブックに CellGroup として出力する
- **`GitHubCreatePullRequest[name, title]`** — PR を作成する。head と base が同一ブランチの場合はエラーメッセージで代替手段を案内

#### コミット履歴管理

- **`GitHubListCommits[name]`** — リポジトリのコミット履歴をリストで返す。オプション: `Owner`, `Repository`, `Branch`, `MaxItems`
- **`GitHubCommitDataset[name]`** — コミット履歴を Review / Pull / Revert ボタン付き Grid で表示する。表示時に既存スナップショットを削除して現在の作業状態を新規保存し、#0 行（ローカル最新版）への復元ボタンも表示される。Grid はタグ付き Output セルとして出力され、再実行時に古いセルは自動削除される。オプション: `Owner`, `Repository`, `Branch`, `MaxItems`
- **`GitHubReviewCommit[name, sha]`** — 指定コミットの詳細・差分をノートブックに CellGroup として表示する。Pull / Revert ボタン付き
- **`GitHubRevertCommit[name, sha, reason]`** — 指定コミットの変更を打ち消すリバートコミットを作成する（親コミットの tree を使用）

#### リポジトリ名データベース（日本語対応）

- **`GitHubRepoDB[]`** — `repo_database.json` の全レコードを返す
- **`GitHubRepoDBSet[name, repoName]`** — パッケージ名 → リポジトリ名の対応を登録
- **`GitHubRepoDBSet[name, repoName, owner]`** — パッケージ名 → リポジトリ名 + owner を登録。他人のリポジトリをインストールする際に `GitHubInstallPackage[name, url]` が自動的に呼び出す
- **`GitHubRepoDBLookup[name]`** — DB からリポジトリ名を解決（未登録なら `name` をそのまま返す）

未登録の非 ASCII パッケージ名は [claudecode](https://github.com/transreal/claudecode) の Claude API を呼び出して意味のある英語リポジトリ名を 3 候補生成し、GitHub 上の重複を確認した上で自動登録します。全候補が重複する場合はサフィックス（`-2` ～ `-20`）または日付が付与されます。RepoDB に `owner` が登録されている場合、`iResolveOwner` はトークンからの自動取得よりも RepoDB の値を優先します。

#### パッケージ管理

- **`GitHubInstallPackage[name]`** — GitHub から `$packageDirectory` へ初回ダウンロード。`Owner` オプションで所有者を指定可能
- **`GitHubInstallPackage[name, url]`** — GitHub URL を直接指定して他者のリポジトリをインストール。`url` から owner・repository 名を解析して `repo_database.json` に自動登録し、以後はパッケージ名だけで操作できる
- **`GitHubUpdatePackage[name]`** — 既存パッケージを GitHub 最新版に更新（内部的に `GitHubInstallPackage` と同じ処理）

#### グローバル変数

- **`$GitHubLicenseHolder`** — MIT ライセンスの著作権者名。空文字列 `""` の場合、ライセンスセクションは `README.md` に挿入されません。例: `$GitHubLicenseHolder = "Katsunobu Imai"`

### ドキュメント一覧

| ファイル | 内容 |
|---------|------|
| `api.md` | 全関数・オプションのリファレンス |
| `setup.md` | セットアップガイド（要件・インストール・API キー設定・トラブルシューティング） |
| `user_manual.md` | 各関数の詳細な使い方と引数説明 |
| `example.md` | 典型的なユースケースのコード例 |

リポジトリ: [https://github.com/transreal/github](https://github.com/transreal/github)

## 使用例・デモ

### 新規パッケージのリポジトリ作成

```wolfram
(* パッケージの GitHub リポジトリを作成してファイルを初回アップロード *)
GitHubCreateRepository["mypackage", 
  Public -> True,
  Description -> "My Wolfram Language package",
  ExtraDirectories -> {"Claude Directives"}]
```

### 既存パッケージの更新とプルリクエスト

```wolfram
(* パッケージを更新してプルリクエストを作成 *)
GitHubSubmitPullRequest["mypackage",
  "feat: 新機能追加", 
  "詳細な変更内容を記述"]

(* プルリクエスト一覧を表示（レビュー・マージボタン付き） *)
GitHubPullRequestDataset["mypackage"]
```

### 他者のリポジトリをインストール

```wolfram
(* GitHub URL を指定して他人のパッケージをインストール *)
GitHubInstallPackage["ResistorBuilder", 
  "https://github.com/dzhang314/ResistorBuilder"]

(* 以降はパッケージ名だけで操作可能 *)
GitHubCommitDataset["ResistorBuilder"]
```

### コミット履歴の管理

```wolfram
(* コミット履歴を表示（レビュー・プル・リバートボタン付き） *)
GitHubCommitDataset["mypackage", MaxItems -> 50]

(* 特定コミットの詳細をレビュー *)
GitHubReviewCommit["mypackage", "a1b2c3d4e5f6..."]
```

### 日本語パッケージ名の自動対応

```wolfram
(* 日本語パッケージ名でもリポジトリ名を自動翻訳 *)
GitHubCreateRepository["情報工学科時間割"]
(* -> 自動的に "jouhou-timetable" などの英語リポジトリ名を生成 *)
```

## 免責事項

本ソフトウェアは "as is"（現状有姿）で提供されており、明示・黙示を問わずいかなる保証もありません。
本ソフトウェアの使用または使用不能から生じるいかなる損害についても責任を負いません。
今後の動作保証のための更新が行われるとは限りません。
本ソフトウェアとドキュメントはほぼすべてが生成AIによって生成されたものです。
Windows 11上での実行を想定しており、MacOS, LinuxのMathematicaでの動作検証は一切していません(生成AIの処理で対応可能と想定されます)。

## ライセンス

```
MIT License

Copyright (c) 2026 Katsunobu Imai

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.