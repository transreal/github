# Package auto-commit — 実行例集 (github.wl)

任意のローカルパッケージを GitHub へオートコミットする支援関数群（旧 `PackageAutoCommit.wl`、**github.wl に統合**）の使い方と、`SourceVault_promptrouter` 連携（プロンプトから呼ぶ）の実行例。
本書のコードはすべて wolframscript / ノートブックで検証済みの API に基づく。

- これらの関数（`PackageDocsFreshnessGate` / `PackageCommitDiff` / `PackageCommitPlan` / `PackageCommit` / `PackageCommitDeletionPreview` / `PackageLLMMessageGenerator`）は **`github.wl` をロードすれば使える**（`GitHubREST\`` context）。
- 副作用について: 実コミット（`GitHubRefreshAndCommit`）と実 deposit 以外は ReadOnly。`PackageCommit` の既定は `"DryRun" -> True`。

---

## 0. ロード

```wolfram
Block[{$CharacterEncoding = "UTF-8"}, Get["github.wl"]];
(* これだけで PackageDocsFreshnessGate / PackageCommitDiff / PackageCommitPlan /
   PackageCommit / PackageCommitDeletionPreview / PackageLLMMessageGenerator が使える *)
```

公開シンボル: `PackageDocsFreshnessGate`, `PackageCommitDiff`, `PackageCommitPlan`, `PackageCommit`, `PackageCommitDeletionPreview`, `PackageLLMMessageGenerator`, `$PackageCommitModel`, `$PackageAutoCommitVersion`。

---

## 1. ドキュメント鮮度ゲート — `PackageDocsFreshnessGate[pkg]`

`<pkg>_info/docs/` の `api.md` / `api_*.md` が、対応する `.wl`（`api.md ↔ <pkg>.wl`, `api_<suffix>.md ↔ <pkg>_<suffix>.wl`）以降に更新されているか検査する。古ければ `Proceed -> False`。

```wolfram
PackageDocsFreshnessGate["github"]
(* => <|"Status"->"OK", "Package"->"github", "Proceed"->True,
        "Checked"->1, "StaleDocs"->{}, "DocsDir"->"...github_info\\docs"|> *)

PackageDocsFreshnessGate["SourceVault"]
(* => Proceed->False, Checked->11, StaleDocs に 6 件
      (api_crypto/maildb/mcp/searchindex/servicemanager/webingest.md が
       対応 .wl より古い)。各要素 <|"Doc","Wl","DocDate","WlDate"|> *)

PackageDocsFreshnessGate["存在しないパッケージ"]
(* => <|"Status"->"NoDocs", "Proceed"->True, "Checked"->0, ...|>  (docs 無し → 通過) *)
```

対応 `.wl` が無い api ドキュメントは検査対象外。

> 内部的には、doc 生成ツール（`ClaudeUpdateDocumentation` 等）が doc 生成成功時や「最新です」判定時に記録するコンテンツハッシュ（サイドカー記録）も鮮度判定の一次情報として使われる。ハッシュが未記録（まだ doc 生成／判定していない）か、記録が読めない場合のみ、上記の `.wl` との更新日時（mtime）比較にフォールバックする。

---

## 2. 前回コミットとの差分 — `PackageCommitDiff[pkg]`

現ソース（`$packageDirectory`）と前回コミットのスナップショット（`GithubRepositories/<pkg>/`）を比較。
`upload_manifest.json` を直接 Import する **ReadOnly**（`GitHubReadManifest` は manifest を自動編集するため呼ばない）。

```wolfram
PackageCommitDiff["github"]
(* => <|"Status"->"OK", "SnapshotExists"->True,
        "Added"->{}, "Changed"->{}, "Removed"->{},
        "UnchangedCount"->8, "ChangeCount"->0,
        "Summary"->"added 0, changed 0, removed 0", ...|> *)

PackageCommitDiff["SourceVault"]
(* => ChangeCount->8,
      "Added"->{"SourceVault_info/design/..._v1.md", "..._v2.md"},
      "Changed"->{"SourceVault_crypto.wl", "SourceVault_maildb.wl",
                  "SourceVault_mcp.wl", ...},  (* 相対パス・変更種別 *)
      "Summary"->"added 2, changed 6, removed 0" *)
```

