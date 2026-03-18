(* github_fixed.wl -- GitHub REST helper package for Mathematica / Wolfram Language
   This package is designed to work with NBAccess.wl and claudecode.wl.
   Authentication is delegated to NBAccess`NBGetAPIKey["github"].
*)

BeginPackage["GitHubREST`"];

Block[{$CharacterEncoding = "UTF-8"},
  Needs["NBAccess`", "NBAccess.wl"]];

GitHubPackageURL::usage =
  "GitHubPackageURL[\"packageName\"] \:306f $packageDirectory \:5185\:306e\:30d1\:30c3\:30b1\:30fc\:30b8\:306e GitHub URL \:3092\:8fd4\:3059\:3002\n" <>
  "Owner \:30aa\:30d7\:30b7\:30e7\:30f3\:3067\:30e6\:30fc\:30b6\:30fc\:540d\:3092\:6307\:5b9a\:53ef\:80fd\:3002Automatic \:306a\:3089 API \:30c8\:30fc\:30af\:30f3\:304b\:3089\:53d6\:5f97\:3002\n" <>
  "\:4f8b: GitHubPackageURL[\"claudecode\"]";
GitHubPackageURLs::usage =
  "GitHubPackageURLs[] \:306f $packageDirectory \:5185\:306e\:5168\:30d1\:30c3\:30b1\:30fc\:30b8\:306e <|name -> url, ...|> \:3092\:8fd4\:3059\:3002";

GitHubRepoPath::usage =
  "GitHubRepoPath[packageName] はローカル GitHub 作業フォルダのパスを返す。\n" <>
  "仕様: FileNameJoin[{$packageDirectory, \"GithubRepositories\", packageName}]";

GitHubEnsureLocalRepo::usage =
  "GitHubEnsureLocalRepo[packageName] はローカル GitHub 作業フォルダを作成して返す。\n" <>
  "オプション LocalRepoPath -> Automatic で保存先を変更できる。";

GitHubReadManifest::usage =
  "GitHubReadManifest[packageName] は packageName_info/upload_manifest.json を読み\n" <>
  "アップロード対象のファイル・ディレクトリ一覧を Association で返す。\n" <>
  "ファイルが存在しない場合は自動生成してディスクに保存する。\n" <>
  "パッケージ種別 (.wl/パクレット) が変わった場合も自動更新する。";

GitHubRefreshLocalPackageGroup::usage =
  "GitHubRefreshLocalPackageGroup[packageName] は upload_manifest.json に基づき\n" <>
  "対象ファイル・ディレクトリをローカル GitHub 作業フォルダへコピーする。\n" <>
  "_info/docs/README.md が存在すればトップレベル README.md として配置する。";

GitHubRefreshLocalPackage::usage =
  "GitHubRefreshLocalPackage[packageName] は $packageDirectory/packageName.wl を\n" <>
  "ローカル GitHub 作業フォルダへコピーする。(後方互換・単一ファイル用)\n" <>
  "グループアップロードには GitHubRefreshLocalPackageGroup を使用する。";

GitHubCreateRepository::usage =
  "GitHubCreateRepository[packageName] は GitHub 上に新規リポジトリを作成する。\n" <>
  "既定では Public -> False で private repository を作成する。\n" <>
  "upload_manifest.json が存在すれば、対象ファイル群をまとめてコミットする。\n" <>
  "_info/docs/README.md があればトップレベル README.md として配置する。\n" <>
  "作成後、リポジトリが API から参照可能になるまで待機し、default branch を返す。";

GitHubReadFile::usage =
  "GitHubReadFile[packageName, path] は GitHub 上のファイルを読み取る。\n" <>
  "ReturnType -> \"Text\" | \"ByteArray\" | \"Bytes\" を指定可能。";

GitHubPull::usage =
  "GitHubPull[packageName] は指定ブランチのリポジトリ内容をローカル GitHub 作業フォルダへ取得する。";

GitHubCommit::usage =
  "GitHubCommit[packageName, message] はローカル GitHub 作業フォルダの内容を\n" <>
  "GitHub の指定ブランチへコミットする。\n" <>
  "複数ファイルを blob/tree/commit/ref 更新の流れでまとめて反映する。\n" <>
  "BaseBranch -> Automatic のときはリポジトリの default branch を自動使用する。";

GitHubCreatePullRequest::usage =
  "GitHubCreatePullRequest[packageName, title] は pull request を作成する。";

GitHubRefreshAndCommit::usage =
  "GitHubRefreshAndCommit[packageName, message] は upload_manifest.json に基づき\n" <>
  "対象ファイル群をローカル GitHub 作業フォルダへコピーし、GitHub へコミットする。\n" <>
  "_info/docs/README.md が変更されていればトップレベル README.md も自動更新する。";

GitHubSubmitPullRequest::usage =
  "GitHubSubmitPullRequest[packageName, title, message] は\n" <>
  "refresh -> branch 作成 -> commit -> pull request 作成を一発で行う。";

Owner::usage =
  "Owner は GitHub の所有者 (ユーザー名 / 組織名) を指定するオプション。\n" <>
  "Automatic の場合は認証トークンの所有ユーザーを用いる。";

Repository::usage =
  "Repository は GitHub のリポジトリ名を指定するオプション。\n" <>
  "Automatic の場合は packageName を用いる。";

Public::usage =
  "Public は新規作成する GitHub リポジトリを公開にするかどうか。\n" <>
  "既定値は False。";

Description::usage =
  "Description は新規リポジトリ作成時の description。";

Homepage::usage =
  "Homepage は新規リポジトリ作成時の homepage URL。";

AutoInit::usage =
  "AutoInit は新規リポジトリ作成時に README 付きで初期化するかどうか。\n" <>
  "既定値は True。";

GitignoreTemplate::usage =
  "GitignoreTemplate は GitHub の gitignore template 名。";

LicenseTemplate::usage =
  "LicenseTemplate は GitHub の license template 名。";

Branch::usage =
  "Branch は操作対象ブランチを指定するオプション。\n" <>
  "Automatic の場合は BaseBranch を使う。";

BaseBranch::usage =
  "BaseBranch は既定ブランチまたは pull request の base branch を指定する。\n" <>
  "既定値は Automatic で、リポジトリの default branch を API から自動取得する。";

CreateBranch::usage =
  "CreateBranch は GitHubCommit 実行時に対象ブランチが存在しなければ\n" <>
  "BaseBranch から新規作成するかどうか。\n" <>
  "Automatic の場合は Branch =!= BaseBranch なら True。";

LocalRepoPath::usage =
  "LocalRepoPath はローカル GitHub 作業フォルダを明示指定するオプション。";

PackageFile::usage =
  "PackageFile は元の packageName.wl のパスを明示指定するオプション。";

IncludePackageFile::usage =
  "IncludePackageFile は GitHubCommit / GitHubCreateRepository の前に\n" <>
  "packageName.wl をローカル GitHub 作業フォルダへコピーするかどうか。\n" <>
  "既定値は True。";

ReturnType::usage =
  "ReturnType は GitHubReadFile の戻り値型。\n" <>
  "\"Text\" | \"ByteArray\" | \"Bytes\" を指定できる。";

Clean::usage =
  "Clean は GitHubPull 時に既存のローカルファイルを先に削除するかどうか。\n" <>
  "既定値は False。";

Force::usage =
  "Force は ref 更新時に fast-forward 制約を無視するかどうか。\n" <>
  "既定値は False。";

DeleteMissing::usage =
  "DeleteMissing は GitHubCommit 時にローカルに存在しないリモート blob を\n" <>
  "削除対象として tree に含めるかどうか。既定値は False。";

Head::usage =
  "Head は pull request の head を指定するオプション。\n" <>
  "Automatic の場合は Branch を使う。";

Body::usage =
  "Body は pull request 本文。";

Draft::usage =
  "Draft は pull request を draft として作成するかどうか。";

MaintainerCanModify::usage =
  "MaintainerCanModify は pull request で maintainers に head branch の\n" <>
  "編集を許可するかどうか。";

Author::usage =
  "Author は commit author を <|\"name\"->..., \"email\"->...|> の形で指定する。";

Committer::usage =
  "Committer は commit committer を <|\"name\"->..., \"email\"->...|> の形で指定する。";

ExtraDirectories::usage =
  "ExtraDirectories は GitHubCreateRepository / GitHubRefreshAndCommit で\n" <>
  "upload_manifest.json の directories に追加するディレクトリのリスト。\n" <>
  "指定されたディレクトリは manifest に永続的に追加される。\n" <>
  "例: ExtraDirectories -> {\"Claude Directives\"}";


GitHubRepoDB::usage =
  "GitHubRepoDB[] \:306f GithubRepositories/repo_database.json \:3092\:8aad\:307f\:8fbc\:307f\:3001\:5168\:30ec\:30b3\:30fc\:30c9\:3092 Association \:3067\:8fd4\:3059\:3002";
GitHubRepoDBSet::usage =
  "GitHubRepoDBSet[packageName, repoName] \:306f\:30d1\:30c3\:30b1\:30fc\:30b8\:540d\:3068 GitHub \:30ea\:30dd\:30b8\:30c8\:30ea\:540d\:306e\:5bfe\:5fdc\:3092 DB \:306b\:767b\:9332\:3059\:308b\:3002\n" <>
  "GitHubRepoDBSet[packageName, repoName, owner] \:306f owner \:3082\:542b\:3081\:3066\:767b\:9332\:3059\:308b\:3002\n" <>
  "\:65e5\:672c\:8a9e\:30d1\:30c3\:30b1\:30fc\:30b8\:540d\:306e\:5834\:5408\:306b\:82f1\:8a9e\:30ea\:30dd\:30b8\:30c8\:30ea\:540d\:3092\:6307\:5b9a\:3059\:308b\:3002";
GitHubRepoDBLookup::usage =
  "GitHubRepoDBLookup[packageName] \:306f DB \:304b\:3089\:30ea\:30dd\:30b8\:30c8\:30ea\:540d\:3092\:89e3\:6c7a\:3059\:308b\:3002\:672a\:767b\:9332\:306a\:3089 packageName \:3092\:305d\:306e\:307e\:307e\:8fd4\:3059\:3002";

GitHubInstallPackage::usage =
  "GitHubInstallPackage[packageName] \:306f GitHub \:304b\:3089 $packageDirectory \:306b\:30d1\:30c3\:30b1\:30fc\:30b8\:3092\:521d\:56de\:30c0\:30a6\:30f3\:30ed\:30fc\:30c9\:3059\:308b\:3002\n" <>
  "GitHubInstallPackage[packageName, url] \:306f\:4ed6\:4eba\:306e\:30ea\:30dd\:30b8\:30c8\:30ea URL \:304b\:3089\:30a4\:30f3\:30b9\:30c8\:30fc\:30eb\:3059\:308b\:3002\n" <>
  "\:4f8b: GitHubInstallPackage[\"pkg\", \"https://github.com/user/repo\"]\n" <>
  "\:30a4\:30f3\:30b9\:30c8\:30fc\:30eb\:5f8c\:306f GitHubUpdatePackage/GitHubCommitDataset/GitHubSubmitPullRequest \:7b49\:304c\n" <>
  "\:30d1\:30c3\:30b1\:30fc\:30b8\:540d\:3060\:3051\:3067\:30ea\:30e2\:30fc\:30c8\:30ea\:30dd\:30b8\:30c8\:30ea\:306b\:5bfe\:3057\:3066\:52d5\:4f5c\:3059\:308b\:3002\n" <>
  "\:30aa\:30d7\:30b7\:30e7\:30f3 Owner, Repository, Branch \:6307\:5b9a\:53ef\:80fd\:3002";
GitHubUpdatePackage::usage =
  "GitHubUpdatePackage[packageName] \:306f\:65e2\:5b58\:30d1\:30c3\:30b1\:30fc\:30b8\:3092 GitHub \:306e\:6700\:65b0\:306b\:66f4\:65b0\:3059\:308b\:3002";

GitHubListPullRequests::usage =
  "GitHubListPullRequests[packageName] \:306f\:30aa\:30fc\:30d7\:30f3\:306a PR \:4e00\:89a7\:3092\:7dca\:6025\:5ea6\:30fb\:4f9d\:5b58\:95a2\:4fc2\:3067\:30bd\:30fc\:30c8\:3057\:3066\:8fd4\:3059\:3002";
GitHubPullRequestDataset::usage =
  "GitHubPullRequestDataset[packageName] \:306f PR \:4e00\:89a7\:3092 Review/Pull/Merge/Close \:30dc\:30bf\:30f3\:4ed8\:304d Dataset \:3067\:8fd4\:3059\:3002";
GitHubMergePullRequest::usage =
  "GitHubMergePullRequest[packageName, prNumber, reason] \:306f PR \:3092\:30de\:30fc\:30b8\:3059\:308b\:3002";
GitHubClosePullRequest::usage =
  "GitHubClosePullRequest[packageName, prNumber, reason] \:306f PR \:3092\:30af\:30ed\:30fc\:30ba\:3059\:308b\:3002";
GitHubReviewPullRequest::usage =
  "GitHubReviewPullRequest[packageName, prNumber] \:306f PR \:306e\:30b3\:30fc\:30c9\:3092\:30c0\:30a6\:30f3\:30ed\:30fc\:30c9\:3057\:3001\n" <>
  "\:30ec\:30d3\:30e5\:30fc\:7528\:30b3\:30fc\:30c9\:3092\:30ce\:30fc\:30c8\:30d6\:30c3\:30af\:306b\:51fa\:529b\:3059\:308b\:3002";

GitHubListCommits::usage =
  "GitHubListCommits[packageName] \:306f\:30ea\:30dd\:30b8\:30c8\:30ea\:306e\:30b3\:30df\:30c3\:30c8\:5c65\:6b74\:3092\:53d6\:5f97\:3057\:3066\:30ea\:30b9\:30c8\:3067\:8fd4\:3059\:3002\n" <>
  "\:30aa\:30d7\:30b7\:30e7\:30f3: Owner, Repository, Branch, MaxItems\:3002";
GitHubCommitDataset::usage =
  "GitHubCommitDataset[packageName] \:306f\:30b3\:30df\:30c3\:30c8\:5c65\:6b74\:3092 Review/Pull/Revert \:30dc\:30bf\:30f3\:4ed8\:304d Grid \:3067\:8868\:793a\:3059\:308b\:3002\n" <>
  "\:30aa\:30d7\:30b7\:30e7\:30f3: Owner, Repository, Branch, MaxItems\:3002";
GitHubReviewCommit::usage =
  "GitHubReviewCommit[packageName, sha] \:306f\:6307\:5b9a\:30b3\:30df\:30c3\:30c8\:306e\:8a73\:7d30\:30fb\:5dee\:5206\:3092\:30ce\:30fc\:30c8\:30d6\:30c3\:30af\:306b\:8868\:793a\:3059\:308b\:3002";
GitHubRevertCommit::usage =
  "GitHubRevertCommit[packageName, sha] \:306f\:6307\:5b9a\:30b3\:30df\:30c3\:30c8\:306e\:5909\:66f4\:3092\:5143\:306b\:623b\:3059\:30ea\:30d0\:30fc\:30c8\:30b3\:30df\:30c3\:30c8\:3092\:4f5c\:6210\:3059\:308b\:3002";
MaxItems::usage =
  "MaxItems \:306f GitHubListCommits/GitHubCommitDataset \:3067\:53d6\:5f97\:3059\:308b\:30b3\:30df\:30c3\:30c8\:6570\:306e\:4e0a\:9650\:3002\:65e2\:5b9a\:5024\:306f 30\:3002";

$GitHubLicenseHolder::usage =
  "$GitHubLicenseHolder \:306f MIT \:30e9\:30a4\:30bb\:30f3\:30b9\:306e\:8457\:4f5c\:6a29\:8005\:540d\:3002\n" <>
  "\:7a7a\:6587\:5b57\:5217 \"\" \:306e\:5834\:5408\:3001\:30e9\:30a4\:30bb\:30f3\:30b9\:30bb\:30af\:30b7\:30e7\:30f3\:306f README.md \:306b\:633f\:5165\:3055\:308c\:306a\:3044\:3002\n" <>
  "\:4f8b: $GitHubLicenseHolder = \"Katsunobu Imai\"";


Begin["`Private`"];

$GitHubAPIBase = "https://api.github.com";

(* ライセンス保持者名 (空文字列ならライセンスは挿入しない) *)
If[!StringQ[$GitHubLicenseHolder], $GitHubLicenseHolder = ""];
$GitHubAPIVersion = "2022-11-28";
$GitHubUserAgent = "Wolfram-GitHubREST/0.2";

(* Undo 再評価防止ガード: ボタン評価の二重実行を防ぐ。
   <|"review:sha" -> True, "review-pr:num" -> True, ...|> *)
If[!AssociationQ[$iGitHubEvalGuard], $iGitHubEvalGuard = <||>];

ClearAll[
  iFailure, iFailureProperty, iStatusCode, iCompactAssociation, iBuildURL,
  iDefaultHeaders, iParseBody, iAPICall, iAccessToken, iResolveOwner,
  iResolveRepository, iResolveBranch, iPackageDirectory, iLocalRepoPath,
  iPackageFilePath, iEnsureDirectory, iEncodePathPreservingSlash,
  iNormalizeGitPath, iGetRef, iCreateRef, iUpdateRef, iGetCommitObject,
  iCreateBlob, iCreateTree, iCreateCommit, iGetTreeRecursive,
  iReadLocalByteArray, iWriteLocalByteArray, iRelativeGitPath, iListLocalFiles,
  iNormalizePerson, iDecodeGitHubContent, iBranchIfMissing, iGetRepoInfo,
  iWaitForRepoInfo, iWaitForRef, iResolveBaseBranch, iRepoAccessFailure,
  iBranchReadFailure, iRepositoryURL, iSlugifyBranchName, iAutoPRBranchName,
  iForceASCIIJSON, iEncodeJSONBody,
  iManifestPath, iDefaultManifest, iReadManifest, iWriteManifest,
  iEnsureManifest, iDetectPackageType, iCopyDirectoryFiltered, iAddExtraDirectories,
  iRefreshPackageGroup, iSyncReadme, iMatchExcludePattern, iInfoDirName,
  iLocalSnapshotDir, iSaveLocalSnapshot, iRestoreLocalSnapshot,
  iCopyLocalRepoToPackageDir, iCleanManifestFilesInPkgDir,
  iDetectNewerThanSnapshot, iSnapshotHashPath,
  iDefaultExcludePatterns, iMergedExcludePatterns,
  iCopyDirectoryPreservingExcluded,
  iTranslateToEnglishRepoName, iSlugifyRepoName, iCheckRepoExists,
  iParseGitHubURL, iRepoDBOwnerLookup,
  iIsRemotePackage, iOriginalsDir, iSaveOriginals, iLoadOriginals,
  iRestoreOriginalsToRepo
];

iFailure[tag_String, msg_String, data_: <||>] :=
  Failure[tag, Join[<|"Message" -> msg|>, data]];

(* JSON 文字列中の非 ASCII 文字を \uXXXX エスケープに変換し、
   エンコーディング問題を完全に回避する。
   StringReplace ではなく ToCharacterCode で直接コードポイントを処理する。 *)
iForceASCIIJSON[jsonStr_String] :=
  Module[{codes},
    codes = ToCharacterCode[jsonStr];
    StringJoin[
      Map[
        Function[code,
          If[code < 128,
            FromCharacterCode[{code}],
            If[code <= 16^^FFFF,
              "\\u" <> IntegerString[code, 16, 4],
              Module[{hi, lo},
                hi = Quotient[code - 16^^10000, 16^^400] + 16^^D800;
                lo = Mod[code - 16^^10000, 16^^400] + 16^^DC00;
                "\\u" <> IntegerString[hi, 16, 4] <>
                "\\u" <> IntegerString[lo, 16, 4]
              ]
            ]
          ]
        ],
        codes
      ]
    ]
  ];

(* ExportString[..., "RawJSON"] の出力を安全な ByteArray に変換する。
   Windows 環境では ExportString が日本語等を UTF-8 バイト値として
   文字列に埋め込む場合がある (各文字コード <= 255 かつ 128 以上あり)。
   この場合、ByteArrayToString で UTF-8 として再デコードしてから
   \uXXXX エスケープを適用する。 *)
iEncodeJSONBody[body_] :=
  Module[{jsonRaw, codes, maxCode, hasNonASCII, jsonStr},
    jsonRaw = ExportString[body, "RawJSON"];
    codes = ToCharacterCode[jsonRaw];
    maxCode = Max[codes];
    hasNonASCII = maxCode > 127;
    jsonStr = Which[
      (* 純 ASCII — 変換不要 *)
      !hasNonASCII, jsonRaw,
      (* 全コード <= 255 かつ非ASCII有 — UTF-8 バイト列として再デコード *)
      maxCode <= 255,
        ByteArrayToString[ByteArray[codes], "UTF-8"],
      (* コード > 255 — 既に正しい Unicode *)
      True, jsonRaw
    ];
    StringToByteArray[iForceASCIIJSON[jsonStr], "UTF-8"]
  ];

iFailureProperty[expr_, key_] := Quiet @ Check[expr[key], Missing["NotAvailable"]];
iStatusCode[expr_] := iFailureProperty[expr, "StatusCode"];

iCompactAssociation[assoc_Association] :=
  Association @ Cases[Normal[assoc], (k_ -> v_) /; v =!= None && v =!= Automatic];

iBuildURL[path_String, query_: <||>] :=
  Module[{base, qAssoc, qString},
    base = $GitHubAPIBase <> "/" <> StringTrim[path, "/"];
    qAssoc = Association[query];
    If[Length[qAssoc] == 0, Return[base]];
    qString = StringRiffle[
      KeyValueMap[
        URLEncode[ToString[#1]] <> "=" <> URLEncode[ToString[#2]] &,
        qAssoc
      ],
      "&"
    ];
    base <> "?" <> qString
  ];

iDefaultHeaders[token_String] := {
  "Accept" -> "application/vnd.github+json",
  "Authorization" -> "Bearer " <> token,
  "X-GitHub-Api-Version" -> $GitHubAPIVersion,
  "User-Agent" -> $GitHubUserAgent
};

iParseBody[body_] := Which[
  AssociationQ[body] || ListQ[body], body,
  ByteArrayQ[body], Quiet @ Check[ImportByteArray[body, "RawJSON"], body],
  StringQ[body], Quiet @ Check[ImportString[body, "RawJSON"], body],
  True, body
];

iAPICall[method_String, path_String, token_String, body_: None, query_: <||>] :=
  Module[{url, headers, reqAssoc, req, resp, status, rawBody, parsedBody, respHeaders},
    url = iBuildURL[path, query];
    headers = Join[
      iDefaultHeaders[token],
      If[body === None, {}, {"Content-Type" -> "application/json; charset=utf-8"}]
    ];
    reqAssoc = Join[
      <|"Method" -> method, "Headers" -> headers|>,
      If[body === None, <||>,
        <|"Body" -> iEncodeJSONBody[body]|>
      ]
    ];
    req = HTTPRequest[url, reqAssoc];
    resp = Quiet @ Check[URLRead[req], $Failed];
    If[resp === $Failed || FailureQ[resp],
      Return[iFailure[
        "HTTPRequestFailed",
        "GitHub API への HTTP リクエストに失敗しました。",
        <|"URL" -> url, "Method" -> method|>
      ]]
    ];
    status = Quiet @ Check[resp["StatusCode"], Missing["NotAvailable"]];
    rawBody = Quiet @ Check[resp["BodyByteArray"], None];
    respHeaders = Quiet @ Check[resp["Headers"], {}];
    parsedBody = Which[
      ByteArrayQ[rawBody], Quiet @ Check[ImportByteArray[rawBody, "RawJSON"], ByteArrayToString[rawBody, "UTF-8"]],
      True, rawBody
    ];
    If[IntegerQ[status] && 200 <= status < 300,
      <|
        "StatusCode" -> status,
        "Body" -> parsedBody,
        "RawBody" -> rawBody,
        "Headers" -> respHeaders,
        "URL" -> url
      |>,
      iFailure[
        "GitHubAPIError",
        "GitHub API がエラーを返しました。",
        <|
          "StatusCode" -> status,
          "Body" -> parsedBody,
          "RawBody" -> rawBody,
          "Headers" -> respHeaders,
          "URL" -> url,
          "Method" -> method
        |>
      ]
    ]
  ];

iAccessToken[] :=
  Module[{token},
    token = Quiet @ NBAccess`NBGetAPIKey[
      "github",
      PrivacySpec -> <|"AccessLevel" -> 1.0|>
    ];
    If[StringQ[token] && StringLength[token] > 0,
      token,
      iFailure[
        "MissingGitHubToken",
        "GitHub トークンを取得できません。SystemCredential[\"GITHUB_TOKEN\"] を設定してください。"
      ]
    ]
  ];

iResolveOwner[token_String, Automatic] :=
  Module[{resp, login},
    resp = iAPICall["GET", "user", token];
    If[FailureQ[resp], Return[resp]];
    login = Lookup[resp["Body"], "login", Missing["NotAvailable"]];
    If[StringQ[login] && StringLength[login] > 0,
      login,
      iFailure["OwnerResolutionFailed", "認証ユーザーの login を取得できませんでした。", <|"Response" -> resp|>]
    ]
  ];

iResolveOwner[_String, owner_String] := owner;

(* 3引数版: RepoDB に owner が登録されていればそちらを優先 *)
iResolveOwner[token_String, Automatic, packageName_String] :=
  Module[{dbOwner},
    dbOwner = iRepoDBOwnerLookup[packageName];
    If[dbOwner =!= Automatic,
      dbOwner,
      iResolveOwner[token, Automatic]
    ]
  ];
iResolveOwner[token_String, owner_String, _String] := owner;

iResolveRepository[packageName_String, Automatic] := packageName;
iResolveRepository[_String, repo_String] := repo;

iResolveBranch[Automatic, base_String] := base;
iResolveBranch[branch_String, _String] := branch;

iPackageDirectory[] :=
  Module[{dir},
    dir = Quiet @ Check[Global`$packageDirectory, $Failed];
    If[StringQ[dir] && StringLength[dir] > 0,
      dir,
      DirectoryName[$InputFileName]
    ]
  ];

iLocalRepoPath[packageName_String, Automatic] :=
  FileNameJoin[{iPackageDirectory[], "GithubRepositories", packageName}];
iLocalRepoPath[_String, path_String] := path;

iPackageFilePath[packageName_String, Automatic] :=
  FileNameJoin[{iPackageDirectory[], packageName <> ".wl"}];
iPackageFilePath[_String, path_String] := path;

iEnsureDirectory[path_String] := (
  If[!DirectoryQ[path],
    CreateDirectory[path, CreateIntermediateDirectories -> True]
  ];
  path
);

iEncodePathPreservingSlash[s_String] := StringReplace[URLEncode[s], "%2F" -> "/"];

iNormalizeGitPath[s_String] := StringJoin[Riffle[FileNameSplit[s], "/"]];

iRepositoryURL[owner_String, repo_String] := "https://github.com/" <> owner <> "/" <> repo;

iGetRepoInfo[token_String, owner_String, repo_String] :=
  iAPICall[
    "GET",
    "repos/" <> owner <> "/" <> repo,
    token
  ];

iWaitForRepoInfo[token_String, owner_String, repo_String, attempts_: 10, delay_: 0.6] :=
  Module[{resp = $Failed, k},
    For[k = 1, k <= attempts, k++,
      resp = iGetRepoInfo[token, owner, repo];
      If[!FailureQ[resp], Return[resp]];
      If[iStatusCode[resp] =!= 404, Return[resp]];
      Pause[delay];
    ];
    resp
  ];

iGetRef[token_String, owner_String, repo_String, branch_String] :=
  iAPICall[
    "GET",
    "repos/" <> owner <> "/" <> repo <> "/git/ref/heads/" <> iEncodePathPreservingSlash[branch],
    token
  ];

iWaitForRef[token_String, owner_String, repo_String, branch_String, attempts_: 10, delay_: 0.6] :=
  Module[{resp = $Failed, k},
    For[k = 1, k <= attempts, k++,
      resp = iGetRef[token, owner, repo, branch];
      If[!FailureQ[resp], Return[resp]];
      If[iStatusCode[resp] =!= 404, Return[resp]];
      Pause[delay];
    ];
    resp
  ];

iCreateRef[token_String, owner_String, repo_String, branch_String, sha_String] :=
  iAPICall[
    "POST",
    "repos/" <> owner <> "/" <> repo <> "/git/refs",
    token,
    <|"ref" -> "refs/heads/" <> branch, "sha" -> sha|>
  ];

iUpdateRef[token_String, owner_String, repo_String, branch_String, sha_String, force_: False] :=
  iAPICall[
    "PATCH",
    "repos/" <> owner <> "/" <> repo <> "/git/refs/heads/" <> iEncodePathPreservingSlash[branch],
    token,
    <|"sha" -> sha, "force" -> TrueQ[force]|>
  ];

iGetCommitObject[token_String, owner_String, repo_String, commitSHA_String] :=
  iAPICall[
    "GET",
    "repos/" <> owner <> "/" <> repo <> "/git/commits/" <> commitSHA,
    token
  ];

iCreateBlob[token_String, owner_String, repo_String, ba_ByteArray] :=
  iAPICall[
    "POST",
    "repos/" <> owner <> "/" <> repo <> "/git/blobs",
    token,
    <|"content" -> BaseEncode[ba], "encoding" -> "base64"|>
  ];

iCreateTree[token_String, owner_String, repo_String, baseTreeSHA_String, treeEntries_List] :=
  iAPICall[
    "POST",
    "repos/" <> owner <> "/" <> repo <> "/git/trees",
    token,
    <|"base_tree" -> baseTreeSHA, "tree" -> treeEntries|>
  ];

iCreateCommit[token_String, owner_String, repo_String, message_String, treeSHA_String, parentSHA_String, author_, committer_] :=
  Module[{body},
    body = iCompactAssociation @ <|
      "message" -> message,
      "tree" -> treeSHA,
      "parents" -> {parentSHA},
      "author" -> author,
      "committer" -> committer
    |>;
    iAPICall[
      "POST",
      "repos/" <> owner <> "/" <> repo <> "/git/commits",
      token,
      body
    ]
  ];

iGetTreeRecursive[token_String, owner_String, repo_String, treeSHA_String] :=
  iAPICall[
    "GET",
    "repos/" <> owner <> "/" <> repo <> "/git/trees/" <> treeSHA,
    token,
    None,
    <|"recursive" -> 1|>
  ];

iReadLocalByteArray[file_String] :=
  Module[{data},
    data = Quiet @ Check[Import[file, "Byte"], $Failed];
    If[ListQ[data],
      ByteArray[data],
      iFailure["LocalFileReadFailed", "ローカルファイルの読込に失敗しました。", <|"File" -> file|>]
    ]
  ];

iWriteLocalByteArray[file_String, ba_ByteArray] :=
  Module[{stream, dir},
    dir = DirectoryName[file];
    If[StringQ[dir] && StringLength[dir] > 0, iEnsureDirectory[dir]];
    stream = OpenWrite[file, BinaryFormat -> True];
    If[!MatchQ[stream, _OutputStream],
      Return[iFailure["LocalFileWriteFailed", "ローカルファイルを書き込めません。", <|"File" -> file|>]]
    ];
    BinaryWrite[stream, Normal[ba], "Byte"];
    Close[stream];
    file
  ];

iRelativeGitPath[root_String, file_String] :=
  iNormalizeGitPath @ FileNameJoin[FileNameDrop[file, FileNameDepth[root]]];

iListLocalFiles[root_String] :=
  DeleteDuplicates @ Select[
    Join[FileNames["*", root, Infinity], FileNames[".*", root, Infinity]],
    FileExistsQ[#] && !DirectoryQ[#] &
  ];

iNormalizePerson[Automatic] := None;
iNormalizePerson[None] := None;
iNormalizePerson[assoc_Association] :=
  Module[{name, email},
    name = Lookup[assoc, "name", None];
    email = Lookup[assoc, "email", None];
    If[StringQ[name] && StringQ[email] && StringLength[name] > 0 && StringLength[email] > 0,
      <|"name" -> name, "email" -> email|>,
      None
    ]
  ];

iDecodeGitHubContent[content_String, encoding_String] :=
  Module[{clean},
    clean = StringReplace[content, WhitespaceCharacter .. -> ""];
    Switch[ToLowerCase[encoding],
      "base64", BaseDecode[clean],
      "utf-8", StringToByteArray[content, "UTF-8"],
      _, BaseDecode[clean]
    ]
  ];

iResolveBaseBranch[token_String, owner_String, repo_String, Automatic] :=
  Module[{repoInfo, branch},
    repoInfo = iWaitForRepoInfo[token, owner, repo];
    If[FailureQ[repoInfo], Return[repoInfo]];
    branch = Lookup[repoInfo["Body"], "default_branch", Missing["NotAvailable"]];
    If[StringQ[branch] && StringLength[branch] > 0,
      branch,
      iFailure[
        "MissingDefaultBranch",
        "リポジトリの default_branch を取得できませんでした。",
        <|"Owner" -> owner, "Repository" -> repo, "RepositoryResponse" -> repoInfo["Body"]|>
      ]
    ]
  ];

iResolveBaseBranch[_String, _String, _String, base_String] := base;

iSlugifyBranchName[s_String] :=
  Module[{slug},
    slug = ToLowerCase[s];
    slug = StringReplace[slug, {
      Except[LetterCharacter | DigitCharacter] .. -> "-",
      StartOfString ~~ "-" .. -> "",
      "-" .. ~~ EndOfString -> "",
      "--" .. -> "-"
    }];
    If[StringLength[slug] == 0, "update", slug]
  ];

iAutoPRBranchName[packageName_String, title_String] :=
  "pr/" <> packageName <> "/" <>
  DateString[{"Year", "Month", "Day", "-", "Hour24", "Minute", "Second"}] <>
  "-" <> iSlugifyBranchName[title];

iRepoAccessFailure[owner_String, repo_String, status_: None] :=
  iFailure[
    "RepositoryAccessFailed",
    "作成または指定したリポジトリへ API からアクセスできません。private repository で 404 が返る場合は、Fine-grained PAT の対象リポジトリ設定が新しい repo を含んでいない可能性があります。GitHub トークンを \"All repositories\" にするか、classic token を使ってください。",
    iCompactAssociation @ <|
      "Owner" -> owner,
      "Repository" -> repo,
      "RepositoryURL" -> iRepositoryURL[owner, repo],
      "StatusCode" -> status
    |>
  ];

iBranchReadFailure[owner_String, repo_String, branch_String] :=
  iFailure[
    "BranchNotReady",
    "ブランチ参照の取得に失敗しました。リポジトリ作成直後で default branch の初期 ref がまだ反映されていないか、トークンがその private repository にアクセスできません。",
    <|
      "Owner" -> owner,
      "Repository" -> repo,
      "Branch" -> branch,
      "RepositoryURL" -> iRepositoryURL[owner, repo]
    |>
  ];

iBranchIfMissing[token_String, owner_String, repo_String, branch_String, baseBranch_String] :=
  Module[{existing, baseRef, baseSHA, created},
    existing = iGetRef[token, owner, repo, branch];
    If[!FailureQ[existing], Return[existing]];
    baseRef = iWaitForRef[token, owner, repo, baseBranch];
    If[FailureQ[baseRef], Return[baseRef]];
    baseSHA = Lookup[Lookup[baseRef["Body"], "object", <||>], "sha", Missing["NotAvailable"]];
    If[!StringQ[baseSHA],
      Return[iFailure["BaseBranchResolutionFailed", "BaseBranch の SHA を取得できませんでした。", <|"Branch" -> baseBranch|>]]
    ];
    created = iCreateRef[token, owner, repo, branch, baseSHA];
    If[FailureQ[created], Return[created]];
    iGetRef[token, owner, repo, branch]
  ];

(* ============================================================
   Manifest / グループリフレッシュ 内部ヘルパー
   ============================================================ *)

(* _info ディレクトリ名: packageName_info *)
iInfoDirName[packageName_String] := packageName <> "_info";

(* _info/originals ディレクトリパス *)
iOriginalsDir[packageName_String] :=
  FileNameJoin[{iPackageDirectory[], iInfoDirName[packageName], "originals"}];

(* RepoDB に owner が登録されているリモートパッケージか判定 *)
iIsRemotePackage[packageName_String] :=
  Module[{db, record},
    db = iLoadRepoDB[];
    record = Lookup[db, packageName, <||>];
    StringQ[Lookup[record, "owner", Automatic]]
  ];

(* doc_options.json に Originals マッピングを保存
   mapping: {<|"repoPath" -> "README.md", "localPath" -> "pkg_info/originals/README.md"|>, ...} *)
iSaveOriginals[packageName_String, mapping_List] :=
  Module[{refDir, optPath, data},
    refDir = FileNameJoin[{iPackageDirectory[], iInfoDirName[packageName], "references"}];
    iEnsureDirectory[refDir];
    optPath = FileNameJoin[{refDir, "doc_options.json"}];
    data = If[FileExistsQ[optPath],
      Quiet @ Check[Import[optPath, "RawJSON"], <||>], <||>];
    If[!AssociationQ[data], data = <||>];
    data["Originals"] = mapping;
    Quiet @ Export[optPath, data, "RawJSON"];
  ];

(* doc_options.json から Originals マッピングを読み込み *)
iLoadOriginals[packageName_String] :=
  Module[{refDir, optPath, data},
    refDir = FileNameJoin[{iPackageDirectory[], iInfoDirName[packageName], "references"}];
    optPath = FileNameJoin[{refDir, "doc_options.json"}];
    If[!FileExistsQ[optPath], Return[{}]];
    data = Quiet @ Check[Import[optPath, "RawJSON"], <||>];
    If[!AssociationQ[data], Return[{}]];
    Replace[Lookup[data, "Originals", {}], Except[_List] -> {}]
  ];

(* originals/ のファイルを GithubRepositories のリポジトリフォルダへ書き戻す *)
iRestoreOriginalsToRepo[packageName_String, localRepoDir_String] :=
  Module[{mapping, pkgDir, src, dst, restored = {}},
    mapping = iLoadOriginals[packageName];
    If[Length[mapping] === 0, Return[{}]];
    pkgDir = iPackageDirectory[];
    Do[
      If[AssociationQ[entry],
        src = FileNameJoin[{pkgDir, Lookup[entry, "localPath", ""]}];
        dst = FileNameJoin[{localRepoDir, Lookup[entry, "repoPath", ""]}];
        If[FileExistsQ[src] && StringLength[Lookup[entry, "repoPath", ""]] > 0,
          iEnsureDirectory[DirectoryName[dst]];
          Quiet @ CopyFile[src, dst, OverwriteTarget -> True];
          AppendTo[restored, Lookup[entry, "repoPath", ""]]]],
      {entry, mapping}];
    restored
  ];

(* upload_manifest.json のパスを返す *)
iManifestPath[packageName_String] :=
  FileNameJoin[{iPackageDirectory[], iInfoDirName[packageName], "upload_manifest.json"}];

(* マニフェストが無い場合のデフォルト構成
   パッケージ (.wl) の場合: files に packageName.wl, directories に packageName_info
   パクレット (フォルダ) の場合: directories に packageName と packageName_info *)
iDefaultManifest[packageName_String] :=
  Module[{pkgDir, wlPath, packletDir},
    pkgDir = iPackageDirectory[];
    wlPath = FileNameJoin[{pkgDir, packageName <> ".wl"}];
    packletDir = FileNameJoin[{pkgDir, packageName}];
    Which[
      FileExistsQ[wlPath],
        <|
          "packageName" -> packageName,
          "files" -> {packageName <> ".wl"},
          "directories" -> {iInfoDirName[packageName]},
          "excludePatterns" -> {iInfoDirName[packageName] <> "/history/",
                                iInfoDirName[packageName] <> "/references/"}
        |>,
      DirectoryQ[packletDir],
        <|
          "packageName" -> packageName,
          "files" -> {},
          "directories" -> {packageName, iInfoDirName[packageName]},
          "excludePatterns" -> {iInfoDirName[packageName] <> "/history/",
                                iInfoDirName[packageName] <> "/references/"}
        |>,
      True,
        <|
          "packageName" -> packageName,
          "files" -> {packageName <> ".wl"},
          "directories" -> {},
          "excludePatterns" -> {}
        |>
    ]
  ];

(* upload_manifest.json をディスクに書き出す *)
iWriteManifest[packageName_String, manifest_Association] :=
  Module[{path, dir, jsonStr, codes, bytes},
    path = iManifestPath[packageName];
    dir = DirectoryName[path];
    iEnsureDirectory[dir];
    jsonStr = ExportString[manifest, "RawJSON", "Compact" -> False];
    codes = ToCharacterCode[jsonStr];
    If[Max[codes] <= 255 && AnyTrue[codes, # > 127 &],
      jsonStr = ByteArrayToString[ByteArray[codes], "UTF-8"]];
    bytes = StringToByteArray[jsonStr, "UTF-8"];
    With[{strm = OpenWrite[path, BinaryFormat -> True]},
      BinaryWrite[strm, Normal[bytes]];
      Close[strm]];
    path
  ];

(* 現在のパッケージ種別を検出: "Package" (.wl) / "Paclet" (フォルダ) / "Unknown" *)
iDetectPackageType[packageName_String] :=
  Module[{pkgDir, wlPath, packletDir},
    pkgDir = iPackageDirectory[];
    wlPath = FileNameJoin[{pkgDir, packageName <> ".wl"}];
    packletDir = FileNameJoin[{pkgDir, packageName}];
    Which[
      (* パクレットフォルダが存在し .wl が存在しない → パクレット *)
      DirectoryQ[packletDir] && !FileExistsQ[wlPath], "Paclet",
      (* .wl が存在する → パッケージ (フォルダとの共存時も .wl 優先) *)
      FileExistsQ[wlPath], "Package",
      (* パクレットフォルダのみ *)
      DirectoryQ[packletDir], "Paclet",
      True, "Unknown"
    ]
  ];

(* upload_manifest.json を読む。存在しなければデフォルトを返す (ディスクへは書かない) *)
iReadManifest[packageName_String] :=
  Module[{path, raw},
    path = iManifestPath[packageName];
    If[!FileExistsQ[path],
      Return[iDefaultManifest[packageName]]
    ];
    raw = Quiet @ Check[Import[path, "RawJSON"], $Failed];
    If[!AssociationQ[raw],
      Return[iDefaultManifest[packageName]]
    ];
    <|
      "packageName" -> Lookup[raw, "packageName", packageName],
      "files" -> Lookup[raw, "files", {}],
      "directories" -> Lookup[raw, "directories", {}],
      "excludePatterns" -> Lookup[raw, "excludePatterns", {}]
    |>
  ];

(* manifest の存在確認 + パッケージ種別変更の自動検知・更新
   - ファイルが無ければ新規作成してディスクに保存
   - ファイルがあっても、パッケージ種別が変わっていたら更新して保存
   戻り値: 最新の manifest Association *)
iEnsureManifest[packageName_String] :=
  Module[{path, manifest, currentType, manifestType, newManifest},
    path = iManifestPath[packageName];
    currentType = iDetectPackageType[packageName];

    If[!FileExistsQ[path],
      (* 新規作成 *)
      manifest = iDefaultManifest[packageName];
      iWriteManifest[packageName, manifest];
      Return[manifest]
    ];

    (* 既存 manifest を読む *)
    manifest = iReadManifest[packageName];

    (* 現在の manifest がどちらの種別か判定:
       files に packageName.wl が含まれている → Package 型
       directories に packageName が含まれている → Paclet 型 *)
    manifestType = Which[
      MemberQ[Lookup[manifest, "files", {}], packageName <> ".wl"], "Package",
      MemberQ[Lookup[manifest, "directories", {}], packageName], "Paclet",
      True, "Unknown"
    ];

    (* 種別が変わっていたら manifest を再生成して保存 *)
    If[currentType =!= manifestType && currentType =!= "Unknown",
      newManifest = iDefaultManifest[packageName];
      (* 既存の excludePatterns でユーザーがカスタマイズしたものがあれば引き継ぐ *)
      newManifest = ReplacePart[newManifest,
        "excludePatterns" -> DeleteDuplicates @ Join[
          Lookup[newManifest, "excludePatterns", {}],
          Lookup[manifest, "excludePatterns", {}]
        ]
      ];
      iWriteManifest[packageName, newManifest];
      Return[newManifest]
    ];

    manifest
  ];

(* ExtraDirectories オプションで指定されたディレクトリを manifest に永続追加する。
   既に含まれていればスキップ。追加後はディスクに保存。 *)
iAddExtraDirectories[packageName_String, extraDirs_] :=
  Module[{dirs, manifest, currentDirs, newDirs},
    dirs = Replace[extraDirs, {
      s_String :> {s},
      l_List :> l,
      _ :> {}
    }];
    If[Length[dirs] == 0, Return[]];
    manifest = iEnsureManifest[packageName];
    currentDirs = Lookup[manifest, "directories", {}];
    newDirs = DeleteDuplicates[Join[currentDirs, dirs]];
    If[newDirs =!= currentDirs,
      manifest["directories"] = newDirs;
      iWriteManifest[packageName, manifest];
      Print["upload_manifest.json に追加: " <> StringRiffle[Complement[newDirs, currentDirs], ", "]]
    ]
  ];

(* excludePattern にマッチするか判定 (パスの前方一致) *)
iMatchExcludePattern[relPath_String, patterns_List] :=
  AnyTrue[patterns,
    Function[pat,
      StringMatchQ[relPath, pat <> "*"] || StringStartsQ[relPath, pat]
    ]
  ];

(* マニフェストの有無に関わらず常に保護すべきデフォルト除外パターン *)
iDefaultExcludePatterns[packageName_String] := {
  iInfoDirName[packageName] <> "/history/",
  iInfoDirName[packageName] <> "/references/"
};

(* マニフェストの excludePatterns にデフォルト保護パターンを統合 *)
iMergedExcludePatterns[packageName_String] :=
  Module[{manifest, patterns},
    manifest = Quiet @ Check[iEnsureManifest[packageName], <||>];
    patterns = Lookup[manifest, "excludePatterns", {}];
    DeleteDuplicates[Join[patterns, iDefaultExcludePatterns[packageName]]]
  ];

(* ディレクトリを $packageDirectory にコピーする際に excludePatterns に該当する
   既存ファイル・フォルダを保護する。DeleteDirectory + CopyDirectory の代替。
   srcDir: コピー元ディレクトリ (GithubRepositories 内)
   dstDir: コピー先ディレクトリ ($packageDirectory 内)
   dirName: ディレクトリの相対名 (例: "fib_info")
   excludePatterns: 保護するパターンのリスト *)
iCopyDirectoryPreservingExcluded[srcDir_String, dstDir_String,
    dirName_String, excludePatterns_List] :=
  Module[{srcFiles, relPath, dstPath, dstExistingFiles, copied = 0, deleted = 0},
    (* コピー先の既存ファイルのうち、excludePatterns に該当しないものだけ削除 *)
    If[DirectoryQ[dstDir],
      dstExistingFiles = iListLocalFiles[dstDir];
      Do[
        relPath = iNormalizeGitPath[
          dirName <> "/" <> FileNameJoin[FileNameDrop[f, FileNameDepth[dstDir]]]];
        If[!iMatchExcludePattern[relPath, excludePatterns],
          Quiet @ DeleteFile[f]; deleted++],
        {f, dstExistingFiles}]];
    (* コピー元のファイルをコピー *)
    If[DirectoryQ[srcDir],
      srcFiles = iListLocalFiles[srcDir];
      Do[
        relPath = iNormalizeGitPath[
          dirName <> "/" <> FileNameJoin[FileNameDrop[f, FileNameDepth[srcDir]]]];
        If[!iMatchExcludePattern[relPath, excludePatterns],
          dstPath = FileNameJoin[Flatten[{DirectoryName[dstDir],
            FileNameSplit[relPath]}]];
          iEnsureDirectory[DirectoryName[dstPath]];
          Quiet @ CopyFile[f, dstPath, OverwriteTarget -> True];
          copied++],
        {f, srcFiles}]];
    <|"Copied" -> copied, "Deleted" -> deleted|>
  ];

(* ディレクトリを再帰コピー (excludePatterns でフィルタ) *)
iCopyDirectoryFiltered[srcDir_String, dstBaseDir_String, relBase_String, excludePatterns_List] :=
  Module[{allFiles, relPath, dstPath, copied = {}},
    If[!DirectoryQ[srcDir], Return[{}]];
    allFiles = Select[
      Join[FileNames["*", srcDir, Infinity], FileNames[".*", srcDir, Infinity]],
      FileExistsQ[#] && !DirectoryQ[#] &
    ];
    Do[
      relPath = iNormalizeGitPath[
        relBase <> "/" <> FileNameJoin[FileNameDrop[file, FileNameDepth[srcDir]]]
      ];
      If[!iMatchExcludePattern[relPath, excludePatterns],
        dstPath = FileNameJoin[Flatten[{dstBaseDir, FileNameSplit[relPath]}]];
        iEnsureDirectory[DirectoryName[dstPath]];
        Quiet @ CopyFile[file, dstPath, OverwriteTarget -> True];
        AppendTo[copied, relPath]
      ],
      {file, allFiles}
    ];
    copied
  ];

(* _info/docs/README.md をトップレベル README.md として同期する *)
iSyncReadme[packageName_String, localDir_String] :=
  Module[{readmeSrc, readmeDst},
    readmeSrc = FileNameJoin[{iPackageDirectory[], iInfoDirName[packageName], "docs", "README.md"}];
    readmeDst = FileNameJoin[{localDir, "README.md"}];
    If[FileExistsQ[readmeSrc],
      Quiet @ CopyFile[readmeSrc, readmeDst, OverwriteTarget -> True];
      readmeDst,
      None
    ]
  ];

(* マニフェストに基づくグループリフレッシュの内部実装 *)
iRefreshPackageGroup[packageName_String, localDir_String] :=
  Module[{manifest, pkgDir, copiedFiles = {}, copiedDirs = {}, excludePatterns,
          src, dst, readmeResult, restoredOriginals},
    manifest = iEnsureManifest[packageName];
    pkgDir = iPackageDirectory[];
    excludePatterns = iMergedExcludePatterns[packageName];
    (* 個別ファイルのコピー *)
    Do[
      src = FileNameJoin[{pkgDir, file}];
      If[FileExistsQ[src],
        dst = FileNameJoin[{localDir, FileNameTake[src]}];
        Quiet @ CopyFile[src, dst, OverwriteTarget -> True];
        AppendTo[copiedFiles, file]
      ],
      {file, Lookup[manifest, "files", {}]}
    ];
    (* ディレクトリの再帰コピー *)
    Do[
      src = FileNameJoin[{pkgDir, dir}];
      If[DirectoryQ[src],
        copiedDirs = Join[copiedDirs,
          iCopyDirectoryFiltered[src, localDir, dir, excludePatterns]
        ]
      ],
      {dir, Lookup[manifest, "directories", {}]}
    ];
    (* originals の書き戻し: _info/originals/ → GithubRepositories/ の元の位置へ *)
    restoredOriginals = iRestoreOriginalsToRepo[packageName, localDir];
    (* README.md の同期 *)
    readmeResult = iSyncReadme[packageName, localDir];
    <|
      "Package" -> packageName,
      "LocalRepoPath" -> localDir,
      "Manifest" -> manifest,
      "CopiedFiles" -> copiedFiles,
      "CopiedDirectoryFiles" -> copiedDirs,
      "RestoredOriginals" -> restoredOriginals,
      "READMESynced" -> readmeResult
    |>
  ];

(* ============================================================
   公開関数: パッケージの GitHub URL を取得
   ============================================================ *)

(* $packageDirectory 内の全パッケージ名を列挙 *)
iListPackageNames[] :=
  Module[{pkgDir, wlFiles, pacletDirs},
    pkgDir = iPackageDirectory[];
    If[!StringQ[pkgDir] || !DirectoryQ[pkgDir], Return[{}]];
    wlFiles = FileBaseName /@ FileNames["*.wl", pkgDir];
    pacletDirs = FileNameTake /@ Select[FileNames["*", pkgDir],
      DirectoryQ[#] && FileExistsQ[FileNameJoin[{#, "PacletInfo.wl"}]] &];
    DeleteDuplicates[Join[wlFiles, pacletDirs]]
  ];

Options[GitHubPackageURL] = {Owner -> Automatic, Repository -> Automatic,
  Fallback -> False
};

GitHubPackageURL[packageName_String, opts:OptionsPattern[]] :=
  Module[{token, owner, repo},
    token = iAccessToken[];
    If[FailureQ[token], Return[$Failed]];
    owner = iResolveOwner[token, OptionValue[Owner], packageName];
    If[FailureQ[owner], Return[$Failed]];
    (* Fallback オプションを  に反映 *)
    If[TrueQ[OptionValue[Fallback]],
      ClaudeCode = True];
    repo = iResolveRepository[packageName, OptionValue[Repository]];
    If[FailureQ[repo], Return[repo]];
    iRepositoryURL[owner, repo]
  ];

GitHubPackageURLs[] :=
  Module[{names},
    names = iListPackageNames[];
    Association[# -> GitHubPackageURL[#] & /@ names]
  ];

(* ============================================================
   公開関数: ローカルリポジトリ管理
   ============================================================ *)

Options[GitHubEnsureLocalRepo] = {LocalRepoPath -> Automatic};

GitHubRepoPath[packageName_String] := iLocalRepoPath[packageName, Automatic];

GitHubEnsureLocalRepo[packageName_String, opts : OptionsPattern[]] :=
  Module[{dir},
    dir = iLocalRepoPath[packageName, OptionValue[LocalRepoPath]];
    iEnsureDirectory[dir]
  ];

Options[GitHubRefreshLocalPackage] = {
  LocalRepoPath -> Automatic,
  PackageFile -> Automatic
};

GitHubRefreshLocalPackage[packageName_String, opts : OptionsPattern[]] :=
  Module[{src, dstDir, dst},
    src = iPackageFilePath[packageName, OptionValue[PackageFile]];
    If[!FileExistsQ[src],
      Return[iFailure[
        "PackageFileNotFound",
        "元パッケージファイルが見つかりません。",
        <|"PackageFile" -> src|>
      ]]
    ];
    dstDir = GitHubEnsureLocalRepo[packageName, LocalRepoPath -> OptionValue[LocalRepoPath]];
    dst = FileNameJoin[{dstDir, FileNameTake[src]}];
    Quiet @ CopyFile[src, dst, OverwriteTarget -> True];
    dst
  ];

(* ============================================================
   GitHubReadManifest / GitHubRefreshLocalPackageGroup
   ============================================================ *)

GitHubReadManifest[packageName_String] := iEnsureManifest[packageName];

Options[GitHubRefreshLocalPackageGroup] = {
  LocalRepoPath -> Automatic
};

GitHubRefreshLocalPackageGroup[packageName_String, opts : OptionsPattern[]] :=
  Module[{localDir},
    localDir = GitHubEnsureLocalRepo[packageName, LocalRepoPath -> OptionValue[LocalRepoPath]];
    iRefreshPackageGroup[packageName, localDir]
  ];

(* ============================================================
   GitHubCreateRepository (グループ対応版)
   ============================================================ *)

Options[GitHubCreateRepository] = {
  Repository -> Automatic,
  Public -> False,
  Description -> "",
  Homepage -> None,
  AutoInit -> True,
  GitignoreTemplate -> None,
  LicenseTemplate -> None,
  LocalRepoPath -> Automatic,
  IncludePackageFile -> True,
  PackageFile -> Automatic,
  ExtraDirectories -> {},
  Fallback -> False
};

GitHubCreateRepository[packageName_String, opts : OptionsPattern[]] :=
  Module[{token, repo, resp, ownerLogin, localDir, refreshResult, repoInfo,
          defaultBranch, refResp, commitResult},
    (* Fallback オプションを $currentUseFallback に反映 *)
    If[TrueQ[OptionValue[Fallback]],
      ClaudeCode`Private`$currentUseFallback = True];
    token = iAccessToken[];
    If[FailureQ[token], Return[token]];
    (* Fallback オプションを  に反映 *)
    If[TrueQ[OptionValue[Fallback]],
      ClaudeCode = True];
    repo = iResolveRepository[packageName, OptionValue[Repository]];
    If[FailureQ[repo], Return[repo]];
    resp = iAPICall[
      "POST",
      "user/repos",
      token,
      iCompactAssociation @ <|
        "name" -> repo,
        "description" -> OptionValue[Description],
        "homepage" -> OptionValue[Homepage],
        "private" -> Not[TrueQ[OptionValue[Public]]],
        "auto_init" -> TrueQ[OptionValue[AutoInit]],
        "gitignore_template" -> OptionValue[GitignoreTemplate],
        "license_template" -> OptionValue[LicenseTemplate]
      |>
    ];
    If[FailureQ[resp], Return[resp]];
    ownerLogin = Lookup[Lookup[resp["Body"], "owner", <||>], "login", Missing["NotAvailable"]];
    If[!StringQ[ownerLogin] || StringLength[ownerLogin] == 0,
      Return[iFailure["OwnerResolutionFailed", "作成したリポジトリの owner を取得できませんでした。", <|"Response" -> resp["Body"]|>]]
    ];
    repoInfo = iWaitForRepoInfo[token, ownerLogin, repo];
    If[FailureQ[repoInfo],
      Return[iRepoAccessFailure[ownerLogin, repo, iStatusCode[repoInfo]]]
    ];
    defaultBranch = Lookup[repoInfo["Body"], "default_branch", Missing["NotAvailable"]];
    If[TrueQ[OptionValue[AutoInit]] && StringQ[defaultBranch] && StringLength[defaultBranch] > 0,
      refResp = iWaitForRef[token, ownerLogin, repo, defaultBranch];
      If[FailureQ[refResp],
        Return[iBranchReadFailure[ownerLogin, repo, defaultBranch]]
      ]
    ];
    localDir = GitHubEnsureLocalRepo[packageName, LocalRepoPath -> OptionValue[LocalRepoPath]];
    (* ExtraDirectories が指定されていれば manifest に永続追加 *)
    iAddExtraDirectories[packageName, OptionValue[ExtraDirectories]];
    refreshResult = None;
    If[TrueQ[OptionValue[IncludePackageFile]],
      refreshResult = iRefreshPackageGroup[packageName, localDir];
      If[FailureQ[refreshResult], Return[refreshResult]];
      (* manifest に基づくファイルをコミット *)
      commitResult = GitHubCommit[
        packageName,
        "Initial upload via GitHubCreateRepository",
        Owner -> ownerLogin,
        Repository -> repo,
        BaseBranch -> defaultBranch,
        LocalRepoPath -> OptionValue[LocalRepoPath],
        IncludePackageFile -> False,
        DeleteMissing -> False
      ];
      If[FailureQ[commitResult], Return[commitResult]];
    ];
    <|
      "Package" -> packageName,
      "Owner" -> ownerLogin,
      "Repository" -> repo,
      "DefaultBranch" -> defaultBranch,
      "LocalRepoPath" -> localDir,
      "RefreshResult" -> refreshResult,
      "Response" -> repoInfo["Body"]
    |>
  ];

Options[GitHubReadFile] = {
  Owner -> Automatic,
  Repository -> Automatic,
  Branch -> Automatic,
  BaseBranch -> Automatic,
  ReturnType -> "Text",
  Fallback -> False
};

GitHubReadFile[packageName_String, path_String, opts : OptionsPattern[]] :=
  Module[{token, owner, repo, baseBranch, branch, resp, body, content, encoding, ba, returnType},
    token = iAccessToken[];
    If[FailureQ[token], Return[token]];
    owner = iResolveOwner[token, OptionValue[Owner], packageName];
    If[FailureQ[owner], Return[owner]];
    (* Fallback オプションを  に反映 *)
    If[TrueQ[OptionValue[Fallback]],
      ClaudeCode = True];
    repo = iResolveRepository[packageName, OptionValue[Repository]];
    If[FailureQ[repo], Return[repo]];
    baseBranch = iResolveBaseBranch[token, owner, repo, OptionValue[BaseBranch]];
    If[FailureQ[baseBranch], Return[baseBranch]];
    branch = iResolveBranch[OptionValue[Branch], baseBranch];
    resp = iAPICall[
      "GET",
      "repos/" <> owner <> "/" <> repo <> "/contents/" <> iEncodePathPreservingSlash[path],
      token,
      None,
      <|"ref" -> branch|>
    ];
    If[FailureQ[resp], Return[resp]];
    body = resp["Body"];
    If[Lookup[body, "type", "file"] =!= "file",
      Return[iFailure["NotAFile", "指定パスはファイルではありません。", <|"Path" -> path, "Body" -> body|>]]
    ];
    content = Lookup[body, "content", Missing["NotAvailable"]];
    encoding = Lookup[body, "encoding", "base64"];
    If[!StringQ[content],
      Return[iFailure["MissingContent", "GitHub 応答に content フィールドがありません。", <|"Body" -> body|>]]
    ];
    ba = iDecodeGitHubContent[content, encoding];
    returnType = OptionValue[ReturnType];
    Switch[returnType,
      "ByteArray", ba,
      "Bytes", Normal[ba],
      _, Quiet @ Check[ByteArrayToString[ba], ba]
    ]
  ];

Options[GitHubPull] = {
  Owner -> Automatic,
  Repository -> Automatic,
  Branch -> Automatic,
  BaseBranch -> Automatic,
  LocalRepoPath -> Automatic,
  Clean -> False,
  Fallback -> False
};

GitHubPull[packageName_String, opts : OptionsPattern[]] :=
  Module[{token, owner, repo, baseBranch, branch, localDir, ref, headSHA, commitObj, treeSHA,
          treeResp, entries, blobResp, blobBody, ba, localFile, pulled = 0},
    token = iAccessToken[];
    If[FailureQ[token], Return[token]];
    owner = iResolveOwner[token, OptionValue[Owner], packageName];
    If[FailureQ[owner], Return[owner]];
    (* Fallback オプションを  に反映 *)
    If[TrueQ[OptionValue[Fallback]],
      ClaudeCode = True];
    repo = iResolveRepository[packageName, OptionValue[Repository]];
    If[FailureQ[repo], Return[repo]];
    baseBranch = iResolveBaseBranch[token, owner, repo, OptionValue[BaseBranch]];
    If[FailureQ[baseBranch], Return[baseBranch]];
    branch = iResolveBranch[OptionValue[Branch], baseBranch];
    localDir = GitHubEnsureLocalRepo[packageName, LocalRepoPath -> OptionValue[LocalRepoPath]];
    If[TrueQ[OptionValue[Clean]],
      Scan[Quiet @ DeleteFile[#] &, iListLocalFiles[localDir]]
    ];
    ref = iWaitForRef[token, owner, repo, branch];
    If[FailureQ[ref], Return[ref]];
    headSHA = Lookup[Lookup[ref["Body"], "object", <||>], "sha", Missing["NotAvailable"]];
    If[!StringQ[headSHA],
      Return[iFailure["MissingHeadSHA", "ブランチ先頭 commit の SHA を取得できませんでした。", <|"Branch" -> branch|>]]
    ];
    commitObj = iGetCommitObject[token, owner, repo, headSHA];
    If[FailureQ[commitObj], Return[commitObj]];
    treeSHA = Lookup[Lookup[commitObj["Body"], "tree", <||>], "sha", Missing["NotAvailable"]];
    If[!StringQ[treeSHA],
      Return[iFailure["MissingTreeSHA", "先頭 commit の tree SHA を取得できませんでした。", <|"Branch" -> branch|>]]
    ];
    treeResp = iGetTreeRecursive[token, owner, repo, treeSHA];
    If[FailureQ[treeResp], Return[treeResp]];
    entries = Select[
      Lookup[treeResp["Body"], "tree", {}],
      AssociationQ[#] && Lookup[#, "type", None] === "blob" &
    ];
    Do[
      blobResp = iAPICall[
        "GET",
        "repos/" <> owner <> "/" <> repo <> "/git/blobs/" <> Lookup[entry, "sha", ""],
        token
      ];
      If[FailureQ[blobResp], Return[blobResp]];
      blobBody = blobResp["Body"];
      ba = iDecodeGitHubContent[
        Lookup[blobBody, "content", ""],
        Lookup[blobBody, "encoding", "base64"]
      ];
      localFile = FileNameJoin[Prepend[StringSplit[Lookup[entry, "path", ""], "/"], localDir]];
      If[FailureQ[iWriteLocalByteArray[localFile, ba]],
        Return[iFailure["LocalPullWriteFailed", "pull したファイルを書き込めませんでした。", <|"File" -> localFile|>]]
      ];
      pulled++,
      {entry, entries}
    ];
    <|
      "Package" -> packageName,
      "Owner" -> owner,
      "Repository" -> repo,
      "Branch" -> branch,
      "LocalRepoPath" -> localDir,
      "FilesPulled" -> pulled
    |>
  ];

Options[GitHubCommit] = {
  Owner -> Automatic,
  Repository -> Automatic,
  Branch -> Automatic,
  BaseBranch -> Automatic,
  CreateBranch -> Automatic,
  LocalRepoPath -> Automatic,
  IncludePackageFile -> True,
  PackageFile -> Automatic,
  DeleteMissing -> False,
  Force -> False,
  Author -> Automatic,
  Committer -> Automatic,
  Fallback -> False
};

GitHubCommit[packageName_String, message_String, opts : OptionsPattern[]] :=
  Module[{token, owner, repo, branch, baseBranch, createBranchQ, localDir, repoInfo, ref,
          headSHA, commitObj, baseTreeSHA, localFiles, entries = {},  localPaths,
          relPath, ba, blobResp, blobSHA, remoteTree, remotePaths, deletePaths,
          treeResp, newTreeSHA, commitResp, newCommitSHA, updateResp, author, committer,
          includePackageResult},
    (* Fallback オプションを $currentUseFallback に反映 *)
    If[TrueQ[OptionValue[Fallback]],
      ClaudeCode`Private`$currentUseFallback = True];
    token = iAccessToken[];
    If[FailureQ[token], Return[token]];
    owner = iResolveOwner[token, OptionValue[Owner], packageName];
    If[FailureQ[owner], Return[owner]];
    (* Fallback オプションを  に反映 *)
    If[TrueQ[OptionValue[Fallback]],
      ClaudeCode = True];
    repo = iResolveRepository[packageName, OptionValue[Repository]];
    If[FailureQ[repo], Return[repo]];
    repoInfo = iWaitForRepoInfo[token, owner, repo];
    If[FailureQ[repoInfo], Return[iRepoAccessFailure[owner, repo, iStatusCode[repoInfo]]]];
    baseBranch = iResolveBaseBranch[token, owner, repo, OptionValue[BaseBranch]];
    If[FailureQ[baseBranch], Return[baseBranch]];
    branch = iResolveBranch[OptionValue[Branch], baseBranch];
    createBranchQ = Replace[OptionValue[CreateBranch], Automatic :> (branch =!= baseBranch)];
    localDir = GitHubEnsureLocalRepo[packageName, LocalRepoPath -> OptionValue[LocalRepoPath]];
    If[TrueQ[OptionValue[IncludePackageFile]],
      includePackageResult = iRefreshPackageGroup[packageName, localDir];
      If[FailureQ[includePackageResult], Return[includePackageResult]];
    ];
    ref = If[TrueQ[createBranchQ],
      iBranchIfMissing[token, owner, repo, branch, baseBranch],
      iWaitForRef[token, owner, repo, branch]
    ];
    If[FailureQ[ref],
      If[iStatusCode[ref] === 404,
        Return[iBranchReadFailure[owner, repo, branch]],
        Return[ref]
      ]
    ];
    headSHA = Lookup[Lookup[ref["Body"], "object", <||>], "sha", Missing["NotAvailable"]];
    If[!StringQ[headSHA],
      Return[iFailure["MissingHeadSHA", "commit 基準となる head SHA を取得できませんでした。", <|"Branch" -> branch|>]]
    ];
    commitObj = iGetCommitObject[token, owner, repo, headSHA];
    If[FailureQ[commitObj], Return[commitObj]];
    baseTreeSHA = Lookup[Lookup[commitObj["Body"], "tree", <||>], "sha", Missing["NotAvailable"]];
    If[!StringQ[baseTreeSHA],
      Return[iFailure["MissingBaseTreeSHA", "ベース tree SHA を取得できませんでした。", <|"Branch" -> branch|>]]
    ];
    localFiles = iListLocalFiles[localDir];
    If[Length[localFiles] == 0,
      Return[iFailure["NoLocalFiles", "ローカル GitHub 作業フォルダにコミット対象ファイルがありません。", <|"LocalRepoPath" -> localDir|>]]
    ];
    Do[
      relPath = iRelativeGitPath[localDir, file];
      ba = iReadLocalByteArray[file];
      If[FailureQ[ba], Return[ba]];
      blobResp = iCreateBlob[token, owner, repo, ba];
      If[FailureQ[blobResp], Return[blobResp]];
      blobSHA = Lookup[blobResp["Body"], "sha", Missing["NotAvailable"]];
      If[!StringQ[blobSHA],
        Return[iFailure["MissingBlobSHA", "blob SHA を取得できませんでした。", <|"File" -> file|>]]
      ];
      AppendTo[entries, <|"path" -> relPath, "mode" -> "100644", "type" -> "blob", "sha" -> blobSHA|>],
      {file, localFiles}
    ];
    localPaths = Lookup[entries, "path"];
    If[TrueQ[OptionValue[DeleteMissing]],
      remoteTree = iGetTreeRecursive[token, owner, repo, baseTreeSHA];
      If[FailureQ[remoteTree], Return[remoteTree]];
      remotePaths = Cases[
        Lookup[remoteTree["Body"], "tree", {}],
        a_Association /; Lookup[a, "type", None] === "blob" :> Lookup[a, "path", None]
      ];
      deletePaths = Complement[Select[remotePaths, StringQ], localPaths];
      entries = Join[
        entries,
        (<|"path" -> #, "mode" -> "100644", "type" -> "blob", "sha" -> None|> & /@ deletePaths)
      ];
    ];
    treeResp = iCreateTree[token, owner, repo, baseTreeSHA, entries];
    If[FailureQ[treeResp], Return[treeResp]];
    newTreeSHA = Lookup[treeResp["Body"], "sha", Missing["NotAvailable"]];
    If[!StringQ[newTreeSHA],
      Return[iFailure["MissingNewTreeSHA", "新しい tree SHA を取得できませんでした。", <||>]]
    ];
    author = iNormalizePerson[OptionValue[Author]];
    committer = iNormalizePerson[OptionValue[Committer]];
    commitResp = iCreateCommit[token, owner, repo, message, newTreeSHA, headSHA, author, committer];
    If[FailureQ[commitResp], Return[commitResp]];
    newCommitSHA = Lookup[commitResp["Body"], "sha", Missing["NotAvailable"]];
    If[!StringQ[newCommitSHA],
      Return[iFailure["MissingCommitSHA", "新しい commit SHA を取得できませんでした。", <||>]]
    ];
    updateResp = iUpdateRef[token, owner, repo, branch, newCommitSHA, OptionValue[Force]];
    If[FailureQ[updateResp], Return[updateResp]];
    <|
      "Package" -> packageName,
      "Owner" -> owner,
      "Repository" -> repo,
      "Branch" -> branch,
      "CommitMessage" -> message,
      "CommitSHA" -> newCommitSHA,
      "TreeSHA" -> newTreeSHA,
      "UpdatedRef" -> updateResp["Body"]
    |>
  ];

Options[GitHubCreatePullRequest] = {
  Owner -> Automatic,
  Repository -> Automatic,
  Branch -> Automatic,
  Head -> Automatic,
  BaseBranch -> Automatic,
  Body -> "",
  Draft -> False,
  MaintainerCanModify -> True,
  Fallback -> False
};

GitHubCreatePullRequest[packageName_String, title_String, opts : OptionsPattern[]] :=
  Module[{token, owner, repo, head, base, resp},
    token = iAccessToken[];
    If[FailureQ[token], Return[token]];
    owner = iResolveOwner[token, OptionValue[Owner], packageName];
    If[FailureQ[owner], Return[owner]];
    (* Fallback オプションを  に反映 *)
    If[TrueQ[OptionValue[Fallback]],
      ClaudeCode = True];
    repo = iResolveRepository[packageName, OptionValue[Repository]];
    If[FailureQ[repo], Return[repo]];
    base = iResolveBaseBranch[token, owner, repo, OptionValue[BaseBranch]];
    If[FailureQ[base], Return[base]];
    head = Replace[OptionValue[Head], Automatic :> iResolveBranch[OptionValue[Branch], base]];
    (* head と base が同じブランチなら PR を作れない *)
    If[head === base,
      Return[iFailure["SameBranch",
        "head (" <> head <> ") と base (" <> base <> ") が同じブランチです。\n" <>
        "PR には別ブランチが必要です。以下のいずれかを使ってください:\n" <>
        "  1. GitHubSubmitPullRequest[\"" <> packageName <> "\", \"" <> title <>
        "\", \"commit msg\"]  (* ブランチ作成 + コミット + PR を一括実行 *)\n" <>
        "  2. GitHubCreatePullRequest[\"" <> packageName <> "\", \"" <> title <>
        "\", Branch -> \"feature-branch\"]  (* 既存の別ブランチから PR *)",
        <|"Head" -> head, "Base" -> base|>]]
    ];
    resp = iAPICall[
      "POST",
      "repos/" <> owner <> "/" <> repo <> "/pulls",
      token,
      iCompactAssociation @ <|
        "title" -> title,
        "head" -> head,
        "base" -> base,
        "body" -> OptionValue[Body],
        "draft" -> TrueQ[OptionValue[Draft]],
        "maintainer_can_modify" -> TrueQ[OptionValue[MaintainerCanModify]]
      |>
    ];
    If[FailureQ[resp], Return[resp]];
    <|
      "Package" -> packageName,
      "Owner" -> owner,
      "Repository" -> repo,
      "Number" -> Lookup[resp["Body"], "number", Missing["NotAvailable"]],
      "URL" -> Lookup[resp["Body"], "html_url", Missing["NotAvailable"]],
      "State" -> Lookup[resp["Body"], "state", Missing["NotAvailable"]],
      "Response" -> resp["Body"]
    |>
  ];

Options[GitHubRefreshAndCommit] = {
  Owner -> Automatic,
  Repository -> Automatic,
  Branch -> Automatic,
  BaseBranch -> Automatic,
  CreateBranch -> Automatic,
  LocalRepoPath -> Automatic,
  DeleteMissing -> False,
  Force -> False,
  Author -> Automatic,
  Committer -> Automatic,
  ExtraDirectories -> {},
  Fallback -> False
};

GitHubRefreshAndCommit[packageName_String, message_String, opts : OptionsPattern[]] :=
  Module[{localDir, refreshResult, commitResult},
    (* Fallback オプションを $currentUseFallback に反映 *)
    If[TrueQ[OptionValue[Fallback]],
      ClaudeCode`Private`$currentUseFallback = True];
    localDir = GitHubEnsureLocalRepo[packageName, LocalRepoPath -> OptionValue[LocalRepoPath]];
    (* ExtraDirectories が指定されていれば manifest に永続追加 *)
    iAddExtraDirectories[packageName, OptionValue[ExtraDirectories]];
    refreshResult = iRefreshPackageGroup[packageName, localDir];
    If[FailureQ[refreshResult], Return[refreshResult]];
    commitResult = GitHubCommit[
      packageName,
      message,
      Owner -> OptionValue[Owner],
      Repository -> OptionValue[Repository],
      Branch -> OptionValue[Branch],
      BaseBranch -> OptionValue[BaseBranch],
      CreateBranch -> OptionValue[CreateBranch],
      LocalRepoPath -> OptionValue[LocalRepoPath],
      IncludePackageFile -> False,
      DeleteMissing -> OptionValue[DeleteMissing],
      Force -> OptionValue[Force],
      Author -> OptionValue[Author],
      Committer -> OptionValue[Committer]
    ];
    If[FailureQ[commitResult], Return[commitResult]];
    Join[
      <|
        "Action" -> "RefreshAndCommit",
        "RefreshResult" -> refreshResult
      |>,
      commitResult
    ]
  ];

Options[GitHubSubmitPullRequest] = {
  Owner -> Automatic,
  Repository -> Automatic,
  Branch -> Automatic,
  BaseBranch -> Automatic,
  LocalRepoPath -> Automatic,
  DeleteMissing -> False,
  Force -> False,
  Author -> Automatic,
  Committer -> Automatic,
  Body -> "",
  Draft -> False,
  MaintainerCanModify -> True,
  Fallback -> False
};

GitHubSubmitPullRequest[packageName_String, title_String, message_String, opts : OptionsPattern[]] :=
  Module[{branch, localDir, refreshResult, commitResult, prResult},
    branch = Replace[
      OptionValue[Branch],
      Automatic :> iAutoPRBranchName[packageName, title]
    ];
    localDir = GitHubEnsureLocalRepo[packageName, LocalRepoPath -> OptionValue[LocalRepoPath]];
    refreshResult = iRefreshPackageGroup[packageName, localDir];
    If[FailureQ[refreshResult], Return[refreshResult]];
    commitResult = GitHubCommit[
      packageName,
      message,
      Owner -> OptionValue[Owner],
      Repository -> OptionValue[Repository],
      Branch -> branch,
      BaseBranch -> OptionValue[BaseBranch],
      CreateBranch -> True,
      LocalRepoPath -> OptionValue[LocalRepoPath],
      IncludePackageFile -> False,
      DeleteMissing -> OptionValue[DeleteMissing],
      Force -> OptionValue[Force],
      Author -> OptionValue[Author],
      Committer -> OptionValue[Committer]
    ];
    If[FailureQ[commitResult], Return[commitResult]];
    prResult = GitHubCreatePullRequest[
      packageName,
      title,
      Owner -> OptionValue[Owner],
      Repository -> OptionValue[Repository],
      Branch -> branch,
      BaseBranch -> OptionValue[BaseBranch],
      Body -> OptionValue[Body],
      Draft -> OptionValue[Draft],
      MaintainerCanModify -> OptionValue[MaintainerCanModify]
    ];
    If[FailureQ[prResult], Return[prResult]];
    <|
      "Action" -> "SubmitPullRequest",
      "Package" -> packageName,
      "Branch" -> branch,
      "RefreshResult" -> refreshResult,
      "Commit" -> commitResult,
      "PullRequest" -> prResult
    |>
  ];


(* ============================================================
   リポジトリ名データベース (GithubRepositories/repo_database.json)
   日本語パッケージ名 → 英語リポジトリ名の対応表
   ============================================================ *)

$iRepoDBFile[] := FileNameJoin[{iPackageDirectory[], "GithubRepositories", "repo_database.json"}];

iLoadRepoDB[] :=
  Module[{path, raw, bytes, jsonStr},
    path = $iRepoDBFile[];
    If[!FileExistsQ[path], Return[<||>]];
    (* バイナリ読み込み + UTF-8 デコードで ShiftJIS 環境の問題を回避 *)
    bytes = Quiet @ Check[ReadByteArray[path], $Failed];
    If[FailureQ[bytes], Return[<||>]];
    jsonStr = Quiet @ Check[ByteArrayToString[bytes, "UTF-8"], $Failed];
    If[!StringQ[jsonStr], Return[<||>]];
    raw = Quiet @ Check[ImportString[jsonStr, "RawJSON"], $Failed];
    If[AssociationQ[raw], raw, <||>]
  ];

iSaveRepoDB[db_Association] :=
  Module[{path, dir, jsonRaw, codes, maxCode, hasNonASCII, jsonStr, bytes},
    path = $iRepoDBFile[];
    dir = DirectoryName[path];
    iEnsureDirectory[dir];
    (* ExportString → ShiftJIS 環境修正 → \uXXXX エスケープ *)
    jsonRaw = ExportString[db, "RawJSON", "Compact" -> False];
    codes = ToCharacterCode[jsonRaw];
    maxCode = Max[codes];
    hasNonASCII = maxCode > 127;
    jsonStr = Which[
      !hasNonASCII, jsonRaw,
      maxCode <= 255,
        ByteArrayToString[ByteArray[codes], "UTF-8"],
      True, jsonRaw
    ];
    jsonStr = iForceASCIIJSON[jsonStr];
    bytes = StringToByteArray[jsonStr, "UTF-8"];
    With[{strm = OpenWrite[path, BinaryFormat -> True]},
      BinaryWrite[strm, Normal[bytes]];
      Close[strm]];
    path
  ];

(* パッケージ名が ASCII のみか判定 *)
iIsASCIIName[name_String] := StringMatchQ[name, RegularExpression["^[\\x20-\\x7E]+$"]];

(* 日本語名から英語リポジトリ名を自動生成 *)

(* Claude API で日本語名を意味のある英語リポジトリ名に翻訳する *)
iTranslateToEnglishRepoName[packageName_String] :=
  Module[{queryFn, queryWithFbFn, prompt, result, lines, candidates, useFallback},
    (* Fallback は $currentUseFallback が明示的に True の場合のみ有効。
       それ以外では Claude Code のエラーをそのまま伝播して処理を停止させる。 *)
    useFallback = TrueQ[ClaudeCode`Private`$currentUseFallback];
    queryWithFbFn = Quiet @ Check[ClaudeCode`Private`iQueryWithFallback, $Failed];
    queryFn = Quiet @ Check[ClaudeCode`Private`iClaudeQueryRaw, $Failed];
    If[(queryWithFbFn === $Failed || !MatchQ[queryWithFbFn, _Symbol]) &&
       (queryFn === $Failed || !MatchQ[queryFn, _Symbol]),
      (* ClaudeCode が利用できない場合: Transliterate フォールバック *)
      Return[Quiet @ Check[
        Transliterate[packageName], packageName]]];
    prompt = "You are naming a GitHub repository. " <>
      "Translate the following Japanese package name into a short, " <>
      "descriptive English repository name using lowercase letters and hyphens. " <>
      "The name should reflect the meaning/purpose, not just romanization. " <>
      "Output EXACTLY 3 candidates, one per line, nothing else. " <>
      "No explanations, no numbering, no quotes.\n\n" <>
      "Japanese name: " <> packageName;
    (* Fallback 対応: $currentUseFallback が明示的に True の場合のみ iQueryWithFallback を使う *)
    result = If[useFallback && queryWithFbFn =!= $Failed && MatchQ[queryWithFbFn, _Symbol],
      Quiet @ Check[queryWithFbFn[prompt, True, None], $Failed],
      Quiet @ Check[queryFn[prompt], $Failed]];
    (* エラーレスポンス検出 *)
    If[!StringQ[result] || StringLength[result] == 0 ||
       StringContainsQ[result,
         "hit your limit" | "rate limit" | "overloaded" |
         "Error:" | "TIMEOUT" | "RunProcess" | "ExitCode=" |
         "resets" | "you-ve" | "error" | "failed",
         IgnoreCase -> True],
      (* Fallback=False: エラーを伝播して停止。絶対にリポジトリ名を生成しない。 *)
      If[!useFallback,
        Return[Failure["LLMQueryFailed",
          <|"Message" -> "リポジトリ名の翻訳に失敗しました (Claude Code 利用不可)。Fallback -> True で再試行してください。",
            "RawResponse" -> If[StringQ[result], StringTake[result, UpTo[200]], ""]|>]]];
      (* Fallback=True でも全モデル失敗: Transliterate にフォールバック *)
      Return[Quiet @ Check[Transliterate[packageName], packageName]]];
    (* 複数行から候補を取得 *)
    lines = Select[StringSplit[result, "\n"],
      StringLength[StringTrim[#]] > 0 &];
    candidates = iSlugifyRepoName /@ lines;
    candidates = Select[candidates, StringLength[#] > 0 && # =!= "package" &];
    If[Length[candidates] == 0,
      If[!useFallback,
        Failure["LLMQueryFailed",
          <|"Message" -> "リポジトリ名の翻訳結果が空でした。Fallback -> True で再試行してください。"|>],
        Quiet @ Check[Transliterate[packageName], packageName]],
      candidates]
  ];

(* 文字列を GitHub リポジトリ名に適した slug に変換 *)
iSlugifyRepoName[s_String] :=
  Module[{slug, chars},
    slug = ToLowerCase[s];
    (* 各文字を走査し、a-z, 0-9, ハイフン以外をハイフンに置換 *)
    chars = Characters[slug];
    chars = Map[
      If[LetterQ[#] && StringMatchQ[#, RegularExpression["[a-z]"]], #,
        If[DigitQ[#], #,
          If[# === "-", "-", "-"]]] &,
      chars];
    slug = StringJoin[chars];
    (* 連続ハイフンを1つに *)
    slug = StringReplace[slug, RegularExpression["-{2,}"] -> "-"];
    (* 先頭・末尾のハイフンを除去 *)
    slug = StringReplace[slug, RegularExpression["^-+"] -> ""];
    slug = StringReplace[slug, RegularExpression["-+$"] -> ""];
    If[StringLength[slug] == 0, "package", slug]
  ];

(* GitHub 上にリポジトリが存在するかチェック *)
iCheckRepoExists[token_String, owner_String, repoName_String] :=
  Module[{resp},
    resp = iAPICall["GET", "repos/" <> owner <> "/" <> repoName, token];
    !FailureQ[resp]
  ];

(* GitHub URL をパースして <|"owner" -> ..., "repo" -> ...|> を返す。
   https://github.com/owner/repo[.git][/...] を受け付ける *)
iParseGitHubURL[url_String] :=
  Module[{parts},
    parts = StringCases[url,
      RegularExpression[
        "(?:https?://)?(?:www\\.)?github\\.com/([^/]+)/([^/.]+)"] :>
      <|"owner" -> "$1", "repo" -> "$2"|>];
    If[Length[parts] > 0, First[parts], $Failed]
  ];

(* RepoDB から owner を取得。登録されていなければ Automatic *)
iRepoDBOwnerLookup[packageName_String] :=
  Module[{db, record, ow},
    db = iLoadRepoDB[];
    record = Lookup[db, packageName, <||>];
    ow = Lookup[record, "owner", Automatic];
    If[StringQ[ow] && StringLength[ow] > 0, ow, Automatic]
  ];

(* RepoDB に owner を含めてレコードを保存 *)
GitHubRepoDBSet[packageName_String, repoName_String, ownerName_String] :=
  Module[{db, record},
    db = iLoadRepoDB[];
    record = Lookup[db, packageName, <||>];
    record = Join[record, <|"repository" -> repoName,
      "packageName" -> packageName,
      "owner" -> ownerName,
      "updatedAt" -> DateString[Now, "ISODateTime"]|>];
    db[packageName] = record;
    iSaveRepoDB[db];
    record
  ];

iAutoRepoName[packageName_String] :=
  If[iIsASCIIName[packageName],
    packageName,
    (* 非 ASCII: Claude API で意味のある英語名に翻訳 *)
    Module[{translated, candidates, slug, token, owner, candidate, result},
      translated = iTranslateToEnglishRepoName[packageName];
      (* 翻訳が Failure なら即伝播して処理を停止 *)
      If[FailureQ[translated], Return[translated]];
      (* 翻訳結果がリストなら複数候補、文字列なら単一候補 *)
      candidates = If[ListQ[translated],
        translated,
        {iSlugifyRepoName[translated]}];
      (* GitHub 上の重複チェック *)
      token = Quiet @ iAccessToken[];
      If[FailureQ[token], Return[First[candidates]]];
      owner = Quiet @ iResolveOwner[token, Automatic];
      If[FailureQ[owner], Return[First[candidates]]];
      (* 候補を順にチェックし、存在しないものを採用 *)
      result = Catch[
        Do[
          If[!iCheckRepoExists[token, owner, c],
            Throw[c]],
          {c, candidates}];
        (* 全候補が存在する場合: 最初の候補にサフィックスを付ける *)
        slug = First[candidates];
        Do[
          candidate = slug <> "-" <> ToString[suffix];
          If[!iCheckRepoExists[token, owner, candidate],
            Throw[candidate]],
          {suffix, 2, 20}];
        (* 20 まで試してダメなら日付付き *)
        slug <> "-" <> DateString[{"Year", "Month", "Day"}]
      ];
      result
    ]
  ];

GitHubRepoDB[] := iLoadRepoDB[];

GitHubRepoDBSet[packageName_String, repoName_String] :=
  Module[{db, record},
    db = iLoadRepoDB[];
    record = Lookup[db, packageName, <||>];
    record = Join[record, <|"repository" -> repoName,
      "packageName" -> packageName,
      "updatedAt" -> DateString[Now, "ISODateTime"]|>];
    db[packageName] = record;
    iSaveRepoDB[db];
    record
  ];

GitHubRepoDBLookup[packageName_String] :=
  Module[{db, record},
    db = iLoadRepoDB[];
    record = Lookup[db, packageName, <||>];
    Lookup[record, "repository", packageName]
  ];

(* iResolveRepository をオーバーライド: DB を先に参照 *)
iResolveRepository[packageName_String, Automatic] :=
  Module[{dbName},
    dbName = GitHubRepoDBLookup[packageName];
    If[!iIsASCIIName[dbName],
      (* まだ DB に英語名がない → 自動生成して登録 *)
      dbName = iAutoRepoName[packageName];
      (* Failure なら即伝播 — DB に不正な値を登録しない *)
      If[FailureQ[dbName], Return[dbName]];
      GitHubRepoDBSet[packageName, dbName]];
    dbName
  ];

(* ============================================================
   パッケージの初回ダウンロードと更新
   ============================================================ *)

Options[GitHubInstallPackage] = {
  Owner -> Automatic, Repository -> Automatic,
  Branch -> Automatic, BaseBranch -> Automatic,
  Fallback -> False
};

GitHubInstallPackage[packageName_String, opts:OptionsPattern[]] :=
  Module[{token, owner, repo, baseBranch, branch, localDir,
          pullResult, pkgDir, manifest, files, dirs, src, dst, installed = {},
          isPaclet, isRemote, hasInfoDir},
    token = iAccessToken[];
    If[FailureQ[token], Return[token]];
    owner = iResolveOwner[token, OptionValue[Owner], packageName];
    If[FailureQ[owner], Return[owner]];
    (* Fallback オプションを  に反映 *)
    If[TrueQ[OptionValue[Fallback]],
      ClaudeCode = True];
    repo = iResolveRepository[packageName, OptionValue[Repository]];
    If[FailureQ[repo], Return[repo]];
    (* 明示的に Repository が指定された場合も repo_database に登録 *)
    If[OptionValue[Repository] =!= Automatic && !iIsASCIIName[packageName],
      GitHubRepoDBSet[packageName, repo]];
    baseBranch = iResolveBaseBranch[token, owner, repo, OptionValue[BaseBranch]];
    If[FailureQ[baseBranch], Return[baseBranch]];
    branch = iResolveBranch[OptionValue[Branch], baseBranch];
    pkgDir = iPackageDirectory[];
    (* GithubRepositories へ pull *)
    localDir = GitHubEnsureLocalRepo[packageName];
    pullResult = GitHubPull[packageName, Owner -> owner, Repository -> repo,
      Branch -> branch, BaseBranch -> baseBranch, Clean -> True];
    If[FailureQ[pullResult], Return[pullResult]];
    (* リポジトリの種別を判定 *)
    isPaclet = AnyTrue[FileNames["*", localDir],
      DirectoryQ[#] && FileExistsQ[FileNameJoin[{#, "PacletInfo.wl"}]] &];
    isRemote = iIsRemotePackage[packageName];
    (* claudecode 製パッケージか判定: _info フォルダが存在するか *)
    hasInfoDir = DirectoryQ[FileNameJoin[{localDir, iInfoDirName[packageName]}]];

    (* local repo から $packageDirectory へコピー — 3 パターン *)
    Which[
      (* ── パターン A: 自分のリポジトリ ── *)
      (* 全ファイル・全フォルダをそのままコピー *)
      !isRemote,
      Do[
        src = FileNameJoin[{localDir, file}];
        If[FileExistsQ[src],
          dst = FileNameJoin[{pkgDir, file}];
          iEnsureDirectory[DirectoryName[dst]];
          Quiet @ CopyFile[src, dst, OverwriteTarget -> True];
          AppendTo[installed, file]],
      {file, Select[
        FileNames["*", localDir],
        (!DirectoryQ[#] && FileNameTake[#] =!= ".gitignore") &] //
        (FileNameTake /@ # &)}];
      Module[{excludePatterns = iMergedExcludePatterns[packageName]},
        Do[
          src = FileNameJoin[{localDir, dir}];
          If[DirectoryQ[src],
            dst = FileNameJoin[{pkgDir, dir}];
            iCopyDirectoryPreservingExcluded[src, dst, dir, excludePatterns];
            AppendTo[installed, dir <> "/"]],
        {dir, Select[
          FileNames["*", localDir],
          DirectoryQ] // (FileNameTake /@ # &)}]],

      (* ── パターン B: リモート + _info あり (claudecode 製 / パクレット含む) ── *)
      (* README.md はスキップ（_info/docs/README.md と同一）。
         それ以外のファイル・フォルダは全てそのまま $packageDirectory へコピー。
         コミット時に iRefreshPackageGroup が docs/README.md → トップ README.md に同期する。 *)
      hasInfoDir,
      Do[
        src = FileNameJoin[{localDir, file}];
        If[FileExistsQ[src] && file =!= "README.md",
          dst = FileNameJoin[{pkgDir, file}];
          iEnsureDirectory[DirectoryName[dst]];
          Quiet @ CopyFile[src, dst, OverwriteTarget -> True];
          AppendTo[installed, file]],
      {file, Select[
        FileNames["*", localDir],
        (!DirectoryQ[#] && FileNameTake[#] =!= ".gitignore") &] //
        (FileNameTake /@ # &)}];
      Module[{excludePatterns = iMergedExcludePatterns[packageName]},
        Do[
          src = FileNameJoin[{localDir, dir}];
          If[DirectoryQ[src],
            dst = FileNameJoin[{pkgDir, dir}];
            iCopyDirectoryPreservingExcluded[src, dst, dir, excludePatterns];
            AppendTo[installed, dir <> "/"]],
          {dir, Select[
            FileNames["*", localDir],
            DirectoryQ] // (FileNameTake /@ # &)}]],

      (* ── パターン C: リモート + _info なし (外部パッケージ) ── *)
      (* .wl は $packageDirectory へ、それ以外は _info/originals/ へ振り分け *)
      True,
      Module[{originalsDir, originalsMapping = {}, allFiles, infoDir},
        originalsDir = iOriginalsDir[packageName];
        iEnsureDirectory[originalsDir];
        infoDir = iInfoDirName[packageName];
        allFiles = Select[
          FileNames["*", localDir],
          (!DirectoryQ[#] && FileNameTake[#] =!= ".gitignore") &] //
          (FileNameTake /@ # &);
        Do[
          src = FileNameJoin[{localDir, file}];
          If[FileExistsQ[src],
            If[StringMatchQ[FileExtension[file], "wl", IgnoreCase -> True],
              (* .wl ファイルは $packageDirectory へ直接コピー *)
              dst = FileNameJoin[{pkgDir, file}];
              iEnsureDirectory[DirectoryName[dst]];
              Quiet @ CopyFile[src, dst, OverwriteTarget -> True];
              AppendTo[installed, file],
              (* その他のファイルは _info/originals/ へ *)
              dst = FileNameJoin[{originalsDir, file}];
              iEnsureDirectory[DirectoryName[dst]];
              Quiet @ CopyFile[src, dst, OverwriteTarget -> True];
              AppendTo[installed, FileNameJoin[{infoDir, "originals", file}]];
              AppendTo[originalsMapping,
                <|"repoPath" -> file,
                  "localPath" -> StringReplace[
                    FileNameJoin[{infoDir, "originals", file}], "\\" -> "/"]|>]
            ]],
          {file, allFiles}];
        (* サブディレクトリも _info/originals/ へ *)
        Do[
          src = FileNameJoin[{localDir, dir}];
          If[DirectoryQ[src],
            Module[{subFiles, relPath},
              subFiles = FileNames["**", src];
              Do[
                If[!DirectoryQ[sf],
                  relPath = FileNameDrop[sf, FileNameDepth[localDir]];
                  dst = FileNameJoin[{originalsDir, relPath}];
                  iEnsureDirectory[DirectoryName[dst]];
                  Quiet @ CopyFile[sf, dst, OverwriteTarget -> True];
                  AppendTo[originalsMapping,
                    <|"repoPath" -> iNormalizeGitPath[relPath],
                      "localPath" -> iNormalizeGitPath[
                        FileNameJoin[{infoDir, "originals", relPath}]]|>]],
                {sf, subFiles}];
              AppendTo[installed, FileNameJoin[{infoDir, "originals", dir}] <> "/"]
            ]],
          {dir, Select[
            FileNames["*", localDir],
            DirectoryQ] // (FileNameTake /@ # &)}];
        (* Originals マッピングを doc_options.json に保存 *)
        iSaveOriginals[packageName, originalsMapping];
        Print["\:2139 \:5916\:90e8\:30d1\:30c3\:30b1\:30fc\:30b8: \:975e .wl \:30d5\:30a1\:30a4\:30eb\:3092 " <> originalsDir <> " \:306b\:914d\:7f6e (" <>
          ToString[Length[originalsMapping]] <> " \:30d5\:30a1\:30a4\:30eb)"]
      ]
    ];
    <|"Package" -> packageName, "Owner" -> owner, "Repository" -> repo,
      "Branch" -> branch, "InstalledTo" -> pkgDir, "Items" -> installed|>
  ];

(* URL 付き2引数版: 他人のリポジトリからインストール *)
GitHubInstallPackage[packageName_String, url_String, opts:OptionsPattern[]] :=
  Module[{parsed, remoteOwner, remoteRepo},
    parsed = iParseGitHubURL[url];
    If[FailureQ[parsed],
      Return[iFailure["InvalidURL",
        "GitHub URL \:3092\:30d1\:30fc\:30b9\:3067\:304d\:307e\:305b\:3093: " <> url <>
        "\n\:5f62\:5f0f: https://github.com/owner/repo"]]];
    remoteOwner = parsed["owner"];
    remoteRepo = parsed["repo"];
    (* RepoDB に owner + repository を登録 *)
    GitHubRepoDBSet[packageName, remoteRepo, remoteOwner];
    Print["\:30ea\:30e2\:30fc\:30c8\:30ea\:30dd\:30b8\:30c8\:30ea\:3092\:767b\:9332: " <> remoteOwner <> "/" <> remoteRepo <>
      " \[RightArrow] " <> packageName];
    (* Owner と Repository を明示的に指定して既存の InstallPackage に委譲 *)
    GitHubInstallPackage[packageName,
      Owner -> remoteOwner, Repository -> remoteRepo,
      Sequence @@ FilterRules[{opts}, Except[Owner | Repository]]]
  ];

Options[GitHubUpdatePackage] = {
  Owner -> Automatic, Repository -> Automatic,
  Branch -> Automatic, BaseBranch -> Automatic,
  Fallback -> False
};

GitHubUpdatePackage[packageName_String, opts:OptionsPattern[]] :=
  GitHubInstallPackage[packageName, opts];

(* ============================================================
   プルリクエスト管理
   ============================================================ *)

Options[GitHubListPullRequests] = {
  Owner -> Automatic, Repository -> Automatic,
  Fallback -> False
};

GitHubListPullRequests[packageName_String, opts:OptionsPattern[]] :=
  Module[{token, owner, repo, resp, prs, sorted},
    token = iAccessToken[];
    If[FailureQ[token], Return[token]];
    owner = iResolveOwner[token, OptionValue[Owner], packageName];
    If[FailureQ[owner], Return[owner]];
    (* Fallback オプションを  に反映 *)
    If[TrueQ[OptionValue[Fallback]],
      ClaudeCode = True];
    repo = iResolveRepository[packageName, OptionValue[Repository]];
    If[FailureQ[repo], Return[repo]];
    resp = iAPICall["GET",
      "repos/" <> owner <> "/" <> repo <> "/pulls",
      token, None, <|"state" -> "open", "per_page" -> 100|>];
    If[FailureQ[resp], Return[resp]];
    prs = resp["Body"];
    If[!ListQ[prs], Return[{}]];
    (* ラベルから緊急度・重要度を推定 *)
    sorted = SortBy[prs,
      Function[pr, Module[{labels, title, urgency, importance},
        labels = StringJoin[Lookup[#, "name", ""] & /@
          Lookup[pr, "labels", {}]];
        title = Lookup[pr, "title", ""];
        urgency = Which[
          StringContainsQ[labels, "urgent" | "critical" | "hotfix", IgnoreCase -> True], 0,
          StringContainsQ[labels, "high", IgnoreCase -> True], 1,
          StringContainsQ[labels, "low", IgnoreCase -> True], 3,
          True, 2];
        importance = Which[
          StringContainsQ[labels, "breaking" | "security", IgnoreCase -> True], 0,
          StringContainsQ[labels, "bug" | "fix", IgnoreCase -> True], 1,
          StringContainsQ[labels, "feature" | "enhancement", IgnoreCase -> True], 2,
          True, 3];
        (* 依存関係: base が default branch でないものは後ろに *)
        {urgency, importance, -Lookup[pr, "number", 0]}
      ]]];
    sorted
  ];

Options[GitHubPullRequestDataset] = {
  Owner -> Automatic, Repository -> Automatic,
  Fallback -> False
};

GitHubPullRequestDataset[packageName_String, opts:OptionsPattern[]] :=
  Module[{prs, gridRows, header, pn = packageName},
    prs = GitHubListPullRequests[packageName, opts];
    If[FailureQ[prs] || !ListQ[prs], Return[prs]];
    If[Length[prs] == 0,
      Print["オープンな PR はありません。"]; Return[{}]];
    header = {Style["#", Bold], Style["Title", Bold], Style["Author", Bold],
      Style["Branch", Bold], Style["Created", Bold], Style["Actions", Bold]};
    gridRows = Map[
      Function[pr,
        Module[{num, title, user, created, head},
          num = Lookup[pr, "number", 0];
          title = Lookup[pr, "title", ""];
          user = Lookup[Lookup[pr, "user", <||>], "login", ""];
          created = Lookup[pr, "created_at", ""];
          head = Lookup[Lookup[pr, "head", <||>], "ref", ""];
          {num,
           StringTake[title, UpTo[40]],
           user,
           StringTake[head, UpTo[28]],
           StringTake[created, UpTo[10]],
           Row[{
             Button["Review",
               Module[{gk = "btn-review-pr:" <> pn <> ":" <> ToString[num]},
                 If[TrueQ[$iGitHubEvalGuard[gk]], Return[]];
                 $iGitHubEvalGuard[gk] = True;
                 WithCleanup[
                   NBAccess`NBWriteCell[EvaluationNotebook[],
                     Cell[BoxData[ToBoxes[
                       GitHubReviewPullRequest[pn, num]]], "Input"]],
                   $iGitHubEvalGuard = KeyDrop[$iGitHubEvalGuard, gk]]],
               Method -> "Queued", ImageSize -> {52, 22}],
             Button["Pull",
               Module[{res, gk = "btn-pull-pr:" <> pn <> ":" <> ToString[num]},
                 If[TrueQ[$iGitHubEvalGuard[gk]], Return[]];
                 $iGitHubEvalGuard[gk] = True;
                 WithCleanup[
                   Print["PR #" <> ToString[num] <> " ブランチを取得中..."];
                   res = GitHubPull[pn, Branch -> head];
                   If[!FailureQ[res],
                     Print["取得完了: " <> GitHubRepoPath[pn]];
                     NBAccess`NBWriteCell[EvaluationNotebook[],
                       Cell[BoxData[ToBoxes[
                         Block[{$CharacterEncoding = "UTF-8"},
                           Get[FileNameJoin[{GitHubRepoPath[pn], pn <> ".wl"}]]]
                       ]], "Input"]],
                     Print[res]],
                   $iGitHubEvalGuard = KeyDrop[$iGitHubEvalGuard, gk]]],
               Method -> "Queued", ImageSize -> {52, 22}],
             Button["Merge",
               Module[{reason, gk = "btn-merge-pr:" <> pn <> ":" <> ToString[num]},
                 If[TrueQ[$iGitHubEvalGuard[gk]], Return[]];
                 $iGitHubEvalGuard[gk] = True;
                 WithCleanup[
                   reason = InputString["マージ理由を入力:"];
                   If[StringQ[reason],
                     Print[GitHubMergePullRequest[pn, num, reason]]],
                   $iGitHubEvalGuard = KeyDrop[$iGitHubEvalGuard, gk]]],
               Method -> "Queued", ImageSize -> {52, 22}],
             Button["Close",
               Module[{reason, gk = "btn-close-pr:" <> pn <> ":" <> ToString[num]},
                 If[TrueQ[$iGitHubEvalGuard[gk]], Return[]];
                 $iGitHubEvalGuard[gk] = True;
                 WithCleanup[
                   reason = InputString["クローズ理由を入力:"];
                   If[StringQ[reason],
                     Print[GitHubClosePullRequest[pn, num, reason]]],
                   $iGitHubEvalGuard = KeyDrop[$iGitHubEvalGuard, gk]]],
               Method -> "Queued", ImageSize -> {52, 22}]
           }, Spacer[3]]}
        ]],
      prs];
    Grid[Prepend[gridRows, header],
      Alignment -> {Left, Center},
      Dividers -> {None, {2 -> GrayLevel[0.7]}},
      Spacings -> {1.5, 0.8},
      Background -> {None, {GrayLevel[0.95], None}},
      ItemSize -> {{3, 20, 8, 18, 8, Automatic}, Automatic}]
  ];

Options[GitHubMergePullRequest] = {
  Owner -> Automatic, Repository -> Automatic,
  Fallback -> False
};

GitHubMergePullRequest[packageName_String, prNumber_Integer, reason_String:"",
    opts:OptionsPattern[]] :=
  Module[{token, owner, repo, resp, commentResp},
    token = iAccessToken[];
    If[FailureQ[token], Return[token]];
    owner = iResolveOwner[token, OptionValue[Owner], packageName];
    If[FailureQ[owner], Return[owner]];
    (* Fallback オプションを  に反映 *)
    If[TrueQ[OptionValue[Fallback]],
      ClaudeCode = True];
    repo = iResolveRepository[packageName, OptionValue[Repository]];
    If[FailureQ[repo], Return[repo]];
    (* コメントとして理由を残す *)
    If[StringLength[reason] > 0,
      commentResp = iAPICall["POST",
        "repos/" <> owner <> "/" <> repo <> "/issues/" <> ToString[prNumber] <> "/comments",
        token, <|"body" -> "\:30de\:30fc\:30b8\:7406\:7531: " <> reason|>]];
    resp = iAPICall["PUT",
      "repos/" <> owner <> "/" <> repo <> "/pulls/" <> ToString[prNumber] <> "/merge",
      token, <|"commit_title" -> "Merge PR #" <> ToString[prNumber],
               "commit_message" -> reason, "merge_method" -> "merge"|>];
    If[FailureQ[resp], Return[resp]];
    <|"Action" -> "Merged", "PR" -> prNumber, "Package" -> packageName,
      "Reason" -> reason, "Response" -> resp["Body"]|>
  ];

Options[GitHubClosePullRequest] = {
  Owner -> Automatic, Repository -> Automatic,
  Fallback -> False
};

GitHubClosePullRequest[packageName_String, prNumber_Integer, reason_String:"",
    opts:OptionsPattern[]] :=
  Module[{token, owner, repo, resp, commentResp},
    token = iAccessToken[];
    If[FailureQ[token], Return[token]];
    owner = iResolveOwner[token, OptionValue[Owner], packageName];
    If[FailureQ[owner], Return[owner]];
    (* Fallback オプションを  に反映 *)
    If[TrueQ[OptionValue[Fallback]],
      ClaudeCode = True];
    repo = iResolveRepository[packageName, OptionValue[Repository]];
    If[FailureQ[repo], Return[repo]];
    If[StringLength[reason] > 0,
      commentResp = iAPICall["POST",
        "repos/" <> owner <> "/" <> repo <> "/issues/" <> ToString[prNumber] <> "/comments",
        token, <|"body" -> "\:30af\:30ed\:30fc\:30ba\:7406\:7531: " <> reason|>]];
    resp = iAPICall["PATCH",
      "repos/" <> owner <> "/" <> repo <> "/pulls/" <> ToString[prNumber],
      token, <|"state" -> "closed"|>];
    If[FailureQ[resp], Return[resp]];
    <|"Action" -> "Closed", "PR" -> prNumber, "Package" -> packageName,
      "Reason" -> reason, "Response" -> resp["Body"]|>
  ];

Options[GitHubReviewPullRequest] = {
  Owner -> Automatic, Repository -> Automatic,
  Fallback -> False
};

GitHubReviewPullRequest[packageName_String, prNumber_Integer, opts:OptionsPattern[]] :=
  Module[{token, owner, repo, prResp, prBody, headBranch, headSHA,
          filesResp, files, nb, tempDir, pn = packageName, num = prNumber,
          guardKey},
    (* Undo 再評価防止ガード *)
    guardKey = "review-pr:" <> packageName <> ":" <> ToString[prNumber];
    If[TrueQ[$iGitHubEvalGuard[guardKey]],
      Return[$Failed]];
    $iGitHubEvalGuard[guardKey] = True;
    WithCleanup[Null,
    token = iAccessToken[];
    If[FailureQ[token], Return[token]];
    owner = iResolveOwner[token, OptionValue[Owner], packageName];
    If[FailureQ[owner], Return[owner]];
    (* Fallback オプションを  に反映 *)
    If[TrueQ[OptionValue[Fallback]],
      ClaudeCode = True];
    repo = iResolveRepository[packageName, OptionValue[Repository]];
    If[FailureQ[repo], Return[repo]];
    (* PR 情報取得 *)
    prResp = iAPICall["GET",
      "repos/" <> owner <> "/" <> repo <> "/pulls/" <> ToString[prNumber], token];
    If[FailureQ[prResp], Return[prResp]];
    prBody = prResp["Body"];
    headBranch = Lookup[Lookup[prBody, "head", <||>], "ref", ""];
    (* 変更ファイル一覧 *)
    filesResp = iAPICall["GET",
      "repos/" <> owner <> "/" <> repo <> "/pulls/" <> ToString[prNumber] <> "/files",
      token, None, <|"per_page" -> 100|>];
    files = If[!FailureQ[filesResp], filesResp["Body"], {}];
    nb = Quiet[EvaluationNotebook[]];
    (* レビュー情報を CellGroup としてまとめて出力 *)
    Module[{cells = {}, prTitle, prInfo},
      prTitle = "PR #" <> ToString[prNumber] <> ": " <> Lookup[prBody, "title", ""];
      prInfo = prTitle <>
        "\nBranch: " <> headBranch <>
        "\nAuthor: " <> Lookup[Lookup[prBody, "user", <||>], "login", ""] <>
        "\nFiles: " <> ToString[Length[files]] <>
        "\n\n" <> Replace[Lookup[prBody, "body", "(本文なし)"],
          Except[_String] -> "(本文なし)"];
      AppendTo[cells, Cell[prTitle, "Subsection"]];
      AppendTo[cells, Cell[prInfo, "Text"]];
      Do[
        AppendTo[cells, Cell[
          "--- " <> Lookup[f, "filename", ""] <> " (" <>
          Lookup[f, "status", ""] <> ", +" <>
          ToString[Lookup[f, "additions", 0]] <> " -" <>
          ToString[Lookup[f, "deletions", 0]] <> ")\n" <>
          StringTake[Lookup[f, "patch", ""], UpTo[2000]],
          "Program"]],
      {f, Take[files, UpTo[10]]}];
      AppendTo[cells, Cell[BoxData[ToBoxes[
        Column[{
          Style["コードレビュー完了後のアクション:", Bold],
          "(* PR ブランチをローカルに取得して検証 *)",
          "GitHubPull[\"" <> pn <> "\", Branch -> \"" <> headBranch <> "\"]",
          "(* テスト実行 *)",
          "Block[{$CharacterEncoding = \"UTF-8\"},\n  Get[FileNameJoin[{GitHubRepoPath[\"" <>
              pn <> "\"], \"" <> pn <> ".wl\"}]]]",
          "",
          Row[{
            With[{pkgName = pn, prNum = num},
              Button["Merge", Module[{r = InputString["\:30de\:30fc\:30b8\:7406\:7531:"]},
                If[StringQ[r], Print[GitHubMergePullRequest[pkgName, prNum, r]]]],
                Method -> "Queued"]],
            Spacer[20],
            With[{pkgName = pn, prNum = num},
              Button["Close", Module[{r = InputString["\:30af\:30ed\:30fc\:30ba\:7406\:7531:"]},
                If[StringQ[r], Print[GitHubClosePullRequest[pkgName, prNum, r]]]],
                Method -> "Queued"]]
          }]
        }]
      ]], "Output"]];
      NBAccess`NBWriteCell[nb, Cell[CellGroupData[cells, Open]]];
    ];
    <|"Action" -> "Review", "PR" -> prNumber, "Package" -> packageName,
      "Branch" -> headBranch, "FilesChanged" -> Length[files]|>,
    (* WithCleanup 終了: ガード解除 *)
    $iGitHubEvalGuard = KeyDrop[$iGitHubEvalGuard, guardKey]]
  ];

(* ============================================================
   コミット履歴: 一覧取得・インタラクティブ表示・レビュー・リバート
   ============================================================ *)

Options[GitHubListCommits] = {
  Owner -> Automatic, Repository -> Automatic,
  Branch -> Automatic, BaseBranch -> Automatic,
  MaxItems -> 30,
  Fallback -> False
};

GitHubListCommits[packageName_String, opts:OptionsPattern[]] :=
  Module[{token, owner, repo, baseBranch, branch, resp, commits, maxN},
    token = iAccessToken[];
    If[FailureQ[token], Return[token]];
    owner = iResolveOwner[token, OptionValue[Owner], packageName];
    If[FailureQ[owner], Return[owner]];
    (* Fallback オプションを  に反映 *)
    If[TrueQ[OptionValue[Fallback]],
      ClaudeCode = True];
    repo = iResolveRepository[packageName, OptionValue[Repository]];
    If[FailureQ[repo], Return[repo]];
    baseBranch = iResolveBaseBranch[token, owner, repo, OptionValue[BaseBranch]];
    If[FailureQ[baseBranch], Return[baseBranch]];
    branch = iResolveBranch[OptionValue[Branch], baseBranch];
    maxN = Replace[OptionValue[MaxItems], Except[_Integer?Positive] -> 30];
    resp = iAPICall["GET",
      "repos/" <> owner <> "/" <> repo <> "/commits",
      token, None, <|"sha" -> branch, "per_page" -> Min[maxN, 100]|>];
    If[FailureQ[resp], Return[resp]];
    commits = resp["Body"];
    If[!ListQ[commits], Return[{}]];
    Take[commits, UpTo[maxN]]
  ];

(* コミットメッセージを短縮表示 *)
iTruncateCommitMsg[msg_String, maxLen_Integer:40] :=
  Module[{firstLine},
    firstLine = First[StringSplit[msg, "\n"], msg];
    If[StringLength[firstLine] > maxLen,
      StringTake[firstLine, maxLen] <> "\:2026",
      firstLine]
  ];

Options[GitHubCommitDataset] = {
  Owner -> Automatic, Repository -> Automatic,
  Branch -> Automatic, BaseBranch -> Automatic,
  MaxItems -> 30,
  Fallback -> False
};

GitHubCommitDataset[packageName_String, opts:OptionsPattern[]] :=
  Module[{commits, gridRows, header, localRow, pn = packageName,
          ownerOpt = OptionValue[Owner], repoOpt = OptionValue[Repository],
          branchOpt = OptionValue[Branch], baseBranchOpt = OptionValue[BaseBranch],
          hasSnapshot, snapDir, outputTag, warningTag, gridResult},
    (* 起動時: 既存スナップショットを削除し、現在の作業状態をローカル最新版として保存する。 *)
    snapDir = iLocalSnapshotDir[packageName];
    If[DirectoryQ[snapDir],
      Quiet @ DeleteDirectory[snapDir, DeleteContents -> True]];
    iSaveLocalSnapshot[packageName];
    commits = GitHubListCommits[packageName, opts];
    If[FailureQ[commits] || !ListQ[commits], Return[commits]];
    If[Length[commits] == 0,
      Print["\:30b3\:30df\:30c3\:30c8\:304c\:3042\:308a\:307e\:305b\:3093\:3002"]; Return[{}]];
    (* Output セルと警告セルの一意タグを生成 *)
    outputTag = "GitHubCommitDataset$" <> packageName <> "$output";
    warningTag = "GitHubCommitDataset$" <> packageName <> "$warning";
    header = {Style["#", Bold], Style["SHA", Bold], Style["Author", Bold],
      Style["Date", Bold], Style["\:30e1\:30c3\:30bb\:30fc\:30b8", Bold], Style["Actions", Bold]};
    (* #0 行: ローカル最新版スナップショットへの復元 *)
    localRow = {
      Dynamic[Style[0, Bold, If[DirectoryQ[iLocalSnapshotDir[pn]], RGBColor[0, 0.5, 0], GrayLevel[0.6]]]],
      Dynamic[Style["local", FontFamily -> "Courier",
        FontColor -> If[DirectoryQ[iLocalSnapshotDir[pn]], RGBColor[0, 0.5, 0], GrayLevel[0.6]]]],
      "(自分)",
      Dynamic[If[DirectoryQ[iLocalSnapshotDir[pn]],
        DateString[
          Quiet @ Check[FileDate[iLocalSnapshotDir[pn]], Date[]],
          {"Year", "-", "Month", "-", "Day"}],
        "-"]],
      Dynamic[If[DirectoryQ[iLocalSnapshotDir[pn]],
        "ローカル最新版 (スナップショット保存済み)",
        "ローカル最新版 (未保存 \[Dash] Pull で自動作成)"]],
      With[{pkg = pn, oTag = outputTag, wTag = warningTag},
        Row[{
          Button["Pull",
            Module[{newerFiles, msg, nb, outputIndices, outputIdx, cells,
                    gk = "btn-pull-local:" <> pkg},
              If[TrueQ[$iGitHubEvalGuard[gk]], Return[]];
              $iGitHubEvalGuard[gk] = True;
              WithCleanup[
              nb = Quiet[EvaluationNotebook[]];
              If[!DirectoryQ[iLocalSnapshotDir[pkg]],
                Print["スナップショットが存在しません。先に過去コミットを Pull するとスナップショットが自動保存されます。"],
                (* スナップショットより変更されたファイルをチェック *)
                newerFiles = iDetectNewerThanSnapshot[pkg];
                If[Length[newerFiles] > 0,
                  (* 警告: 変更されたファイルが存在する — Output セル直後に挿入 *)
                  msg = "以下の " <> ToString[Length[newerFiles]] <>
                    " ファイルがスナップショットより新しく変更されています:\n\n" <>
                    StringRiffle[Take[newerFiles, UpTo[10]], "\n"] <>
                    If[Length[newerFiles] > 10,
                      "\n... 他 " <> ToString[Length[newerFiles] - 10] <> " ファイル", ""] <>
                    "\n\nローカル最新版で上書きすると、これらの変更は失われます。";
                  (* 古い警告セルがあれば削除 *)
                  NBAccess`NBDeleteCellsByTag[nb, wTag];
                  (* Output セル (Grid) の直後にカーソルを移動 *)
                  outputIndices = NBAccess`NBCellIndicesByTag[nb, oTag];
                  If[Length[outputIndices] > 0,
                    outputIdx = Last[outputIndices];
                    NBAccess`NBMoveAfterCell[nb, outputIdx],
                    (* フォールバック: ノートブック末尾へカーソル移動 *)
                    Quiet[SelectionMove[nb, After, Notebook]]
                  ];
                  (* 警告セルグループを書き込み *)
                  cells = Cell[CellGroupData[{
                    Cell["\:26a0 ローカル最新版への復元", "Subsubsection",
                      CellTags -> {wTag}],
                    Cell[msg, "Text"],
                    Cell[BoxData[ToBoxes[Row[{
                      Button["すべてローカル最新版に置き換える",
                        Module[{res, nb2},
                          nb2 = Quiet[EvaluationNotebook[]];
                          res = iRestoreLocalSnapshot[pkg];
                          If[!FailureQ[res],
                            Print["ローカル最新版に復元しました: " <>
                              ToString[res["FilesRestored"]] <> " ファイル"],
                            Print[res]];
                          NBAccess`NBDeleteCellsByTag[nb2, wTag]],
                        Method -> "Queued"],
                      Spacer[20],
                      Button["キャンセル",
                        Module[{nb2},
                          nb2 = Quiet[EvaluationNotebook[]];
                          Print["キャンセルしました。"];
                          NBAccess`NBDeleteCellsByTag[nb2, wTag]],
                        Method -> "Queued"]
                    }]]], "Output"]
                  }, Open]];
                  NBAccess`NBWriteCell[nb, cells],
                  (* 変更なし: 通常の確認ダイアログ *)
                  If[ChoiceDialog["ローカル最新版 (スナップショット) に復元しますか？\n" <>
                      "GithubRepositories と $packageDirectory の両方が復元されます。"],
                    Module[{res},
                      res = iRestoreLocalSnapshot[pkg];
                      If[!FailureQ[res],
                        Print["ローカル最新版に復元しました: " <>
                          ToString[res["FilesRestored"]] <> " ファイル"],
                        Print[res]]],
                    Print["キャンセルしました。"]]
                ]],
              (* WithCleanup 終了: ガード解除 *)
              $iGitHubEvalGuard = KeyDrop[$iGitHubEvalGuard, gk]]],
            Method -> "Queued", ImageSize -> {52, 22}]
        }, Spacer[3]]]
    };
    gridRows = MapIndexed[
      Function[{commit, idx},
        Module[{sha, author, date, msg, commitData},
          commitData = Lookup[commit, "commit", <||>];
          sha = StringTake[Lookup[commit, "sha", ""], UpTo[7]];
          author = Lookup[Lookup[commitData, "author", <||>], "name", ""];
          date = StringTake[Lookup[Lookup[commitData, "author", <||>], "date", ""], UpTo[10]];
          msg = Lookup[commitData, "message", ""];
          {First[idx],
           Style[sha, FontFamily -> "Courier"],
           StringTake[author, UpTo[15]],
           date,
           iTruncateCommitMsg[msg],
           Row[{
             With[{pkg = pn, s = Lookup[commit, "sha", ""],
                   ow = ownerOpt, rp = repoOpt},
               Button["Review",
                 Module[{gk = "btn-review:" <> pkg <> ":" <> s},
                   If[TrueQ[$iGitHubEvalGuard[gk]], Return[]];
                   $iGitHubEvalGuard[gk] = True;
                   WithCleanup[
                     GitHubReviewCommit[pkg, s, Owner -> ow, Repository -> rp],
                     $iGitHubEvalGuard = KeyDrop[$iGitHubEvalGuard, gk]]],
                 Method -> "Queued", ImageSize -> {52, 22}]],
             With[{pkg = pn, s = Lookup[commit, "sha", ""],
                   ow = ownerOpt, rp = repoOpt},
               Button["Pull",
                 Module[{res, gk = "btn-pull:" <> pkg <> ":" <> s},
                   If[TrueQ[$iGitHubEvalGuard[gk]], Return[]];
                   $iGitHubEvalGuard[gk] = True;
                   WithCleanup[
                     If[ChoiceDialog["コミット " <> StringTake[s, UpTo[7]] <>
                         " のファイルをローカルに取得しますか？\n" <>
                         "(現在の作業ファイルはスナップショットに自動保存されます)"],
                       Print["コミット " <> StringTake[s, UpTo[7]] <> " を取得中..."];
                       res = iGitHubPullAtCommit[pkg, s, Owner -> ow, Repository -> rp];
                       If[!FailureQ[res],
                         Print["取得完了: " <> ToString[res["FilesPulled"]] <>
                           " ファイル (GithubRepositories + $packageDirectory)"],
                         Print[res]],
                       Print["キャンセルしました。"]],
                     $iGitHubEvalGuard = KeyDrop[$iGitHubEvalGuard, gk]]],
                 Method -> "Queued", ImageSize -> {52, 22}]],
             With[{pkg = pn, s = Lookup[commit, "sha", ""],
                   ow = ownerOpt, rp = repoOpt,
                   bo = branchOpt, bbo = baseBranchOpt},
               Button["Revert",
                 Module[{reason, gk = "btn-revert:" <> pkg <> ":" <> s},
                   If[TrueQ[$iGitHubEvalGuard[gk]], Return[]];
                   $iGitHubEvalGuard[gk] = True;
                   WithCleanup[
                     reason = InputString["\:30ea\:30d0\:30fc\:30c8\:7406\:7531:"];
                     If[StringQ[reason],
                       Print[GitHubRevertCommit[pkg, s, reason,
                         Owner -> ow, Repository -> rp,
                         Branch -> bo, BaseBranch -> bbo]]],
                     $iGitHubEvalGuard = KeyDrop[$iGitHubEvalGuard, gk]]],
                 Method -> "Queued", ImageSize -> {52, 22}]]
           }, Spacer[3]]}
        ]],
      commits];
    (* Grid を CellPrint でタグ付き Output セルとして出力 *)
    gridResult = Grid[Prepend[Prepend[gridRows, localRow], header],
      Alignment -> {Left, Center},
      Dividers -> {None, {2 -> GrayLevel[0.7]}},
      Spacings -> {1.5, 0.8},
      Background -> {None, {GrayLevel[0.95], None}},
      ItemSize -> {{3, 6, 10, 8, 22, Automatic}, Automatic}];
    (* 古い出力・警告セルがあれば削除 *)
    Module[{nb = Quiet[EvaluationNotebook[]]},
      NBAccess`NBDeleteCellsByTag[nb, warningTag];
      NBAccess`NBDeleteCellsByTag[nb, outputTag];
      NBAccess`NBWriteCell[nb, Cell[BoxData[ToBoxes[gridResult]], "Output",
        CellTags -> {outputTag}]]];
  ];

(* ============================================================
   ローカルスナップショット管理
   Pull で過去コミットに巻き戻す前に、$packageDirectory の現在の状態を
   GithubRepositories/_local_snapshot/<packageName>/ に保存する。
   #0 行の Pull で復元可能。
   ============================================================ *)

iLocalSnapshotDir[packageName_String] :=
  FileNameJoin[{iPackageDirectory[], "GithubRepositories", "_local_snapshot", packageName}];

iSnapshotHashPath[packageName_String] :=
  FileNameJoin[{iLocalSnapshotDir[packageName], "_snapshot_hashes.json"}];

(* マニフェストに基づき $packageDirectory の作業ファイルをスナップショットに保存し、
   各ファイルの SHA-256 ハッシュを _snapshot_hashes.json に記録する。 *)
iSaveLocalSnapshot[packageName_String] :=
  Module[{snapDir, pkgDir, manifest, files, dirs, excludePatterns,
          src, dst, copiedFiles = {}, copiedDirs = {}, hashes = <||>},
    snapDir = iLocalSnapshotDir[packageName];
    (* 既存スナップショットを削除して新規作成 *)
    If[DirectoryQ[snapDir],
      Quiet @ DeleteDirectory[snapDir, DeleteContents -> True]];
    iEnsureDirectory[snapDir];
    pkgDir = iPackageDirectory[];
    manifest = iEnsureManifest[packageName];
    excludePatterns = iMergedExcludePatterns[packageName];
    (* 個別ファイルのコピー + ハッシュ記録 *)
    Do[
      src = FileNameJoin[{pkgDir, file}];
      If[FileExistsQ[src],
        dst = FileNameJoin[{snapDir, FileNameTake[src]}];
        Quiet @ CopyFile[src, dst, OverwriteTarget -> True];
        AppendTo[copiedFiles, file];
        hashes[file] = Quiet @ Check[FileHash[src, "SHA256", "HexString"], ""]],
      {file, Lookup[manifest, "files", {}]}];
    (* ディレクトリの再帰コピー + ハッシュ記録 *)
    Do[
      src = FileNameJoin[{pkgDir, dir}];
      If[DirectoryQ[src],
        Module[{dirFiles, relPath, f},
          dirFiles = Select[
            Join[FileNames["*", src, Infinity], FileNames[".*", src, Infinity]],
            FileExistsQ[#] && !DirectoryQ[#] &];
          Do[
            relPath = iNormalizeGitPath[
              dir <> "/" <> FileNameJoin[FileNameDrop[f, FileNameDepth[src]]]];
            If[!iMatchExcludePattern[relPath, excludePatterns],
              Module[{dstF},
                dstF = FileNameJoin[Flatten[{snapDir, FileNameSplit[relPath]}]];
                iEnsureDirectory[DirectoryName[dstF]];
                Quiet @ CopyFile[f, dstF, OverwriteTarget -> True];
                AppendTo[copiedDirs, relPath];
                hashes[relPath] = Quiet @ Check[FileHash[f, "SHA256", "HexString"], ""]]],
            {f, dirFiles}]]],
      {dir, Lookup[manifest, "directories", {}]}];
    (* README.md があれば *)
    Module[{readmeSrc, readmeDst},
      readmeSrc = FileNameJoin[{pkgDir, iInfoDirName[packageName], "docs", "README.md"}];
      readmeDst = FileNameJoin[{snapDir, "README.md"}];
      If[FileExistsQ[readmeSrc],
        Quiet @ CopyFile[readmeSrc, readmeDst, OverwriteTarget -> True]]];
    (* ハッシュを JSON で保存 *)
    Export[iSnapshotHashPath[packageName], hashes, "RawJSON"];
    <|"Action" -> "SaveSnapshot", "Package" -> packageName,
      "SnapshotDir" -> snapDir,
      "CopiedFiles" -> copiedFiles, "CopiedDirs" -> copiedDirs,
      "HashedFiles" -> Length[hashes]|>
  ];

(* ローカルスナップショットを $packageDirectory と GithubRepositories に復元 *)
iRestoreLocalSnapshot[packageName_String] :=
  Module[{snapDir, pkgDir, localDir, allFiles, relPath, src, dst, restored = 0},
    snapDir = iLocalSnapshotDir[packageName];
    If[!DirectoryQ[snapDir],
      Return[iFailure["NoSnapshot",
        "ローカルスナップショットが見つかりません。\n" <> snapDir]]];
    pkgDir = iPackageDirectory[];
    localDir = GitHubEnsureLocalRepo[packageName];
    (* localDir をクリーンアップ *)
    Scan[Quiet @ DeleteFile[#] &, iListLocalFiles[localDir]];
    (* $packageDirectory のマニフェスト対象ファイルもクリーンアップ *)
    iCleanManifestFilesInPkgDir[packageName];
    (* スナップショットから localDir と pkgDir の両方にコピー *)
    allFiles = iListLocalFiles[snapDir];
    Do[
      relPath = iRelativeGitPath[snapDir, file];
      (* localDir へコピー *)
      dst = FileNameJoin[Flatten[{localDir, FileNameSplit[relPath]}]];
      iEnsureDirectory[DirectoryName[dst]];
      Quiet @ CopyFile[file, dst, OverwriteTarget -> True];
      (* pkgDir へコピー *)
      dst = FileNameJoin[Flatten[{pkgDir, FileNameSplit[relPath]}]];
      iEnsureDirectory[DirectoryName[dst]];
      Quiet @ CopyFile[file, dst, OverwriteTarget -> True];
      restored++,
      {file, allFiles}];
    <|"Action" -> "RestoreSnapshot", "Package" -> packageName,
      "LocalRepoPath" -> localDir, "PackageDir" -> pkgDir,
      "FilesRestored" -> restored|>
  ];

(* マニフェスト対象のファイル・ディレクトリを $packageDirectory から削除する。
   コピーバック前に呼ぶことで、過去コミットに存在しないファイルが残らないようにする。 *)
iCleanManifestFilesInPkgDir[packageName_String] :=
  Module[{pkgDir, manifest, excludePatterns, target, deleted = 0},
    pkgDir = iPackageDirectory[];
    manifest = iEnsureManifest[packageName];
    (* マニフェストの excludePatterns にデフォルト保護パターンを統合 *)
    excludePatterns = iMergedExcludePatterns[packageName];
    (* 個別ファイルを削除 *)
    Do[
      target = FileNameJoin[{pkgDir, file}];
      If[FileExistsQ[target],
        Quiet @ DeleteFile[target]; deleted++],
      {file, Lookup[manifest, "files", {}]}];
    (* ディレクトリ配下のファイルを削除 (excludePatterns に該当するものは残す) *)
    Do[
      target = FileNameJoin[{pkgDir, dir}];
      If[DirectoryQ[target],
        Module[{allFiles, relPath},
          allFiles = iListLocalFiles[target];
          Do[
            relPath = iNormalizeGitPath[
              dir <> "/" <> FileNameJoin[FileNameDrop[f, FileNameDepth[target]]]];
            If[!iMatchExcludePattern[relPath, excludePatterns],
              Quiet @ DeleteFile[f]; deleted++],
            {f, allFiles}]]],
      {dir, Lookup[manifest, "directories", {}]}];
    deleted
  ];

(* $packageDirectory 内でスナップショット時から内容が変更されたファイルを検出する。
   スナップショット保存時に記録した SHA-256 ハッシュと現在のファイルハッシュを比較し、
   異なるファイルの相対パスのリストを返す。 *)
iDetectNewerThanSnapshot[packageName_String] :=
  Module[{snapDir, hashPath, savedHashes, pkgDir, manifest, excludePatterns,
          changedFiles = {}, target, currentHash, savedHash},
    snapDir = iLocalSnapshotDir[packageName];
    If[!DirectoryQ[snapDir], Return[{}]];
    hashPath = iSnapshotHashPath[packageName];
    savedHashes = Quiet @ Check[Import[hashPath, "RawJSON"], <||>];
    If[!AssociationQ[savedHashes], savedHashes = <||>];
    pkgDir = iPackageDirectory[];
    manifest = iEnsureManifest[packageName];
    excludePatterns = iMergedExcludePatterns[packageName];
    (* 個別ファイルをチェック *)
    Do[
      target = FileNameJoin[{pkgDir, file}];
      If[FileExistsQ[target],
        currentHash = Quiet @ Check[FileHash[target, "SHA256", "HexString"], ""];
        savedHash = Lookup[savedHashes, file, None];
        If[savedHash === None || currentHash =!= savedHash,
          AppendTo[changedFiles, file]]],
      {file, Lookup[manifest, "files", {}]}];
    (* ディレクトリ配下のファイルをチェック *)
    Do[
      target = FileNameJoin[{pkgDir, dir}];
      If[DirectoryQ[target],
        Module[{allFiles, relPath},
          allFiles = iListLocalFiles[target];
          Do[
            relPath = iNormalizeGitPath[
              dir <> "/" <> FileNameJoin[FileNameDrop[f, FileNameDepth[target]]]];
            If[!iMatchExcludePattern[relPath, excludePatterns],
              currentHash = Quiet @ Check[FileHash[f, "SHA256", "HexString"], ""];
              savedHash = Lookup[savedHashes, relPath, None];
              If[savedHash === None || currentHash =!= savedHash,
                AppendTo[changedFiles, relPath]]],
            {f, allFiles}]]],
      {dir, Lookup[manifest, "directories", {}]}];
    changedFiles
  ];

(* GithubRepositories/pkg のファイルを $packageDirectory へコピーバック。
   まずマニフェスト対象を削除してからコピーするので、
   過去コミットで存在しないファイルは $packageDirectory に残らない。 *)
iCopyLocalRepoToPackageDir[packageName_String, localDir_String] :=
  Module[{pkgDir, allFiles, relPath, dst, copied = 0, cleaned},
    pkgDir = iPackageDirectory[];
    (* マニフェスト対象ファイルを先に削除 *)
    cleaned = iCleanManifestFilesInPkgDir[packageName];
    allFiles = iListLocalFiles[localDir];
    Do[
      relPath = iRelativeGitPath[localDir, file];
      dst = FileNameJoin[Flatten[{pkgDir, FileNameSplit[relPath]}]];
      iEnsureDirectory[DirectoryName[dst]];
      Quiet @ CopyFile[file, dst, OverwriteTarget -> True];
      copied++,
      {file, allFiles}];
    <|"FilesCopied" -> copied, "FilesCleanedBefore" -> cleaned, "PackageDir" -> pkgDir|>
  ];

(* 特定コミット SHA のファイルをローカルに取得し $packageDirectory にも反映 *)
Options[iGitHubPullAtCommit] = {
  Owner -> Automatic, Repository -> Automatic,
  LocalRepoPath -> Automatic
};

iGitHubPullAtCommit[packageName_String, commitSHA_String, opts:OptionsPattern[]] :=
  Module[{token, owner, repo, localDir, commitObj, treeSHA,
          treeResp, entries, blobResp, blobBody, ba, localFile, pulled = 0,
          snapshotResult, copyResult, snapshotSaved = False},
    token = iAccessToken[];
    If[FailureQ[token], Return[token]];
    owner = iResolveOwner[token, OptionValue[Owner], packageName];
    If[FailureQ[owner], Return[owner]];
    (* Fallback オプションを  に反映 *)
    If[TrueQ[OptionValue[Fallback]],
      ClaudeCode = True];
    repo = iResolveRepository[packageName, OptionValue[Repository]];
    If[FailureQ[repo], Return[repo]];
    localDir = GitHubEnsureLocalRepo[packageName, LocalRepoPath -> OptionValue[LocalRepoPath]];
    (* スナップショットが存在しない場合のみ保存 (最初の Pull のみ)。
       既にスナップショットがある = 過去に巻き戻し済みなので温存する。 *)
    If[!DirectoryQ[iLocalSnapshotDir[packageName]],
      snapshotResult = iSaveLocalSnapshot[packageName];
      snapshotSaved = True;
      Print["ローカル最新版をスナップショットに保存しました: " <> iLocalSnapshotDir[packageName]],
      (* else *)
      Print["既存のローカル最新版スナップショットを温存します。"]
    ];
    (* localDir の既存ファイルをすべて削除してクリーンな状態にする *)
    Scan[Quiet @ DeleteFile[#] &, iListLocalFiles[localDir]];
    commitObj = iGetCommitObject[token, owner, repo, commitSHA];
    If[FailureQ[commitObj], Return[commitObj]];
    treeSHA = Lookup[Lookup[commitObj["Body"], "tree", <||>], "sha", Missing["NotAvailable"]];
    If[!StringQ[treeSHA],
      Return[iFailure["MissingTreeSHA", "コミットの tree SHA を取得できませんでした。"]]];
    treeResp = iGetTreeRecursive[token, owner, repo, treeSHA];
    If[FailureQ[treeResp], Return[treeResp]];
    entries = Select[
      Lookup[treeResp["Body"], "tree", {}],
      AssociationQ[#] && Lookup[#, "type", None] === "blob" &];
    Do[
      blobResp = iAPICall["GET",
        "repos/" <> owner <> "/" <> repo <> "/git/blobs/" <> Lookup[entry, "sha", ""],
        token];
      If[FailureQ[blobResp], Return[blobResp]];
      blobBody = blobResp["Body"];
      ba = iDecodeGitHubContent[
        Lookup[blobBody, "content", ""],
        Lookup[blobBody, "encoding", "base64"]];
      localFile = FileNameJoin[Prepend[StringSplit[Lookup[entry, "path", ""], "/"], localDir]];
      If[FailureQ[iWriteLocalByteArray[localFile, ba]],
        Return[iFailure["LocalPullWriteFailed",
          "ファイルを書き込めませんでした。", <|"File" -> localFile|>]]];
      pulled++,
      {entry, entries}];
    (* GithubRepositories から $packageDirectory へもコピー *)
    copyResult = iCopyLocalRepoToPackageDir[packageName, localDir];
    Print["$packageDirectory へ " <> ToString[copyResult["FilesCopied"]] <> " ファイルをコピーしました。"];
    <|"Action" -> "PullAtCommit", "Package" -> packageName,
      "Commit" -> StringTake[commitSHA, UpTo[7]],
      "LocalRepoPath" -> localDir, "FilesPulled" -> pulled,
      "SnapshotSaved" -> snapshotSaved,
      "FilesCopiedToPackageDir" -> copyResult["FilesCopied"]|>
  ];

Options[GitHubReviewCommit] = {
  Owner -> Automatic, Repository -> Automatic,
  Fallback -> False
};

GitHubReviewCommit[packageName_String, commitSHA_String, opts:OptionsPattern[]] :=
  Module[{token, owner, repo, resp, body, commitData, author, date, msg,
          files, nb, cells, pn = packageName, sha = commitSHA,
          guardKey},
    (* Undo 再評価防止ガード *)
    guardKey = "review:" <> packageName <> ":" <> commitSHA;
    If[TrueQ[$iGitHubEvalGuard[guardKey]],
      Return[$Failed]];
    $iGitHubEvalGuard[guardKey] = True;
    (* ガード自動解除 (正常終了・異常終了とも) *)
    WithCleanup[Null,
    token = iAccessToken[];
    If[FailureQ[token], Return[token]];
    owner = iResolveOwner[token, OptionValue[Owner], packageName];
    If[FailureQ[owner], Return[owner]];
    (* Fallback オプションを  に反映 *)
    If[TrueQ[OptionValue[Fallback]],
      ClaudeCode = True];
    repo = iResolveRepository[packageName, OptionValue[Repository]];
    If[FailureQ[repo], Return[repo]];
    (* commits API \:306f\:30d5\:30a1\:30a4\:30eb\:5dee\:5206\:3082\:542b\:3080 *)
    resp = iAPICall["GET",
      "repos/" <> owner <> "/" <> repo <> "/commits/" <> commitSHA, token];
    If[FailureQ[resp], Return[resp]];
    body = resp["Body"];
    commitData = Lookup[body, "commit", <||>];
    author = Lookup[Lookup[commitData, "author", <||>], "name", ""];
    date = Lookup[Lookup[commitData, "author", <||>], "date", ""];
    msg = Lookup[commitData, "message", ""];
    files = Lookup[body, "files", {}];
    nb = Quiet[EvaluationNotebook[]];
    cells = {
      Cell["Commit " <> StringTake[commitSHA, UpTo[7]] <> ": " <>
        First[StringSplit[msg, "\n"], ""], "Subsection"],
      Cell[
        "SHA: " <> commitSHA <>
        "\nAuthor: " <> author <>
        "\nDate: " <> date <>
        "\nFiles: " <> ToString[Length[files]] <>
        "\n\n" <> msg, "Text"]
    };
    Do[
      AppendTo[cells, Cell[
        "--- " <> Lookup[f, "filename", ""] <> " (" <>
        Lookup[f, "status", ""] <> ", +" <>
        ToString[Lookup[f, "additions", 0]] <> " -" <>
        ToString[Lookup[f, "deletions", 0]] <> ")\n" <>
        StringTake[Lookup[f, "patch", ""], UpTo[2000]],
        "Program"]],
      {f, Take[files, UpTo[15]]}];
    (* \:30a2\:30af\:30b7\:30e7\:30f3\:30dc\:30bf\:30f3 *)
    With[{pkgName = pn, s = sha,
          ow = OptionValue[Owner], rp = OptionValue[Repository]},
      AppendTo[cells, Cell[BoxData[ToBoxes[
        Row[{
          Button["Pull (ローカルに取得)",
            Module[{res},
              Print["コミット " <> StringTake[s, UpTo[7]] <> " を取得中 (スナップショット自動保存)..."];
              res = iGitHubPullAtCommit[pkgName, s, Owner -> ow, Repository -> rp];
              If[!FailureQ[res],
                Print["取得完了: " <> ToString[res["FilesPulled"]] <>
                  " ファイル (GithubRepositories + $packageDirectory)"],
                Print[res]]],
            Method -> "Queued"],
          Spacer[20],
          Button["Revert (\:30b3\:30df\:30c3\:30c8\:3092\:623b\:3059)",
            Module[{reason},
              reason = InputString["\:30ea\:30d0\:30fc\:30c8\:7406\:7531:"];
              If[StringQ[reason],
                Print[GitHubRevertCommit[pkgName, s, reason,
                  Owner -> ow, Repository -> rp]]]],
            Method -> "Queued"]
        }]
      ]], "Output"]]];
    NBAccess`NBWriteCell[nb, Cell[CellGroupData[cells, Open]]];
    <|"Action" -> "ReviewCommit", "Package" -> packageName,
      "SHA" -> commitSHA, "FilesChanged" -> Length[files]|>,
    (* WithCleanup 終了: ガード解除 *)
    $iGitHubEvalGuard = KeyDrop[$iGitHubEvalGuard, guardKey]]
  ];

Options[GitHubRevertCommit] = {
  Owner -> Automatic, Repository -> Automatic,
  Branch -> Automatic, BaseBranch -> Automatic,
  Fallback -> False
};

GitHubRevertCommit[packageName_String, commitSHA_String, reason_String:"",
    opts:OptionsPattern[]] :=
  Module[{token, owner, repo, baseBranch, branch,
          commitResp, commitBody, parentSHAs, parentSHA,
          parentObj, parentTreeSHA,
          headRef, headSHA, newCommitMsg, newCommit, updateResp},
    token = iAccessToken[];
    If[FailureQ[token], Return[token]];
    owner = iResolveOwner[token, OptionValue[Owner], packageName];
    If[FailureQ[owner], Return[owner]];
    (* Fallback オプションを  に反映 *)
    If[TrueQ[OptionValue[Fallback]],
      ClaudeCode = True];
    repo = iResolveRepository[packageName, OptionValue[Repository]];
    If[FailureQ[repo], Return[repo]];
    baseBranch = iResolveBaseBranch[token, owner, repo, OptionValue[BaseBranch]];
    If[FailureQ[baseBranch], Return[baseBranch]];
    branch = iResolveBranch[OptionValue[Branch], baseBranch];
    (* \:30b3\:30df\:30c3\:30c8\:306e\:89aa\:3092\:53d6\:5f97 *)
    commitResp = iAPICall["GET",
      "repos/" <> owner <> "/" <> repo <> "/commits/" <> commitSHA, token];
    If[FailureQ[commitResp], Return[commitResp]];
    commitBody = commitResp["Body"];
    parentSHAs = Lookup[#, "sha", ""] & /@ Lookup[commitBody, "parents", {}];
    If[Length[parentSHAs] === 0,
      Return[iFailure["NoParent", "\:521d\:56de\:30b3\:30df\:30c3\:30c8\:306f\:30ea\:30d0\:30fc\:30c8\:3067\:304d\:307e\:305b\:3093\:3002"]]];
    parentSHA = First[parentSHAs];
    (* \:89aa\:30b3\:30df\:30c3\:30c8\:306e tree SHA \:3092\:53d6\:5f97 *)
    parentObj = iGetCommitObject[token, owner, repo, parentSHA];
    If[FailureQ[parentObj], Return[parentObj]];
    parentTreeSHA = Lookup[Lookup[parentObj["Body"], "tree", <||>], "sha", ""];
    If[parentTreeSHA === "",
      Return[iFailure["MissingParentTree", "\:89aa\:30b3\:30df\:30c3\:30c8\:306e tree \:3092\:53d6\:5f97\:3067\:304d\:307e\:305b\:3093\:3067\:3057\:305f\:3002"]]];
    (* \:73fe\:5728\:306e HEAD SHA \:3092\:53d6\:5f97 *)
    headRef = iGetRef[token, owner, repo, branch];
    If[FailureQ[headRef], Return[headRef]];
    headSHA = Lookup[Lookup[headRef["Body"], "object", <||>], "sha", ""];
    (* \:30ea\:30d0\:30fc\:30c8\:30b3\:30df\:30c3\:30c8\:3092\:4f5c\:6210: \:89aa\:306e tree \:3092\:4f7f\:3044\:3001\:73fe\:5728 HEAD \:3092\:89aa\:3068\:3059\:308b *)
    newCommitMsg = "Revert " <> StringTake[commitSHA, UpTo[7]];
    If[reason =!= "", newCommitMsg = newCommitMsg <> ": " <> reason];
    newCommit = iCreateCommit[token, owner, repo,
      newCommitMsg, parentTreeSHA, headSHA, Automatic, Automatic];
    If[FailureQ[newCommit], Return[newCommit]];
    (* \:30d6\:30e9\:30f3\:30c1\:3092\:66f4\:65b0 *)
    updateResp = iUpdateRef[token, owner, repo, branch,
      Lookup[newCommit["Body"], "sha", ""]];
    If[FailureQ[updateResp], Return[updateResp]];
    <|"Action" -> "Revert", "Package" -> packageName,
      "RevertedCommit" -> StringTake[commitSHA, UpTo[7]],
      "ParentCommit" -> StringTake[parentSHA, UpTo[7]],
      "NewCommit" -> StringTake[Lookup[newCommit["Body"], "sha", ""], UpTo[7]],
      "Branch" -> branch,
      "Reason" -> reason|>
  ];

(* ============================================================
   ロード時メッセージ
   ============================================================ *)

Print[Style["GitHubREST パッケージ \[LongDash] GitHub REST API ユーティリティ", Bold]];
Print[
  "  GitHubPackageURL[package]                \[RightArrow] パッケージの GitHub URL\n" <>
  "  GitHubPackageURLs[]                      \[RightArrow] 全パッケージの GitHub URL 一覧\n" <>
  "  GitHubInstallPackage[package]            \[RightArrow] GitHub から $packageDirectory へ初回ダウンロード\n" <>
  "  GitHubInstallPackage[package, url]       \[RightArrow] 他人のリポジトリからインストール\n" <>
  "  GitHubUpdatePackage[package]             \[RightArrow] パッケージを GitHub 最新に更新\n" <>
  "  GitHubPullRequestDataset[package]        \[RightArrow] PR 一覧 (Review/Merge/Close ボタン付き)\n" <>
  "  GitHubCommitDataset[package]             \[RightArrow] コミット履歴 (Review/Pull/Revert ボタン付き)\n" <>
  "  GitHubReviewCommit[package, sha]         \[RightArrow] コミット詳細・差分を表示\n" <>
  "  GitHubRevertCommit[package, sha, reason] \[RightArrow] コミットをリバート\n" <>
  "  GitHubRepoDBSet[package, repoName]       \[RightArrow] 日本語パッケージ名 → 英語リポジトリ名を登録\n" <>
  "  GitHubRepoPath[package]                  \[RightArrow] ローカル GitHub 作業フォルダのパス (GithubRepositories/)\n" <>
  "  GitHubEnsureLocalRepo[package]           \[RightArrow] ローカル GitHub 作業フォルダを作成\n" <>
  "  GitHubReadManifest[package]              \[RightArrow] upload_manifest.json を読取\n" <>
  "  GitHubRefreshLocalPackageGroup[package]  \[RightArrow] manifest に基づきファイル群を local repo へコピー\n" <>
  "  GitHubRefreshLocalPackage[package]       \[RightArrow] 単一 .wl ファイルを local repo へコピー (後方互換)\n" <>
  "  GitHubCreateRepository[package]          \[RightArrow] GitHub に新規リポジトリを作成 + manifest コミット\n" <>
  "  GitHubReadFile[package, path]            \[RightArrow] GitHub 上のファイル読取\n" <>
  "  GitHubPull[package]                      \[RightArrow] GitHub から local repo へ取得\n" <>
  "  GitHubCommit[package, message]           \[RightArrow] local repo の内容を GitHub へコミット\n" <>
  "  GitHubCreatePullRequest[package, title]  \[RightArrow] pull request を作成\n" <>
  "  GitHubRefreshAndCommit[package, message] \[RightArrow] グループ refresh + commit を一発で実行\n" <>
  "  GitHubSubmitPullRequest[package, title, message] \[RightArrow] グループ refresh + branch + commit + PR\n" <>
  "\n--- 認証 ---\n" <>
  "  NBAccess`NBGetAPIKey[\"github\"]        \[RightArrow] GitHub アクセストークン取得\n" <>
  "\n--- 既定ローカル構成 ---\n" <>
  "  GitHubRepoPath[\"fact\"]               \[RightArrow] FileNameJoin[{$packageDirectory, \"GithubRepositories\", \"fact\"}]\n" <>
  "  upload_manifest.json                   \[RightArrow] $packageDirectory/fact_info/upload_manifest.json\n" <>
  "  _info/docs/README.md                   \[RightArrow] GitHub リポジトリトップの README.md に自動同期\n" <>
  "\n--- インストール (初回) ---\n" <>
  "  1. claudecode.wl, NBAccess.wl, github.wl を $packageDirectory に手動配置\n" <>
  "  2. Block[{$CharacterEncoding = \"UTF-8\"}, Needs[\"GitHubREST`\", \"github.wl\"]]\n" <>
  "  3. GitHubInstallPackage[\"other-package\"] で自分のパッケージをダウンロード\n" <>
  "  4. GitHubInstallPackage[\"pkg\", \"https://github.com/user/repo\"] で他人のリポジトリをインストール\n" <>
  "\n--- 他人のリポジトリを使う流れ ---\n" <>
  "  GitHubInstallPackage[\"pkg\", \"https://github.com/alice/repo\"]\n" <>
  "  GitHubUpdatePackage[\"pkg\"]                              \[RightArrow] 最新を pull\n" <>
  "  GitHubCommitDataset[\"pkg\"]                              \[RightArrow] コミット履歴を確認\n" <>
  "  GitHubSubmitPullRequest[\"pkg\", \"Fix\", \"Bug fix\"]        \[RightArrow] PR 送信\n" <>
  "\n--- よく使う流れ ---\n" <>
  "  GitHubCreateRepository[\"fact\", Public -> False]\n" <>
  "  GitHubRefreshAndCommit[\"fact\", \"Update fact\"]\n" <>
  "  GitHubSubmitPullRequest[\"fact\", \"Update\", \"Update fact\"]\n" <>
  "  GitHubPull[\"fact\"]\n" <>
  "\n--- 主なオプション ---\n" <>
  "  Owner, Repository, Public, Description, Homepage,\n" <>
  "  AutoInit, GitignoreTemplate, LicenseTemplate,\n" <>
  "  Branch, BaseBranch, CreateBranch,\n" <>
  "  Body, Draft, MaintainerCanModify,\n" <>
  "  IncludePackageFile, LocalRepoPath, PackageFile, ReturnType,\n" <>
  "  Author, Committer, Force, DeleteMissing\n"
];

End[];
EndPackage[];