`manifest` の `excludePatterns`（既定 `<pkg>_info/history/`, `<pkg>_info/references/`, `<pkg>_info/docs/docs/`）と前方マッピング（files=basename, directories=相対パス）を `iRefreshPackageGroup` と同形で再現する。差分はリフレッシュ前に取ること（リフレッシュ後はスナップショットが上書きされ差分が消える）。

> `<pkg>_info/docs/docs/`（ネストした `docs` フォルダの重複）はマニフェストの有無に関わらず常に保護される既定除外パターンで、2026-07-08 に追加された。過去の同期事故で紛れ込んだこのネスト重複が `GitHubPull` のたびにローカルへ再生成され、doc 更新の対象が膨張 → push で再コミット、という永久ループを起こしていたため、これを断つための保護。**保護パターンに該当するファイルは `DeleteMissing -> True` でも削除されない**ので、不要になった場合は手動で削除する必要がある（削除しないとツリーに残り続ける）。

`ChangedDetail`（各ファイルの `<|"Rel", "Src", "Snap"|>`）は **変更ファイルと追加ファイルの両方**を含む（追加ファイルは `Snap` が存在しないパス＝全行が新規）。§5 の LLM メッセージ生成が「追加ファイルの中身」も要約できるのはこのため。

---

## 3. 計画 — `PackageCommitPlan[pkg, opts]`

ゲート → 差分 → メッセージ案を ReadOnly に組み立てる。

```wolfram
PackageCommitPlan["github"]
(* docs 最新だが差分なし => <|"Status"->"NoChange", "Proceed"->False, "Diff"->..|> *)

PackageCommitPlan["SourceVault"]
(* docs が古い => <|"Status"->"Blocked", "Proceed"->False,
                    "Reason"->"StaleDocs (...)", "StaleDocs"->{..}|> *)
```

ゲート通過かつ差分ありのときだけ `Status -> "OK"` で `CommitMessage` を返す。

```wolfram
(* メッセージ生成方式を指定 *)
PackageCommitPlan["mypkg", "MessageGenerator" -> Automatic]        (* 既定: claudecode ロード済みなら LLM 内容ベース、無ければ決定論 *)
PackageCommitPlan["mypkg", "MessageGenerator" -> "手動の固定文"]    (* 固定文字列 *)
PackageCommitPlan["mypkg", "MessageGenerator" -> (myFn[#] &)]      (* diff を受け取る関数 *)
```

`MessageGenerator -> Automatic`（既定）は `$PackageCommitModel` で挙動が決まる（§5.6）。**既定ではさらに `$PackageCommitModel` も `Automatic` で、claudecode がロード済みなら周囲の既定モデルで内容ベースのメッセージを生成する。**

決定論メッセージ（claudecode 未ロード時のフォールバック、または `$PackageCommitModel = None`）の形: 「basename 列挙（最大 3 件、超過は先頭 2＋ほか N 件）を 更新／追加／削除、で連結」。
例: `claudecode.wl, CLAUDE.md を更新`、`c1.wl, c2.wl ほか 3 件 を更新、p.wl, q.wl を追加、old.wl を削除`。

### `SkipDocsGate`（docs 鮮度ゲートの一時スキップ／**DryRun 限定**）

```wolfram
PackageCommitPlan["SourceVault", "SkipDocsGate" -> True]
(* docs が古くてもゲートを飛ばして Status->"OK"+CommitMessage を返す（プレビュー用途） *)
```

> **`SkipDocsGate` は DryRun のプレビューでしか効かない。** `PackageCommit[..., "DryRun" -> False]` の実コミットでは `SkipDocsGate -> True` を指定しても **必ず**ゲートで止まる（§4）。docs 陳腐化のまま実コミットしてしまう事故を防ぐため。

---

## 4. コミット駆動 — `PackageCommit[pkg, opts]`

`PackageCommitPlan` を実行し、`Status -> "OK"` のときだけ `GitHubRefreshAndCommit[pkg, CommitMessage]` を呼ぶ。
**既定は `"DryRun" -> True`（実コミットしない）**。

```wolfram
(* DryRun: 計画とメッセージ案を確認するだけ (副作用なし) *)
PackageCommit["github"]
(* => Status->"NoChange" / "Blocked" / "DryRun"(OKのとき) のいずれか, Committed->False *)

(* 実コミット (要 github.wl + トークン)。
   docs 古い / 差分なしなら安全に短絡して Committed->False *)
PackageCommit["github", "DryRun" -> False]
```

`Status`: `DryRun` | `Committed` | `Blocked`(docs 古い) | `NoChange` | `Failed`。
**実コミットでも、docs 古い or 差分なしなら止まる**（ゲート→計画の判定をそのまま使う）。

### `SkipDocsGate` は DryRun 専用（安全設計）

```wolfram
(* DryRun のプレビューでは SkipDocsGate でゲートを飛ばせる *)
PackageCommit["SourceVault", "DryRun" -> True, "SkipDocsGate" -> True]["CommitMessage"]
(* => docs 古くてもメッセージ案が返る *)

(* 実コミットでは SkipDocsGate -> True でも必ず止まる *)
PackageCommit["SourceVault", "DryRun" -> False, "SkipDocsGate" -> True]
(* => Status->"Blocked", Committed->False。docs 古いまま実コミットしない *)
```

内部的には `PackageCommitPlan[pkg, ..., "SkipDocsGate" -> (skipGate && dry)]` として、`DryRun -> False` のときは `SkipDocsGate` を無効化している。実コミットが `Blocked` になると `Message[PackageCommit::staledocs, pkg, docNames]` の警告を出し、`"CommitMessage"` には理由入りの `Missing["StaleDocs", ...]` を返す（`Missing["KeyAbsent", ...]` のような不親切な出力にはならない）。

### `DeleteMissing`（リモート残骸の削除・既定 `False`）

```wolfram
PackageCommit["mypkg", "DryRun" -> False, "DeleteMissing" -> True]
```

`"DeleteMissing" -> True` にすると、`GitHubRefreshAndCommit[pkg, CommitMessage, "DeleteMissing" -> True]` として転送され、ローカルミラーに存在しないリモート blob（GitHub 側で手動削除した／過去の同期事故で紛れ込んだ残骸など）がコミットで削除される。既定 `False`（安全側）。
**`True` にする前には必ず `PackageCommitDeletionPreview[pkg]`（§4.5）で削除候補を確認すること。**

---

## 4.5. 削除プレビュー — `PackageCommitDeletionPreview[pkg]`（`DeleteMissing` 前に必ず確認）

`PackageCommit[..., "DeleteMissing" -> True]` で削除される対象（リモート tree にあってローカルミラーに無い blob）を、`GitHubCommit` の `DeleteMissing` 計算（リモート tree − ローカルミラー）と同じロジックで、**実行せずに** 列挙する読み取り専用関数。

```wolfram
PackageCommitDeletionPreview["SourceVault"]
(* => <|"WouldDelete"->{"old/removed_file.wl", ...},
        "RemoteCount"->42, "LocalCount"->39|> *)
```

- `WouldDelete` はソート済みの相対パスリスト（削除対象＝リモートにあってミラーに無いもの全部）。空なら削除候補なし。
- §2 の除外パターンで保護されたミラー内ファイル（`<pkg>_info/docs/docs/` 等）は先にミラーから除外して比較するため、`WouldDelete` には現れない。保護パターン該当ファイルは `DeleteMissing -> True` でも削除されないので、不要なら手動削除が必要。
- 同じ式を読み取り専用で再現するだけで、リモートにもミラーにも一切手を触れない。

---

## 5. LLM メッセージ生成 — `PackageLLMMessageGenerator[queryFn, opts]`（v0.5.0: content-aware）

LLM で単文コミットメッセージを生成する `MessageGenerator`（`diff -> String`）を返す。
**既定で実際の変更行（`- 削除 / + 追加`）をプロンプトに含め**、「どのファイルが変わったか」ではなく「何をしたか（機能追加・不具合修正・挙動変更）」を要約させる。

**追加ファイルの中身も含まれる**: 変更ファイルだけでなく**新規追加ファイルの内容**もプロンプトに入る（`(新規ファイル)` マーカー付き・全行が `+`）。「◯◯.md を追加」のような自明な羅列でなく、追加物の**目的**を反映したメッセージになる。各ファイルには公平なバジェット（`Min[MaxPerFileChars, Max[300, Ceiling[MaxContentChars/ファイル数]]]`）を割り当て、ファイル数が多くても新規ファイルがプロンプトから落ちないようにしている。

### queryFn — 関数 or モデル指定子

`queryFn` は `prompt -> String` の関数。**モデル指定子（tuple `{provider, model}` または モデル名 String）を渡すと `ClaudeCode\`ClaudeQueryBg[prompt, Model -> spec]` で自動ラップ**する（要 claudecode ロード）。

```wolfram
(* (a) モデル指定子をそのまま渡す ($iModelSonnet = {"claudecode","claude-sonnet-4-6"} 等) *)
PackageCommit["claudecode", "DryRun" -> True,
  "MessageGenerator" -> PackageLLMMessageGenerator[$iModelSonnet, "MaxChars" -> 80]]["CommitMessage"]

(* (b) 自前の prompt -> String 関数を渡す *)
PackageLLMMessageGenerator[Function[p, ClaudeCode`ClaudeQueryBg[p, Model -> $iModelSonnet]]]

(* (c) 既定モデル *)
PackageLLMMessageGenerator[ClaudeCode`ClaudeQueryBg]
```

> **注意**: tuple/モデル名を渡さず `$iModelSonnet` のような「関数でない値」を素で渡しても、`queryFn[prompt]` が文字列を返さず**決定論フォールバック**（ファイル名の羅列）になる。v0.5.0 で tuple/String は自動ラップされるので `$iModelSonnet` がそのまま使える。

### オプション

| オプション | 既定 | 説明 |
|---|---|---|
| `"MaxChars"` | 80 | メッセージの目安文字数 |
| `"IncludeContent"` | True | 変更行を model に送る。`False` でファイル名のみ（低 privacy） |
| `"MaxContentChars"` | 4000 | プロンプトに含める変更内容の合計上限 |
| `"MaxPerFileChars"` | 1500 | ファイル毎の変更内容上限 |

> **privacy**: `IncludeContent -> True` は変更行（ソース）を model に送る。cloud model（Sonnet 等）を使う場合は承知の上で。社外秘コードは `IncludeContent -> False` か local model を。

### 挙動・フォールバック

- LLM 応答は整形（code fence マーカー行を除去・**本文は保持**、先頭非空行、前後引用符除去）。
- `queryFn[prompt]` が文字列を返さない / 空のときは決定論メッセージにフォールバック。
- mock で LLM 無し検証可能:

```wolfram
PackageLLMMessageGenerator[Function[prompt, "core の依存を修正"]][PackageCommitDiff["claudecode"]]
(* => "core の依存を修正" (mock の戻り値) *)
```

行差分はハッシュ集合ベース（O(n)）で、巨大ファイル（claudecode.wl ~28000 行）でも高速。`PackageCommitDiff` の `ChangedDetail`（各ファイルの `Rel`/`Src`/`Snap`）を使う。

### 5.6 既定モデル `$PackageCommitModel`（既定で内容ベース／`MessageGenerator` 不要）

`"MessageGenerator" -> Automatic`（＝未指定）のときの**既定コミットメッセージモデル**。

**既定 `Automatic` は、claudecode がロード済みなら周囲の既定モデル（`$ClaudeModel`）で差分内容を要約した LLM メッセージを自動生成する。** モデルの明示設定は不要 —— `PackageCommit["pkg", "DryRun" -> True]["CommitMessage"]` がそのまま内容ベースのメッセージを返す。claudecode 未ロード時や LLM 失敗時は決定論的なファイル名列挙にフォールバックする。

```wolfram
(* 何も設定しなくても内容ベース（claudecode ロード済みが前提） *)
PackageCommit["SourceVault", "DryRun" -> True]["CommitMessage"]
(* => "packageapiアダプタを追加しapi.mdを関数粒度で索引化・検索、MCPとauxに配線しAPIリファレンスを新設。" *)
```

| `$PackageCommitModel` | 意味 |
|---|---|
| `Automatic`（既定） | claudecode ロード済み → 周囲の既定モデルで内容ベース生成／未ロード・失敗 → 決定論フォールバック |
| モデル指定子（tuple `{provider, model}` 例 `$iModelSonnet` / モデル名 String / `prompt->String` 関数） | そのモデル・関数で生成 |
| `None` | LLM を呼ばず**決定論的なファイル名列挙に固定**（opt-out） |

```wolfram
(* 特定モデルに固定したいとき *)
$PackageCommitModel = $iModelSonnet;   (* 例: {"claudecode", "claude-sonnet-4-6"} *)

(* LLM を呼ばせたくない（従来の決定論メッセージ）とき *)
$PackageCommitModel = None;
```

- 再ロードしても値は保持（`If[! ValueQ[...], $PackageCommitModel = Automatic]` で初期化）。
- 都度だけモデルを変えたいときは `"MessageGenerator" -> PackageLLMMessageGenerator[$iModelSonnet]` を渡す（明示指定が `$PackageCommitModel` より優先）。
- モデル指定子は `PackageLLMMessageGenerator[$PackageCommitModel]` として解決され、§5 のオプション（`IncludeContent` など）は既定値が使われる。

> **注意（LLM 呼び出し）**: 既定 `Automatic` では `PackageCommitPlan` / `PackageCommit`（DryRun 含む）を呼ぶたびに LLM が 1 回走る。plan の結果を変数に束ねれば（`p = PackageCommit[...]; p["CommitMessage"]`）多重呼び出しにはならない。LLM を止めたいときは `$PackageCommitModel = None`。
> **privacy**: 内容ベース生成は変更行（ソース）を model に送る。cloud model を使う環境では承知の上で。社外秘コードは `$PackageCommitModel = None`（決定論）か local model、または `"MessageGenerator" -> PackageLLMMessageGenerator[<local>, "IncludeContent" -> False]` を。

---

## 6. SourceVault PromptRouter 連携（プロンプトから呼ぶ）

`PackageCommitPlan`（ReadOnly）を SourceVault PromptRouter の **FunctionRoute** として登録すると、プロンプトから呼べる。

### 6.0 ロード

```wolfram
Block[{$CharacterEncoding = "UTF-8"},
  Get["ClaudeOrchestrator.wl"];   (* handler allowlist 拡張点を提供 *)
  Get["github.wl"];               (* ロード末尾で PackageCommitPlan を自動弱登録 *)
  Get["SourceVault.wl"]];         (* PromptRouter *)
```

> `ClaudeOrchestrator` がロード済みのとき、`github.wl` はロード末尾で
> `PackageCommitPlan` を ReadOnly handler として自動登録する（`ClaudeOrchestrator\`ClaudeWorkflowRegisterHandler` 経由）。

### 6.1 handler allowlist と merge view 確認

```wolfram
ClaudeOrchestrator`ClaudeWorkflowHandlerAllowlist[]
(* => <|"PackageCommitPlan" -> <|"FunctionId"->"PackageCommitPlan",
        "Symbol"->PackageCommitPlan, "UseAsFunctionRoute"->True,
        "SideEffectClass"->"ReadOnly", "OwnerPackage"->"PackageAutoCommit"|>|> *)

(* router 側のマージビュー (SourceVault 所有 + Orchestrator 所有 handler) *)
SourceVault`SourceVaultCallableAllowlistView[]
(* => Keys に "PackageCommitPlan" が含まれる
      (+ SourceVaultUpcomingSchedule / FindNotebooks / NewNotebook) *)
```

別パッケージの callable を登録するには:

```wolfram
ClaudeOrchestrator`ClaudeWorkflowRegisterHandler["MyReadOnlyFn",
  <|"Symbol" -> MyPkg`MyReadOnlyFn, "UseAsFunctionRoute" -> True,
    "UseAsHandlerRef" -> True, "SideEffectClass" -> "ReadOnly",
    "OwnerPackage" -> "MyPkg"|>]
```

### 6.2 FunctionRoute を登録（pkg を `Target.Args` で宣言）

ルーターを package 集合に結合しないため、引数はルートの `Target.Args` で宣言する（per-package route）。

```wolfram
SourceVault`SourceVaultRegisterPromptRoute[<|
  "Type"    -> "PromptRoute",                       (* 必須 *)
  "RouteId" -> "pkg-autocommit-github-v1",
  "Matcher" -> <|"KeywordsAny" -> {"github をオートコミット", "github のコミット案"}|>,
  "Target"  -> <|"Kind" -> "Function",
                 "FunctionId" -> "PackageCommitPlan",
                 "Args" -> {"github"}|>,            (* pkg を baked *)
  "Privacy" -> <|"PrivacyLevel" -> 0.0|>,
  "Source"  -> "Manual"|>,
  "DryRun"  -> False]                                (* False で実書き込み *)
(* => WrittenCount -> 1 *)
```

> 別パッケージは別ルート（`Args -> {"SourceVault"}` 等、対応する KeywordsAny）を登録する。

### 6.3 解決 → 提案（pkg 充填・未評価）

```wolfram
SourceVault`SourceVaultResolvePromptRoute["github をオートコミットして"]
(* => Status->"Matched", Target.FunctionId->"PackageCommitPlan", Target.Args->{"github"} *)

prop = SourceVault`SourceVaultProposePromptRoute["github をオートコミットして"];
prop["ProposedExpression"]
(* => HoldComplete[PackageCommitPlan["github"]]   (pkg 充填・未評価のまま; spec 5.2) *)
prop["Decision"]["Args"]   (* => {"github"} *)
```

`ProposedExpression` は **未評価の `HoldComplete[...]`**。ClaudeEval / 呼び出し側がこれを受け取り、ReadOnly なので確認の上で評価できる。

### 6.4 ルート削除（後始末）

```wolfram
SourceVault`SourceVaultDeletePromptRoute["pkg-autocommit-github-v1",
  "Confirm" -> True, "DryRun" -> False]
(* => Removed -> 1 *)
```

### 副作用 driver（`PackageCommit`）について

`PackageCommit` は副作用（実コミット）なので **auto-propose されない**（`iSVPRProposeFunctionRoute` は ReadOnly/SafeCreate のみ自動提案。副作用 callable は `NonAutoDispatchSideEffect` で拒否）。
承認付きで呼ぶ正しい経路は、**保存ルート＋承認 UI**（`SourceVaultPromptVersionsUI` でユーザーが Run をクリック）。auto-propose で副作用式を流すのは安全上避ける。

---

## 7. ワーカー成果物の SourceVault 保存（案A: orchestrator 側 deposit）

ClaudeOrchestrator のワーカーは副作用を実行しない producer。メインカーネル（=単一書き手）が各成果物を SourceVault へ append-only deposit し、`sv://` 参照を返す。

### 7.0 前提: deposit 認可プロファイル設定（1 回）

```wolfram
(* ローカル worker 専用 identity に DepositArtifact を許可 (PrivateVault に永続) *)
SourceVault`SourceVaultSetModelAccessProfile["orchestrator-worker", "*", "*",
  <|"AllowedOperations" -> {"DepositArtifact"},
    "TrustDomain" -> "Local", "MaxAccessLevel" -> 0.5|>]
(* => ProfileId -> "orchestrator-worker:*:*", AllowedOperations -> {DepositArtifact} *)
```

> 既定プロファイルの `AllowedOperations` は `{Search, ReadSummary, ReadContext}` で DepositArtifact を含まない（fail-closed）。

### 7.1 成果物を deposit

```wolfram
arts = <|
  "t1" -> <|"TaskId"->"t1", "Status"->"OK",
            "Payload"-><|"Summary"->"diff: SourceVault_mcp.wl 更新", "ChangeCount"->1|>|>,
  "t2" -> <|"TaskId"->"t2", "Status"->"OK",
            "Payload"-><|"Summary"->"gate ok", "Proceed"->True|>|>|>;

ClaudeOrchestrator`ClaudeOrchestratorDepositArtifacts[arts]
(* => <|"Status"->"OK",
        "URIs"->{"sv://artifact/artifact-...", "sv://artifact/artifact-..."},
        "Deposits"-><|"t1"-><|"Status"->"OK","URI"->"sv://artifact/.."|>, "t2"->..|>|> *)
```

- `idempotencyKey` は content hash。同一 artifacts を再 deposit すると同じ URI（冪等）。
- SourceVault 未ロードなら `Status -> "Skipped"`（弱依存）。

### 7.2 ClaudeRunOrchestration に統合

```wolfram
ClaudeRunOrchestration[prompt,
  "DepositArtifacts" -> True,                  (* opt-in: Spawn 後 Reduce 前に deposit *)
  "DepositProvider"  -> "orchestrator-worker"]
(* 結果に "DepositResult" (URIs 等) が付く *)
```

---

## 8. SourceVault `sourcevault_deposit` MCP tool（LLM からの直接 deposit）

LLM（MCP クライアント）が append-only artifact を直接 deposit する。`mode "plan"` はプレビュー（書込なし）、`mode "commit"` は DepositArtifact 認可が必要。

### 8.1 plan（書込なし）

```wolfram
SourceVault`SourceVaultMCPDispatch["tools/call",
  <|"name" -> "sourcevault_deposit",
    "arguments" -> <|"mode" -> "plan",
      "content" -> <|"text" -> "# memo\n..."|>|>|>]
(* => content に "Planned" を含む (継承後の予定 policy / URI 形式) *)
```

### 8.2 commit と grant gating

```wolfram
(* grant 無し / 未認可 provider => RequireGrant (fail-closed) *)
SourceVault`SourceVaultMCPDeposit[<|"mode"->"commit", "content"-><|"text"->"x"|>|>]
(* => Status -> "RequireGrant", RequiredAction -> "DepositArtifact" *)

(* DepositArtifact grant を発行して渡す *)
SourceVault`SourceVaultMCPEnsureGrantKey[];
g = SourceVault`SourceVaultMCPMintAccessGrant[
  <|"AllowedActions" -> {"DepositArtifact"}, "MaxAccessLevel" -> 0.5, "TTLSeconds" -> 300|>];

SourceVault`SourceVaultMCPDeposit[<|
  "mode" -> "commit", "content" -> <|"text" -> "本文"|>,
  "policy" -> <|"privacyLevel" -> 0.3|>, "Grant" -> g|>]
(* => Status -> "OK", ArtifactUri -> "sv://artifact/..." (低 privacy で grant ceiling 内) *)
```

認可は **(a) 有効 grant の `AllowedActions ∋ DepositArtifact`**、または **(b) endpoint AccessProfile の `AllowedOperations ∋ DepositArtifact`**。
privacy approval: `RequiresApproval`（高 privacy / 未裏付け ref）は `"Approved" -> True` か grant/profile の `MaxAccessLevel >= effPL` が無いと `RequireApproval`。
プライバシー継承（§10.7.2）: 同一 Session/Batch の observed-read max を Max 合成（高 privacy を読んだ後に低申告で低分類するのを防ぐ）。

---

## 9. よくある注意点

- これらの関数は `github.wl` に統合済み（`GitHubREST\`` context）。`Get["github.wl"]` だけでよい（旧 `PackageAutoCommit.wl` は削除）。
- `PackageCommit` の既定は `"DryRun" -> True`。実コミットは `"DryRun" -> False`。
- `SkipDocsGate -> True` は **DryRun のプレビュー限定**。実コミット（`DryRun -> False`）では効かず、docs 古ければ必ず `Blocked`。
- `PackageCommit[..., "DeleteMissing" -> True]`（既定 `False`）はリモート残骸ファイルも削除してコミットする。**必ず先に `PackageCommitDeletionPreview[pkg]`（§4.5）で削除候補を確認する。**
- `<pkg>_info/docs/docs/` 等の保護除外パターン（§2）に該当するファイルは `DeleteMissing -> True` でも削除されない。残す必要が無くなったら手動で削除すること。
- 既定（`Automatic`）で claudecode ロード済みなら内容ベースのメッセージが出る。決定論（ファイル名列挙）に固定したいときは `$PackageCommitModel = None`。特定モデルに固定は `$PackageCommitModel = <モデル>` か `"MessageGenerator" -> PackageLLMMessageGenerator[<モデル>]`。既定は plan/commit ごとに LLM が 1 回走る。
- ゲートが多くのパッケージで `Blocked` を返すのは正常（docs が `.wl` より古い）。実コミット前に api ドキュメントを更新する。
- `PackageCommitDiff` / `PackageCommitDeletionPreview` はいずれも `GitHubReadManifest` を呼ばない（あれは manifest を自動編集する非 ReadOnly）。
- route 登録には `"Type" -> "PromptRoute"` が必須。
- 副作用（実コミット・実 deposit）以外はすべて ReadOnly。`mode "plan"` / `DryRun` / `PackageCommitDeletionPreview` で安全に確認できる。
- `SourceVault_promptrouter` のソースは all-ASCII 規約。route の日本語 KeywordsAny は登録データなので問題ない。

---

## 関連

- `github.wl` (`GitHubREST\``) — auto-commit 関数群 (本書) + `GitHubRefreshAndCommit` / `GitHubRepoPath` / `GitHubReadManifest`
- `SourceVault_mcp.wl` — `SourceVaultMCPDeposit` / grant / AccessProfile
- `SourceVault_promptrouter.wl` — `SourceVaultResolvePromptRoute` / `SourceVaultProposePromptRoute` / `SourceVaultRegisterPromptRoute`
- `ClaudeOrchestrator.wl` — `ClaudeOrchestratorDepositArtifacts` / `ClaudeWorkflowRegisterHandler` / `ClaudeWorkflowHandlerAllowlist`