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

GitHubValidateManifest::usage =
  "GitHubValidateManifest[packageName] は upload_manifest.json を検査し\n" <>
  "<|Status, FileCount, MissingFiles, ExcludePatterns, Issues, ...|> を返す。\n" <>
  "files[] の実在、secret/token/runtime らしきファイルの混入、除外パターンを確認する。\n" <>
  "(SourceVault では GitHubValidateManifest[\"SourceVault\"] で呼ぶ)";

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

GitHubReadLocalFile::usage =
  "GitHubReadLocalFile[packageName, path] はローカルファイルを UTF-8 で読み取る。\n" <>
  "GitHubReadFile との比較用。ReadString は $CharacterEncoding に依存するが、\n" <>
  "この関数は常に UTF-8 でデコードするため日本語環境でも文字化けしない。\n" <>
  "path が省略された場合はパッケージの .wl ファイルを読む。";

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
  "\:30aa\:30d7\:30b7\:30e7\:30f3 Owner, Repository, Branch \:6307\:5b9a\:53ef\:80fd\:3002\n" <>
  "既にローカルにソースが存在する場合は上書きせず失敗する (更新は GitHubUpdatePackage、強制上書きは \"Overwrite\" -> True)。";
GitHubUpdatePackage::usage =
  "GitHubUpdatePackage[packageName] \:306f\:65e2\:5b58\:30d1\:30c3\:30b1\:30fc\:30b8\:3092 GitHub \:306e\:6700\:65b0\:306b\:66f4\:65b0\:3059\:308b\:3002\n" <>
  "ローカルの未コミット変更は GitHub の内容で上書きされるので注意。";

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
GitHubCommitLog::usage =
  "GitHubCommitLog[packageName] はリポジトリのコミット履歴を日付範囲付きで取得し\n" <>
  "{<|\"SHA\", \"Date\", \"Author\", \"Message\"|>..} のコンパクト形式で返す。\n" <>
  "リポジトリを一切変更しない読み取り専用操作のため、承認なしで実行できる\n" <>
  "(NBAccess`$NBTrustedPackageHeads 登録済み)。GithubRepositories/ は .git を\n" <>
  "持たないミラーなので、履歴は GitHub API から取得する。\n" <>
  "オプション: MaxItems -> 50, \"Since\" -> None, \"Until\" -> None, Branch -> Automatic。\n" <>
  "例: GitHubCommitLog[\"SourceVault\", \"Since\" -> \"2026-06-20\"]";
GitHubReviewCommit::usage =
  "GitHubReviewCommit[packageName, sha] \:306f\:6307\:5b9a\:30b3\:30df\:30c3\:30c8\:306e\:8a73\:7d30\:30fb\:5dee\:5206\:3092\:30ce\:30fc\:30c8\:30d6\:30c3\:30af\:306b\:8868\:793a\:3059\:308b\:3002";
GitHubRevertCommit::usage =
  "GitHubRevertCommit[packageName, sha] \:306f\:6307\:5b9a\:30b3\:30df\:30c3\:30c8\:306e\:5909\:66f4\:3092\:5143\:306b\:623b\:3059\:30ea\:30d0\:30fc\:30c8\:30b3\:30df\:30c3\:30c8\:3092\:4f5c\:6210\:3059\:308b\:3002";
MaxItems::usage =
  "MaxItems \:306f GitHubListCommits/GitHubCommitDataset \:3067\:53d6\:5f97\:3059\:308b\:30b3\:30df\:30c3\:30c8\:6570\:306e\:4e0a\:9650\:3002\:65e2\:5b9a\:5024\:306f 30\:3002";

GitHubListIssues::usage =
  "GitHubListIssues[packageName] はリポジトリの Issue を取得し正規化リスト\n" <>
  "{<|\"Package\", \"Owner\", \"Repository\", \"Number\", \"Title\", \"Body\", \"State\",\n" <>
  "  \"Labels\", \"Author\", \"AuthorAssociation\", \"CreatedAt\", \"UpdatedAt\",\n" <>
  "  \"CommentCount\", \"URL\", \"IsPullRequest\"|>..} で返す。\n" <>
  "リポジトリを一切変更しない読み取り専用操作 (NBAccess trusted head 登録済み)。\n" <>
  "オプション: Owner, Repository, MaxItems -> 50, \"State\" -> \"open\",\n" <>
  "\"IncludePullRequests\" -> False (GitHub API は PR も issue として返すため既定で除外)。\n" <>
  "例: GitHubListIssues[\"claudecode\"]";
GitHubIssueGet::usage =
  "GitHubIssueGet[packageName, number] は指定番号の Issue 1 件を正規化 Association で返す。\n" <>
  "読み取り専用。オプション: Owner, Repository。";
GitHubIssueComments::usage =
  "GitHubIssueComments[packageName, number] は Issue のコメント一覧を\n" <>
  "{<|\"Author\", \"AuthorAssociation\", \"Body\", \"CreatedAt\", \"URL\"|>..} で返す。\n" <>
  "読み取り専用。オプション: Owner, Repository, MaxItems -> 50。";
GitHubIssueAuthorProfile::usage =
  "GitHubIssueAuthorProfile[login] は GitHub ユーザーの公開プロファイルを\n" <>
  "<|\"Login\", \"Name\", \"CreatedAt\", \"Followers\", \"Following\", \"PublicRepos\",\n" <>
  "  \"Bio\", \"Company\", \"HTMLURL\"|> で返す。Issue 作成者の信頼度推定の材料\n" <>
  "(アカウント年齢・フォロワー数など) に使う。読み取り専用。";
GitHubManagedRepositories::usage =
  "GitHubManagedRepositories[] は github.wl 管理下のリポジトリ一覧\n" <>
  "{<|\"Package\", \"Repository\", \"Owner\"|>..} を返す。\n" <>
  "GithubRepositories/ ミラーフォルダと repo_database.json の和集合。\n" <>
  "Owner は repo_database.json の owner 登録があればその値、無ければ Automatic\n" <>
  "(認証ユーザー)。ローカル情報のみでネットワークに触れない読み取り専用操作。";
GitHubAllOpenIssues::usage =
  "GitHubAllOpenIssues[] は管理下全リポジトリの Open Issue を集約して\n" <>
  "<|\"Issues\" -> {正規化 issue..}, \"RepoCount\", \"Errors\" -> {<|\"Package\", \"Failure\"|>..}|>\n" <>
  "を返す。リポジトリ単位で fail-soft (未作成リポジトリ等はスキップし Errors に記録)。\n" <>
  "読み取り専用。オプション: MaxItems -> 50 (リポジトリ毎), \"IncludePullRequests\" -> False。\n" <>
  "SourceVault の汎用イシューDB取込 (SourceVaultIssueIngestGitHub) の供給元。";
GitHubIssueAddComment::usage =
  "GitHubIssueAddComment[packageName, number, body] は Issue へコメントを投稿し\n" <>
  "<|\"URL\", \"Id\", \"CreatedAt\"|> を返す。公開リポジトリへの書き込み操作なので\n" <>
  "trusted head には登録しない (承認ゲート対象)。呼び出し側で内容の秘匿情報\n" <>
  "(ローカルパス等) を除去してから渡すこと。オプション: Owner, Repository。\n" <>
  "SourceVaultIssueNotifyGitHub (解決通知) の送信層。";

GitHubServiceStatus::usage =
  "GitHubServiceStatus[] は GitHub 稼働状況 (githubstatus.com) を取得し\n" <>
  "<|\"Healthy\", \"Indicator\", \"Description\", \"CommitAffected\", \"Components\",\n" <>
  "  \"Degraded\", \"Incidents\", \"CheckedAt\"|> を返す。\n" <>
  "コミットが 500/502/503/504 で失敗したとき、コード側の不具合か GitHub 側の\n" <>
  "障害かを切り分けるために使う。\n" <>
  "\"CommitAffected\" は PackageCommit / GitHubCommit が依存するコンポーネント\n" <>
  "(API Requests, Git Operations) のいずれかが operational でないとき True。\n" <>
  "公開ステータスページの読み取りのみで認証不要。GitHub API トークンは送らない。\n" <>
  "リポジトリを一切変更しない読み取り専用操作。\n" <>
  "GitHubServiceStatus[key] で単一キーを取得。\n" <>
  "オプション: \"Timeout\" -> 20。\n" <>
  "例: GitHubServiceStatus[\"CommitAffected\"]";

$GitHubLicenseHolder::usage =
  "$GitHubLicenseHolder \:306f MIT \:30e9\:30a4\:30bb\:30f3\:30b9\:306e\:8457\:4f5c\:6a29\:8005\:540d\:3002\n" <>
  "\:7a7a\:6587\:5b57\:5217 \"\" \:306e\:5834\:5408\:3001\:30e9\:30a4\:30bb\:30f3\:30b9\:30bb\:30af\:30b7\:30e7\:30f3\:306f README.md \:306b\:633f\:5165\:3055\:308c\:306a\:3044\:3002\n" <>
  "\:4f8b: $GitHubLicenseHolder = \"Katsunobu Imai\"";


(* ============================================================
   Package auto-commit ヘルパー (旧 PackageAutoCommit.wl を統合)
   GitHubRefreshAndCommit の前段: docs 鮮度ゲート / 前回コミット差分 /
   コミットメッセージ案 (決定論 or LLM) / DryRun 既定の駆動。
   ============================================================ *)

PackageDocsFreshnessGate::usage =
  "PackageDocsFreshnessGate[packageName] は packageName_info/docs 配下の api.md / api_*.md が\n" <>
  "対応する .wl ファイル以降に更新されているか (鮮度) を検査する。\n" <>
  "api ドキュメントが対応 .wl より古い (= .wl 更新後にドキュメントが未更新) ものが\n" <>
  "1 つでもあれば Proceed -> False とし、StaleDocs に <|Doc, Wl, DocDate, WlDate|> を列挙する。\n" <>
  "対応規則: api.md <-> <pkg>.wl, api_<suffix>.md <-> <pkg>_<suffix>.wl。\n" <>
  "対応 .wl が存在しない api ドキュメントは検査対象外。docs フォルダが無ければ Proceed -> True。\n" <>
  "戻り値: <|Status, Package, Proceed, Checked, StaleDocs, DocsDir|>。";

PackageCommitDiff::usage =
  "PackageCommitDiff[packageName] は packageName の現ソースと前回コミットスナップショット\n" <>
  "(GithubRepositories/<pkg>) との差分を ReadOnly に計算する。\n" <>
  "upload_manifest.json を直接 Import し (GitHubReadManifest は自動編集するため呼ばない)、\n" <>
  "GitHubRefreshAndCommit の前方マッピング (files=basename, directories=相対パス+exclude) を\n" <>
  "再現して src<->snapshot を内容比較する。リフレッシュ前に呼ぶこと (リフレッシュ後はスナップショットが\n" <>
  "上書きされ差分が消える)。\n" <>
  "戻り値: <|Status, Package, SnapshotDir, SnapshotExists, Added, Changed, Removed,\n" <>
  "          UnchangedCount, ChangeCount, ChangedDetail, Summary|>。";

PackageCommitPlan::usage =
  "PackageCommitPlan[packageName, opts] は鮮度ゲート -> 差分 -> コミットメッセージ案 を ReadOnly に組み立てる。\n" <>
  "ゲートが Proceed -> False (docs 古い) なら Status -> Blocked、差分が無ければ Status -> NoChange。\n" <>
  "両方 OK なら Status -> OK で CommitMessage を返す (実コミットはしない)。\n" <>
  "opts: \"MessageGenerator\" -> Automatic (差分からの決定論的単文) | \"固定文字列\" | fn (diff Association を受け取り文字列を返す)、\n" <>
  "      \"SkipDocsGate\" -> False (True で docs 鮮度ゲートを無視して進む; OK 結果に StaleDocs 警告 + DocsGateSkipped)、\n" <>
  "      \"AllowAckRemoval\" -> False (README の「## 謝辞」節が前回コミットから消えるコミットは Blocked。True で明示解除)。\n" <>
  "戻り値: <|Status, Package, Proceed, (StaleDocs | AckLossFiles | Diff | CommitMessage), ...|>。";

PackageCommit::usage =
  "PackageCommit[packageName, opts] は PackageCommitPlan を実行し、Status -> OK のとき\n" <>
  "GitHubRefreshAndCommit[packageName, CommitMessage] を呼ぶ。Blocked (docs 古い) / NoChange / Failed の\n" <>
  "ときはコミットせず計画結果を返す。パッケージのメイン駆動関数。\n" <>
  "opts: \"DryRun\" -> True (既定。実コミットせず計画とメッセージ案を返す), \"MessageGenerator\" -> Automatic,\n" <>
  "      \"SkipDocsGate\" -> False (True は DryRun プレビュー専用でゲートを無視。実コミット (DryRun -> False) では\n" <>
  "      SkipDocsGate に関わらず docs 古ければ Blocked で停止し StaleDocs を返す)、\n" <>
  "      \"AllowAckRemoval\" -> False (README の「## 謝辞」節が消えるコミットは Blocked。意図的削除時のみ True)。\n" <>
  "戻り値: <|Status (DryRun|Committed|Blocked|NoChange|Failed), Committed, CommitMessage, ...|>。";

PackageLLMMessageGenerator::usage =
  "PackageLLMMessageGenerator[queryFn, opts] は LLM でコミットメッセージを生成する\n" <>
  "MessageGenerator 関数 (diff Association -> 文字列) を返す。PackageCommit / PackageCommitPlan の\n" <>
  "\"MessageGenerator\" オプションに渡す。\n" <>
  "queryFn は prompt -> 文字列 の関数。モデル指定子 (tuple {provider,model} 例 $iModelSonnet、または\n" <>
  "モデル名 String) を渡すと ClaudeCode`ClaudeQueryBg[prompt, Model->spec] で自動ラップする (要 claudecode)。\n" <>
  "既定 (\"IncludeContent\"->True) では、変更ファイルの実際の変更行 (- 削除 / + 追加, PackageCommitDiff の\n" <>
  "ChangedDetail から計算) をプロンプトに含め、何が変わったかを要約させる。ソース変更行を model に送るので\n" <>
  "信頼できる model を使うこと。\"IncludeContent\"->False でファイル名のみ (低 privacy) に戻せる。\n" <>
  "queryFn[prompt] が文字列を返さない / 空なら決定論メッセージにフォールバック。\n" <>
  "opts: \"MaxChars\"->80, \"IncludeContent\"->True, \"MaxContentChars\"->4000, \"MaxPerFileChars\"->1500。\n" <>
  "例: PackageCommit[\"github\",\"DryRun\"->False,\"MessageGenerator\"->PackageLLMMessageGenerator[$iModelSonnet]]。";

$PackageCommitModel::usage =
  "$PackageCommitModel は PackageCommit / PackageCommitPlan の既定コミットメッセージモデル。\n" <>
  "既定 Automatic: claudecode がロード済みなら周囲の既定モデルで差分内容を要約した LLM メッセージを生成し、\n" <>
  "  未ロード/失敗時は決定論的なファイル名列挙にフォールバックする。\n" <>
  "特定モデルを使うにはモデル指定子 (tuple {provider,model} 例 $iModelSonnet、またはモデル名 String) か\n" <>
  "  prompt->文字列 関数を代入する。None を代入すると LLM を呼ばず決定論メッセージに固定する。\n" <>
  "再ロードで値を保持する。\n" <>
  "例: $PackageCommitModel = $iModelSonnet; PackageCommit[\"claudecode\", \"DryRun\" -> True][\"CommitMessage\"]";

PackageCommitDeletionPreview::usage =
  "PackageCommitDeletionPreview[packageName] は DeleteMissing -> True で削除される\n" <>
  "リモートファイル (リモート tree にあってローカルミラーに無い blob) を実行せずに列挙する。\n" <>
  "読み取り専用。PackageCommit[..., \"DeleteMissing\" -> True] の前に必ず実行して確認すること。\n" <>
  "返り値: <|\"WouldDelete\" -> {path..}, \"RemoteCount\", \"LocalCount\"|>。";


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
  iNormalizeGitPath, iGetRef, iCreateRef, iUpdateRef, iCommitAndUpdateRef, iGetCommitObject,
  iCreateBlob, iGitBlobSHA, iCreateTree, iCreateCommit, iGetTreeRecursive,
  iReadLocalByteArray, iWriteLocalByteArray, iRelativeGitPath, iListLocalFiles,
  iNormalizePerson, iDecodeGitHubContent, iBranchIfMissing, iGetRepoInfo,
  iWaitForRepoInfo, iWaitForRef, iResolveBaseBranch, iRepoAccessFailure,
  iBranchReadFailure, iRepositoryURL, iSlugifyBranchName, iAutoPRBranchName,
  iForceASCIIJSON, iEncodeJSONBody,
  iManifestPath, iDefaultManifest, iReadManifest, iWriteManifest,
  iEnsureManifest, iDetectPackageType, iDiscoverAuxWLFiles,
  iCopyDirectoryFiltered, iAddExtraDirectories,
  iRefreshPackageGroup, iSyncReadme, iMatchExcludePattern, iInfoDirName,
  iLocalSnapshotDir, iSaveLocalSnapshot, iRestoreLocalSnapshot,
  iCopyLocalRepoToPackageDir, iCleanManifestFilesInPkgDir,
  iDetectNewerThanSnapshot, iSnapshotHashPath,
  iDefaultExcludePatterns, iMergedExcludePatterns,
  iCopyDirectoryPreservingExcluded, iCleanStaleLocalFiles,
  iTranslateToEnglishRepoName, iSlugifyRepoName, iCheckRepoExists,
  iParseGitHubURL, iRepoDBOwnerLookup,
  iIsRemotePackage, iOriginalsDir, iSaveOriginals, iLoadOriginals,
  iRestoreOriginalsToRepo,
  iRetriableStatusQ, iRetriableCallQ, iRetryDelay,
  iStatusDate, iLatestIncidentUpdate,
  iMirrorBackupPath, iBackupMirror, iRestoreMirror, iDiscardMirrorBackup,
  iWithMirrorRollback, iPruneMirrorBackupRoot, $iMirrorDiscardSuffix,
  iMarkdownRealFrontMatterQ, iMarkdownHeadHazardQ, iNormalizeMarkdownFileHead,
  iMarkdownUnclosedFenceQ, iSanitizeMirrorMarkdown
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
    (* 純 ASCII なら iForceASCIIJSON をスキップ (base64 blob 等の大容量で致命的遅延を回避) *)
    StringToByteArray[If[hasNonASCII, iForceASCIIJSON[jsonStr], jsonStr], "UTF-8"]
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

(* 5xx はサーバ側の一時障害 (GitHub 全体障害・単発の 503 等)。本文が処理されて
   いないことが確定的なので、再送で回復しうる。 *)
iRetriableStatusQ[status_] := IntegerQ[status] && MemberQ[{500, 502, 503, 504}, status];

(* POST は一般に非冪等 (PR/Issue/リポジトリ作成が二重に走る) なので再試行しない。
   例外は /git/ 系 = blob/tree/commit で、内容アドレス指定のため同じ本文を再送しても
   同じ SHA が返るだけで重複が生じない。 *)
iRetriableCallQ[method_String, path_String] :=
  Module[{m = ToUpperCase[method]},
    MemberQ[{"GET", "HEAD", "PUT", "PATCH", "DELETE"}, m] ||
      (m === "POST" && StringContainsQ[path, "/git/"])
  ];

(* Retry-After があれば従う (上限 60 秒)。無ければ指数バックオフ。 *)
iRetryDelay[resp_, k_Integer] :=
  Module[{ra},
    ra = Quiet @ Check[Lookup[Association[resp["Headers"]], "retry-after", None], None];
    If[StringQ[ra] && StringMatchQ[ra, DigitCharacter ..],
      Min[ToExpression[ra], 60],
      2^k
    ]
  ];

iAPICall[method_String, path_String, token_String, body_: None, query_: <||>] :=
  Module[{url, headers, reqAssoc, req, resp, status, rawBody, parsedBody, respHeaders,
          maxRetries = 3, k, retriable},
    url = iBuildURL[path, query];
    retriable = iRetriableCallQ[method, path];
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
    (* リトライ付き URLRead (タイムアウト 120秒、最大 3 回)。
       通信自体の失敗に加え、冪等な呼び出しに限り 5xx も再試行する。 *)
    resp = $Failed;
    Do[
      resp = Quiet @ Check[URLRead[req, TimeConstraint -> 120], $Failed];
      If[resp === $Failed || FailureQ[resp],
        If[k < maxRetries, Pause[2 * k]];
        Continue[]
      ];
      If[k < maxRetries && retriable &&
          iRetriableStatusQ[Quiet @ Check[resp["StatusCode"], None]],
        Pause[iRetryDelay[resp, k]];
        Continue[]
      ];
      Break[],
      {k, 1, maxRetries}
    ];
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

(* ============================================================
   GitHub 稼働状況 (2026-07-20)

   5xx でコミットが失敗したとき、コード側の不具合か GitHub 側の障害かを
   切り分けるための読み取り専用ユーティリティ。
   参照先は Statuspage の公開 API (認証不要) で api.github.com ではない。
   第三者ホストなので GitHub API トークンは絶対に送らない。
   ============================================================ *)

$GitHubStatusURL = "https://www.githubstatus.com/api/v2/summary.json";

(* PackageCommit / GitHubCommit が依存するコンポーネント *)
$GitHubCommitComponents = {"API Requests", "Git Operations"};

iStatusDate[s_] := If[StringQ[s], Quiet @ Check[DateObject[s, TimeZone -> 0], s], s];

(* incident_updates は新しい順。最新の本文だけ拾う。 *)
iLatestIncidentUpdate[inc_] :=
  Module[{ups},
    ups = Lookup[inc, "incident_updates", {}];
    If[ListQ[ups] && Length[ups] > 0,
      Lookup[First[ups], "body", Missing["NotAvailable"]],
      Missing["NotAvailable"]
    ]
  ];

Options[GitHubServiceStatus] = {"Timeout" -> 20};

GitHubServiceStatus[opts : OptionsPattern[]] :=
  Module[{resp, raw, data, comps, compAssoc, degraded, incidents, indicator},
    resp = Quiet @ Check[
      URLRead[
        HTTPRequest[$GitHubStatusURL,
          <|"Method" -> "GET", "Headers" -> {"User-Agent" -> $GitHubUserAgent}|>],
        TimeConstraint -> OptionValue["Timeout"]
      ],
      $Failed
    ];
    If[resp === $Failed || FailureQ[resp],
      Return[iFailure["GitHubStatusUnavailable",
        "GitHub 稼働状況ページに接続できませんでした。",
        <|"URL" -> $GitHubStatusURL|>]]
    ];
    If[! (IntegerQ[resp["StatusCode"]] && 200 <= resp["StatusCode"] < 300),
      Return[iFailure["GitHubStatusUnavailable",
        "GitHub 稼働状況ページがエラーを返しました。",
        <|"URL" -> $GitHubStatusURL, "StatusCode" -> resp["StatusCode"]|>]]
    ];
    raw = Quiet @ Check[resp["BodyByteArray"], None];
    (* 日本語を含みうるので ImportByteArray 経由 (二重エンコード回避) *)
    data = If[ByteArrayQ[raw],
      Quiet @ Check[ImportByteArray[raw, "RawJSON"], $Failed],
      $Failed];
    If[! AssociationQ[data],
      Return[iFailure["GitHubStatusParseFailed",
        "GitHub 稼働状況の JSON を解釈できませんでした。",
        <|"URL" -> $GitHubStatusURL|>]]
    ];
    comps = Lookup[data, "components", {}];
    (* グループ見出し (group -> True) は実体が無いので除外 *)
    comps = Select[comps,
      AssociationQ[#] && ! TrueQ[Lookup[#, "group", False]] &];
    compAssoc = Association[
      (Lookup[#, "name", "?"] -> Lookup[#, "status", "unknown"]) & /@ comps];
    degraded = Keys @ Select[compAssoc, # =!= "operational" &];
    indicator = Lookup[Lookup[data, "status", <||>], "indicator", "unknown"];
    incidents = Map[
      <|
        "Name" -> Lookup[#, "name", "?"],
        "Status" -> Lookup[#, "status", "?"],
        "Impact" -> Lookup[#, "impact", "?"],
        "Started" -> iStatusDate[Lookup[#, "created_at", Missing["NotAvailable"]]],
        "Updated" -> iStatusDate[Lookup[#, "updated_at", Missing["NotAvailable"]]],
        "LatestUpdate" -> iLatestIncidentUpdate[#],
        "URL" -> Lookup[#, "shortlink", Missing["NotAvailable"]]
      |> &,
      Select[Lookup[data, "incidents", {}], AssociationQ]
    ];
    <|
      "Healthy" -> (indicator === "none" && degraded === {}),
      "Indicator" -> indicator,
      "Description" -> Lookup[Lookup[data, "status", <||>], "description", "?"],
      (* コミット経路に効くコンポーネントだけを見た判定 *)
      "CommitAffected" -> AnyTrue[$GitHubCommitComponents,
        Lookup[compAssoc, #, "operational"] =!= "operational" &],
      "Components" -> compAssoc,
      "Degraded" -> degraded,
      "Incidents" -> incidents,
      "CheckedAt" -> Now,
      "URL" -> "https://www.githubstatus.com/"
    |>
  ];

GitHubServiceStatus[key_String, opts : OptionsPattern[]] :=
  Module[{res},
    res = GitHubServiceStatus[opts];
    If[FailureQ[res], res, Lookup[res, key, Missing["KeyAbsent", key]]]
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

(* 422 競合リトライ付きコミット + ref 更新。
   並列実行で head SHA がずれた場合、head を再取得して
   コミットを作り直す。最大 maxRetries 回リトライ。 *)
iCommitAndUpdateRef[
    token_String, owner_String, repo_String, branch_String,
    message_String, newTreeSHA_String, headSHA0_String,
    author_, committer_, force_, maxRetries_Integer: 3] :=
  Module[{headSHA = headSHA0, commitResp, newCommitSHA, updateResp, k, ref},
    Do[
      commitResp = iCreateCommit[token, owner, repo, message, newTreeSHA, headSHA, author, committer];
      If[FailureQ[commitResp], Return[commitResp, Module]];
      newCommitSHA = Lookup[commitResp["Body"], "sha", Missing["NotAvailable"]];
      If[!StringQ[newCommitSHA],
        Return[iFailure["MissingCommitSHA",
          "新しい commit SHA を取得できませんでした。", <||>], Module]
      ];
      updateResp = iUpdateRef[token, owner, repo, branch, newCommitSHA, force];
      If[!FailureQ[updateResp],
        Return[<|"CommitSHA" -> newCommitSHA, "UpdateRef" -> updateResp|>, Module]
      ];
      (* 422 以外のエラーはそのまま返す *)
      If[iStatusCode[updateResp] =!= 422,
        Return[updateResp, Module]
      ];
      (* 422: head が競合で変わった → 再取得してリトライ *)
      ref = iGetRef[token, owner, repo, branch];
      If[FailureQ[ref], Return[ref, Module]];
      headSHA = Lookup[Lookup[ref["Body"], "object", <||>], "sha", ""];
      If[!StringQ[headSHA] || headSHA === "",
        Return[iFailure["MissingHeadSHA",
          "リトライ中に head SHA を再取得できませんでした。",
          <|"Branch" -> branch, "Attempt" -> k|>], Module]
      ],
      {k, 1, maxRetries}
    ];
    (* maxRetries 回すべて 422 だった場合 *)
    iFailure["UpdateRefConflict",
      "ref 更新が " <> ToString[maxRetries] <> " 回連続で競合しました (422)。\n" <>
      "並列実行を避けるか、時間をおいて再試行してください。",
      <|"Branch" -> branch, "LastHeadSHA" -> headSHA|>]
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

(* ローカルで git blob SHA-1 を計算する (blob <size>\0<content> のハッシュ) *)
iGitBlobSHA[ba_ByteArray] :=
  Module[{headerBytes, combined},
    headerBytes = Join[
      Normal[StringToByteArray["blob " <> ToString[Length[ba]], "UTF-8"]],
      {0}];
    combined = ByteArray[Join[headerBytes, Normal[ba]]];
    Hash[combined, "SHA1", "HexString"]
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

(* $packageDirectory 内の補助 .wl ファイルを検出する。
   packageName_*.wl にマッチするファイル名のリストを返す。
   (packageName.wl 本体は除く) *)
iDiscoverAuxWLFiles[packageName_String] :=
  Module[{pkgDir, pattern, found},
    pkgDir = iPackageDirectory[];
    pattern = packageName <> "_*.wl";
    found = FileNames[pattern, {pkgDir}];
    (* CodePrivacyLevel > 0 の非公開拡張モジュール (例: SourceVault_course_
       private.wl) はアップロード候補にしない。ここで除外しないと
       iEnsureManifest の自動追加が manifest の files へ毎回書き戻し、
       手動で外しても次回コミットで再追加 → 関所ブロックの無限ループになる
       (2026-08-11)。明示的に files へ書かれた非公開ファイルは従来どおり
       iPrivateCodeViolations が遮断する。 *)
    found = Select[found, iCodePrivacyLevel[#] <= 0 &];
    FileNameTake /@ found
  ];

(* マニフェストが無い場合のデフォルト構成
   パッケージ (.wl) の場合: files に packageName.wl, directories に packageName_info
   パクレット (フォルダ) の場合: directories に packageName と packageName_info *)
iDefaultManifest[packageName_String] :=
  Module[{pkgDir, wlPath, packletDir, auxFiles},
    pkgDir = iPackageDirectory[];
    wlPath = FileNameJoin[{pkgDir, packageName <> ".wl"}];
    packletDir = FileNameJoin[{pkgDir, packageName}];
    auxFiles = iDiscoverAuxWLFiles[packageName];
    Which[
      FileExistsQ[wlPath],
        <|
          "packageName" -> packageName,
          "files" -> DeleteDuplicates[Join[{packageName <> ".wl"}, auxFiles]],
          "directories" -> {iInfoDirName[packageName]},
          "excludePatterns" -> {iInfoDirName[packageName] <> "/history/",
                                iInfoDirName[packageName] <> "/references/"}
        |>,
      DirectoryQ[packletDir],
        <|
          "packageName" -> packageName,
          "files" -> auxFiles,
          "directories" -> {packageName, iInfoDirName[packageName]},
          "excludePatterns" -> {iInfoDirName[packageName] <> "/history/",
                                iInfoDirName[packageName] <> "/references/"}
        |>,
      True,
        <|
          "packageName" -> packageName,
          "files" -> DeleteDuplicates[Join[{packageName <> ".wl"}, auxFiles]],
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
  Module[{path, manifest, currentType, manifestType, newManifest,
          auxFiles, currentFiles, addedFiles},
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

    (* 補助 .wl ファイルの自動検出・追加 *)
    auxFiles = iDiscoverAuxWLFiles[packageName];
    If[Length[auxFiles] > 0,
      currentFiles = Lookup[manifest, "files", {}];
      addedFiles = Complement[auxFiles, currentFiles];
      If[Length[addedFiles] > 0,
        manifest["files"] = DeleteDuplicates[Join[currentFiles, addedFiles]];
        iWriteManifest[packageName, manifest];
        Print["upload_manifest.json に補助ファイルを追加: " <>
          StringRiffle[addedFiles, ", "]]
      ]
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

(* マニフェストの有無に関わらず常に保護すべきデフォルト除外パターン。
   2026-07-08: <pkg>_info/docs/docs/ を追加。過去の同期事故でリポジトリに
   混入したネスト重複 (docs の中の docs/) が pull で毎回ローカル再生成され、
   doc 更新の対象膨張 → push で再コミット、という永久ループの遮断。
   このパターンは pull コピー・push スナップショット・stale 掃除の全経路に
   効くため、リポジトリ側に残骸があってもローカルへは二度と入らない。 *)
iDefaultExcludePatterns[packageName_String] := {
  iInfoDirName[packageName] <> "/history/",
  iInfoDirName[packageName] <> "/references/",
  iInfoDirName[packageName] <> "/docs/docs/"
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

(* ソース側で削除されたファイルをローカルレポの各マニフェストディレクトリから削除する。
   copiedDirFiles に含まれず exclude にも該当しないファイルが対象。 *)
iCleanStaleLocalFiles[localDir_String, manifestDirs_List, copiedDirFiles_List, excludePatterns_List] :=
  Module[{deletedFiles = {}, dirInLocal, allLocal, relPath},
    Do[
      dirInLocal = FileNameJoin[{localDir, dir}];
      If[DirectoryQ[dirInLocal],
        allLocal = Select[
          Join[FileNames["*", dirInLocal, Infinity],
               FileNames[".*", dirInLocal, Infinity]],
          FileExistsQ[#] && !DirectoryQ[#] &
        ];
        Do[
          relPath = iNormalizeGitPath[
            dir <> "/" <> FileNameJoin[FileNameDrop[file, FileNameDepth[dirInLocal]]]
          ];
          If[!MemberQ[copiedDirFiles, relPath] &&
             !iMatchExcludePattern[relPath, excludePatterns],
            Quiet @ DeleteFile[file];
            AppendTo[deletedFiles, relPath]
          ],
          {file, allLocal}
        ]
      ],
      {dir, manifestDirs}
    ];
    deletedFiles
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

(* ============================================================
   Markdown 先頭 --- (擬似 YAML front matter) のコミット直前ガード (2026-08-02)

   GitHub は .md の 1 行目が --- だと、そこから次の --- までを YAML front matter
   としてパースする。生成ドキュメントは front matter を使わないので、先頭に ---
   が 1 行残るだけで「1 行目 〜 次の水平線」が front matter 扱いになり、GitHub 上で
   "Error in user YAML: mapping values are not allowed in this context" となって
   本文全体が生テキスト表示になる (README/setup/examples 破損の実績あり)。

   生成側 (claudecode.wl iNormalizeDocHead) でも除去しているが、手編集・旧世代の
   ファイル・外部ワーカー経由の書き込みなど生成経路を通らない .md もあるため、
   「GitHub へ出る唯一の関所」であるミラー refresh でも決定的に正規化する。

   Claude Directives の rules/*.md や skills/*/SKILL.md は本物の front matter を
   持つので壊してはならない。--- の直後の最初の非空行が key: 形式で、かつ閉じ ---
   行が存在するものだけを「本物」として素通しする。
   ============================================================ *)

iMarkdownRealFrontMatterQ[content_String] :=
  StringMatchQ[content,
    RegularExpression[
      "(?sm)[ \t]*-{3,}[ \t]*\r?\n(?:[ \t]*\r?\n)*[ \t]*[A-Za-z_][-A-Za-z0-9_.]*[ \t]*:" <>
      "[^\r\n]*\r?\n.*?^-{3,}[ \t]*\r?$.*"]];
iMarkdownRealFrontMatterQ[_] := False;

(* 先頭が「単独 --- 行」で始まり、かつ本物の front matter ではない = 危険 *)
iMarkdownHeadHazardQ[content_String] :=
  Module[{s = StringReplace[content, RegularExpression["\\A\\s*"] -> "", 1]},
    StringStartsQ[s, RegularExpression["-{3,}[ \t]*\r?\n"]] &&
      !iMarkdownRealFrontMatterQ[s]
  ];
iMarkdownHeadHazardQ[_] := False;

(* 危険な先頭 --- を除去して書き戻す。変更したときだけ True *)
iNormalizeMarkdownFileHead[path_String] :=
  Module[{content, fixed},
    content = Quiet @ Check[Import[path, "Text", CharacterEncoding -> "UTF-8"], $Failed];
    If[!StringQ[content] || !iMarkdownHeadHazardQ[content], Return[False]];
    fixed = StringReplace[
      StringReplace[content, RegularExpression["\\A\\s*"] -> "", 1],
      RegularExpression["\\A-{3,}[ \t]*\r?\n\\s*"] -> "", 1];
    If[fixed === content || StringTrim[fixed] === "", Return[False]];
    TrueQ @ Quiet @ Check[
      Export[path, fixed, "Text", CharacterEncoding -> "UTF-8"]; True, False]
  ];
iNormalizeMarkdownFileHead[_] := False;

(* 末尾が開いたままのコードフェンス = 生成が途中で切れた兆候。
   除去では直せないので警告のみ。以降のレンダリングが全部コードブロックになる。
   claudecode.wl iDocFenceUnclosedQ と同じ CommonMark 準拠の開閉追跡:
   (a) 行頭 (インデント 3 まで) の ``` / ~~~ のみをフェンスとみなす
       → 文中の ``` (Markdown 自体を説明する doc に出る) を数えない
   (b) 閉じは開きと同種・同長以上・info string 無しに限る
       → ```` で囲んだ中の ``` を閉じと誤認しない *)
iMarkdownUnclosedFenceQ[content_String] :=
  Module[{openMark = None, s, mark, rest},
    Do[
      s = StringReplace[line, RegularExpression["^[ ]{0,3}"] -> "", 1];
      If[!StringStartsQ[s, "```" | "~~~"], Continue[]];
      mark = First @ StringCases[s, RegularExpression["^(`{3,}|~{3,})"]];
      rest = StringTrim @ StringDrop[s, StringLength[mark]];
      If[openMark === None,
        openMark = mark,
        If[StringTake[mark, 1] === StringTake[openMark, 1] &&
           StringLength[mark] >= StringLength[openMark] && rest === "",
          openMark = None]],
      {line, StringSplit[content, {"\r\n", "\n", "\r"}]}
    ];
    openMark =!= None
  ];
iMarkdownUnclosedFenceQ[_] := False;

(* ミラー配下の全 .md を検査・正規化し、修正した相対パスのリストを返す *)
iSanitizeMirrorMarkdown[localDir_String] :=
  Module[{files, fixed = {}, unclosed = {}, rel},
    If[!DirectoryQ[localDir], Return[{}]];
    files = Quiet @ Check[FileNames["*.md", localDir, Infinity], {}];
    Do[
      rel = StringReplace[StringDrop[f, StringLength[localDir] + 1], "\\" -> "/"];
      If[iNormalizeMarkdownFileHead[f], AppendTo[fixed, rel]];
      If[TrueQ @ Quiet @ Check[
          iMarkdownUnclosedFenceQ[Import[f, "Text", CharacterEncoding -> "UTF-8"]], False],
        AppendTo[unclosed, rel]],
      {f, files}
    ];
    If[Length[unclosed] > 0,
      Print[Style[
        "[GitHub] \:8b66\:544a: \:672a\:9589\:30b3\:30fc\:30c9\:30d5\:30a7\:30f3\:30b9 (``` \:304c\:5947\:6570) \:306e Markdown \:304c\:3042\:308a\:307e\:3059\:3002" <>
        "\:751f\:6210\:304c\:9014\:4e2d\:3067\:5207\:308c\:305f\:53ef\:80fd\:6027\:304c\:9ad8\:304f\:3001GitHub \:3067\:672b\:5c3e\:304c\:5168\:90e8\:30b3\:30fc\:30c9\:8868\:793a\:306b\:306a\:308a\:307e\:3059: " <>
        StringRiffle[unclosed, ", "], Orange]];
      Print[Style[
        "  \:203b ClaudeUpdateDocumentation \:3067\:5f53\:8a72\:30d5\:30a1\:30a4\:30eb\:3092\:518d\:751f\:6210\:3057\:3066\:304f\:3060\:3055\:3044\:3002", Gray]]
    ];
    If[Length[fixed] > 0,
      Print[Style[
        "[GitHub] Markdown \:5148\:982d\:306e\:64ec\:4f3c front matter (---) \:3092\:9664\:53bb\:3057\:307e\:3057\:305f: " <>
        StringRiffle[fixed, ", "], Orange]];
      Print[Style[
        "  \:203b \:751f\:6210\:5143 ($packageDirectory \:5074) \:306e\:540c\:540d\:30d5\:30a1\:30a4\:30eb\:306b\:3082\:540c\:3058\:6b8b\:7559\:304c\:3042\:308b\:5834\:5408\:306f\:3001" <>
        "\:6b21\:56de refresh \:3067\:518d\:5ea6\:4fee\:6b63\:3055\:308c\:307e\:3059\:3002", Gray]]
    ];
    fixed
  ];
iSanitizeMirrorMarkdown[_] := {};

(* マニフェストに基づくグループリフレッシュの内部実装 *)
(* ============================================================
   ミラーのロールバック (2026-07-20)

   iRefreshPackageGroup はソース → ミラー (GithubRepositories/<pkg>) を
   コミット前に進める。コミットが失敗するとミラーだけが HEAD より先に進み、
   「ミラー = 前回コミット状態」という不変条件が壊れる。
   PackageCommitPlan のコミットメッセージはこのミラーとの差分から生成される
   ため、次回実行時のメッセージが嘘になる (追加したファイルが「削除」になる等)。
   → コミット失敗時はミラーを refresh 前の状態へ戻す。
   ============================================================ *)

iMirrorBackupPath[packageName_String] :=
  FileNameJoin[{iPackageDirectory[], "GithubRepositories", "_mirror_rollback", packageName}];

iBackupMirror[packageName_String, localDir_String] :=
  Module[{dest},
    If[!DirectoryQ[localDir], Return[None]];
    dest = iMirrorBackupPath[packageName];
    Quiet @ Check[
      If[DirectoryQ[dest], DeleteDirectory[dest, DeleteContents -> True]];
      (* 前回の復旧が中断して退避ディレクトリが残っていれば掃除する *)
      If[DirectoryQ[localDir <> $iMirrorDiscardSuffix],
        DeleteDirectory[localDir <> $iMirrorDiscardSuffix, DeleteContents -> True]];
      iEnsureDirectory[DirectoryName[dest]];
      CopyDirectory[localDir, dest];
      dest,
      None
    ]
  ];

$iMirrorDiscardSuffix = ".rollback_discard";

(* 復旧はコピーではなく移動で行う。
   - バックアップが残らない (Windows/Dropbox では直後の DeleteDirectory が
     ハンドル競合で失敗しがちで、数 MB のコピーが残留する)
   - 大きなバイナリを二度コピーしない
   進んだミラーは一旦退避してから差し替え、途中で失敗した場合は退避分を
   戻すので、ミラーが消えたままにはならない。 *)
iRestoreMirror[localDir_String, backup_] :=
  Module[{dead, ok},
    If[!StringQ[backup] || !DirectoryQ[backup], Return[False]];
    dead = localDir <> $iMirrorDiscardSuffix;
    Quiet @ Check[
      If[DirectoryQ[dead], DeleteDirectory[dead, DeleteContents -> True]], Null];
    ok = TrueQ @ Quiet @ Check[
      If[DirectoryQ[localDir], RenameDirectory[localDir, dead]];
      (* RenameDirectory はボリューム跨ぎで失敗する (LocalRepoPath を別ドライブに
         指定した場合)。その時はコピーで復旧し、バックアップは明示的に消す。 *)
      If[FailureQ[Quiet @ Check[RenameDirectory[backup, localDir], $Failed]],
        CopyDirectory[backup, localDir];
        iDiscardMirrorBackup[backup]
      ];
      DirectoryQ[localDir],
      False
    ];
    If[!ok,
      (* 差し替え失敗: 退避した (進んだ) ミラーを元に戻して諦める *)
      Quiet @ Check[
        If[DirectoryQ[dead] && !DirectoryQ[localDir], RenameDirectory[dead, localDir]],
        Null];
      Return[False]
    ];
    Quiet @ Check[
      If[DirectoryQ[dead], DeleteDirectory[dead, DeleteContents -> True]], Null];
    True
  ];

iDiscardMirrorBackup[backup_] :=
  If[StringQ[backup] && DirectoryQ[backup],
    TrueQ @ Quiet @ Check[DeleteDirectory[backup, DeleteContents -> True]; True, False],
    False
  ];

(* 空になった _mirror_rollback 置き場を残さない *)
iPruneMirrorBackupRoot[] :=
  Module[{root},
    root = FileNameJoin[{iPackageDirectory[], "GithubRepositories", "_mirror_rollback"}];
    If[DirectoryQ[root] && FileNames["*", root] === {},
      TrueQ @ Quiet @ Check[DeleteDirectory[root]; True, False],
      False
    ]
  ];

(* refresh + commit を包み、失敗時にミラーを巻き戻す。
   body は refresh 結果とコミット結果を順に返す HoldForm 不要の関数として渡す。 *)
iWithMirrorRollback[packageName_String, localDir_String, body_] :=
  Module[{backup, result, restored},
    backup = iBackupMirror[packageName, localDir];
    result = body[];
    If[FailureQ[result],
      restored = iRestoreMirror[localDir, backup];
      iDiscardMirrorBackup[backup];
      iPruneMirrorBackupRoot[];
      Return[Replace[result,
        Failure[tag_, assoc_Association] :>
          Failure[tag, Append[assoc, "MirrorRestored" -> restored]]
      ]]
    ];
    iDiscardMirrorBackup[backup];
    iPruneMirrorBackupRoot[];
    result
  ];

(* ---- 非公開コード関所 ----
   ファイル先頭付近の機械可読マーカー  (* :CodePrivacyLevel: 0.1 *)  で
   「ソースコード自体が非公開」を宣言する (0 または無印 = 公開可)。
   manifest 経由で公開リポジトリへ流れ込むのを fail-closed で遮断する。
   検出は行頭の正準スタンプ形 ( (* ... *) / <!-- ... --> 完全形) に限る。
   裸の部分文字列マッチだと、マーカー記法を本文中で説明する生成 doc
   (github_info/docs/api.md) を誤検出して自己ブロックする (2026-08-11)。 *)
iCodePrivacyLevel[path_String] := Module[{st, bytes, head},
  If[! FileExistsQ[path], Return[0]];
  st = Quiet @ OpenRead[path, BinaryFormat -> True];
  If[st === $Failed || Head[st] =!= InputStream, Return[0]];
  bytes = WithCleanup[Quiet @ Check[ReadByteArray[st], $Failed],
    Quiet @ Close[st]];
  If[! ByteArrayQ[bytes] || Length[bytes] === 0, Return[0]];
  head = Quiet @ Check[ByteArrayToString[
    ByteArray[Take[Normal[bytes], UpTo[4096]]], "UTF-8"], $Failed];
  (* 4096 バイト目で多バイト文字が切れて UTF-8 デコードに失敗しても、
     マーカーは ASCII なので Latin-1 で読み直せば検出できる (fail-open 防止) *)
  If[! StringQ[head], head = Quiet @ Check[ByteArrayToString[
    ByteArray[Take[Normal[bytes], UpTo[4096]]], "ISO8859-1"], $Failed]];
  If[! StringQ[head], Return[0]];
  Replace[StringCases[head,
      StartOfLine ~~ (" " | "\t") ... ~~ ("(*" | "<!--") ~~ Whitespace ... ~~
        ":CodePrivacyLevel:" ~~ Whitespace ... ~~ lvl : NumberString ~~
        Whitespace ... ~~ ("*)" | "-->") :> ToExpression[lvl], 1],
    {{l_?NumericQ, ___} :> l, _ -> 0}]];

(* manifest 対象 (個別 files + directories 配下の .wl/.m) から
   CodePrivacyLevel > 0 のファイルを列挙する。
   directories 配下は excludePatterns 該当分を走査から外す: 除外ファイルは
   iCopyDirectoryFiltered でコピーされず公開リポジトリへ流れないため、
   manifest で明示的に除外した非公開 doc (例: SourceVault_info/docs/
   api_course_private.md) がパッケージ全体のコミットを永久ブロックしない
   (2026-08-11)。fail-closed は維持: アップロードされ得る対象は全て遮断。
   個別 files はコピー時に exclude 判定が無いので無条件で検査する。 *)
iPrivateCodeViolations[packageName_String] := Module[
  {manifest, pkgDir, files, dirs, excludePatterns, dirCands, cands},
  manifest = Quiet @ Check[iEnsureManifest[packageName], $Failed];
  If[! AssociationQ[manifest], Return[{}]];
  pkgDir = iPackageDirectory[];
  files = Map[FileNameJoin[{pkgDir, #}] &, Lookup[manifest, "files", {}]];
  dirs = Select[Lookup[manifest, "directories", {}],
    DirectoryQ[FileNameJoin[{pkgDir, #}]] &];
  excludePatterns = iMergedExcludePatterns[packageName];
  (* .md/.txt も対象: 非公開ソースから生成された doc は claudecode.wl の
     iSafeWriteDoc が同マーカーを継承させる (<!-- :CodePrivacyLevel: x -->) *)
  dirCands = Flatten @ Map[
    Function[dir, Module[{src = FileNameJoin[{pkgDir, dir}]},
      Select[FileNames[{"*.wl", "*.m", "*.wls", "*.md", "*.txt"}, src, Infinity],
        ! iMatchExcludePattern[iNormalizeGitPath[
            dir <> "/" <> FileNameJoin[FileNameDrop[#, FileNameDepth[src]]]],
          excludePatterns] &]]],
    dirs];
  cands = Join[files, dirCands];
  Select[DeleteDuplicates[cands], iCodePrivacyLevel[#] > 0 &]];

iRefreshPackageGroup[packageName_String, localDir_String] :=
  Module[{manifest, pkgDir, copiedFiles = {}, copiedDirs = {}, excludePatterns,
          deletedFiles = {}, deletedDirFiles = {},
          src, dst, readmeResult, restoredOriginals, mdHeadFixed, privateHits},
    (* 関所: 非公開コード (CodePrivacyLevel > 0) が manifest 対象に居たら
       何もコピーせず失敗させる (部分反映を作らない) *)
    privateHits = iPrivateCodeViolations[packageName];
    If[privateHits =!= {},
      Return[Failure["PrivateCodeBlocked", <|
        "MessageTemplate" ->
          "CodePrivacyLevel > 0 の非公開ファイルが manifest 対象に含まれています。upload_manifest.json から外してください。",
        "PackageName" -> packageName,
        "Files" -> Map[FileNameTake, privateHits]|>]]];
    manifest = iEnsureManifest[packageName];
    pkgDir = iPackageDirectory[];
    excludePatterns = iMergedExcludePatterns[packageName];
    (* 個別ファイルのコピー (ソースが消えていればローカルからも削除) *)
    Do[
      src = FileNameJoin[{pkgDir, file}];
      dst = FileNameJoin[{localDir, FileNameTake[src]}];
      If[FileExistsQ[src],
        Quiet @ CopyFile[src, dst, OverwriteTarget -> True];
        AppendTo[copiedFiles, file],
        If[FileExistsQ[dst],
          Quiet @ DeleteFile[dst];
          AppendTo[deletedFiles, file]
        ]
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
    (* その前にソース側で消えたファイルをローカルレポから削除 *)
    deletedDirFiles = iCleanStaleLocalFiles[localDir,
      Lookup[manifest, "directories", {}], copiedDirs, excludePatterns];
    restoredOriginals = iRestoreOriginalsToRepo[packageName, localDir];
    (* README.md の同期 *)
    readmeResult = iSyncReadme[packageName, localDir];
    (* コミット直前ガード: GitHub が YAML front matter と誤認する先頭 --- を除去。
       README 同期の後に走らせ、docs/README.md とトップ README.md の両方を掃除する *)
    mdHeadFixed = iSanitizeMirrorMarkdown[localDir];
    <|
      "Package" -> packageName,
      "LocalRepoPath" -> localDir,
      "Manifest" -> manifest,
      "CopiedFiles" -> copiedFiles,
      "CopiedDirectoryFiles" -> copiedDirs,
      "DeletedFiles" -> deletedFiles,
      "DeletedDirFiles" -> deletedDirFiles,
      "RestoredOriginals" -> restoredOriginals,
      "READMESynced" -> readmeResult,
      "MarkdownHeadFixed" -> mdHeadFixed
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
      ClaudeCode`Private`$currentUseFallback = True];
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

(* manifest 検査: files[] の実在 / secret 混入 / 除外パターンを確認する。
   配布前の「成果が抜けていないか」「秘密が混入していないか」チェックに使う。 *)
GitHubValidateManifest[packageName_String] := Module[
  {manifest, base, files, dirs, excl, missingFiles, presentFiles, secretHits, issues = {}},
  base = iPackageDirectory[];
  manifest = Quiet @ Check[iEnsureManifest[packageName], $Failed];
  If[! AssociationQ[manifest],
    Return[<|"Status" -> "Error", "Reason" -> "ManifestUnreadable", "PackageName" -> packageName|>]];
  files = Lookup[manifest, "files", {}];
  dirs  = Lookup[manifest, "directories", {}];
  excl  = iMergedExcludePatterns[packageName];
  missingFiles = Select[files, ! FileExistsQ[FileNameJoin[{base, #}]] &];
  presentFiles = Complement[files, missingFiles];
  If[missingFiles =!= {},
    AppendTo[issues, <|"Issue" -> "MissingFiles", "Files" -> missingFiles|>]];
  secretHits = Select[files,
    Function[f, AnyTrue[{"secret", "token", "credential", ".pid", ".heartbeat", ".log"},
      StringContainsQ[ToLowerCase[f], #] &]]];
  If[secretHits =!= {},
    AppendTo[issues, <|"Issue" -> "SuspectSecretFiles", "Files" -> secretHits|>]];
  (* 非公開コード関所: 先頭マーカー :CodePrivacyLevel: > 0 のファイルは
     公開リポジトリへコミットできない (refresh 側でも fail-closed で遮断) *)
  Module[{privHits = iPrivateCodeViolations[packageName]},
    If[privHits =!= {},
      AppendTo[issues, <|"Issue" -> "PrivateCodeFiles",
        "Files" -> Map[FileNameTake, privHits],
        "Hint" -> "CodePrivacyLevel > 0。upload_manifest.json から外すこと"|>]]];
  <|
    "Status" -> If[issues === {}, "OK", "Issues"],
    "PackageName" -> packageName,
    "FileCount" -> Length[files],
    "PresentFileCount" -> Length[presentFiles],
    "MissingFiles" -> missingFiles,
    "Directories" -> dirs,
    "ExcludePatterns" -> excl,
    "Issues" -> issues|>];

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
      ClaudeCode`Private`$currentUseFallback = True];
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
      ClaudeCode`Private`$currentUseFallback = True];
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
      _, Quiet @ Check[ByteArrayToString[ba, "UTF-8"], ba]
    ]
  ];

(* ローカルファイルを UTF-8 で読み取る。
   ReadString は $CharacterEncoding（日本語 Windows では ShiftJIS）に依存するため、
   UTF-8 ファイルの比較で文字化けする。この関数はバイト列を UTF-8 として正しくデコードする。 *)
GitHubReadLocalFile[packageName_String, path_String:""] :=
  Module[{filePath, bytes},
    filePath = If[path === "" || path === packageName <> ".wl",
      FileNameJoin[{Global`$packageDirectory, packageName <> ".wl"}],
      FileNameJoin[{Global`$packageDirectory, path}]];
    If[!FileExistsQ[filePath],
      Return[iFailure["FileNotFound", "\:30d5\:30a1\:30a4\:30eb\:304c\:898b\:3064\:304b\:308a\:307e\:305b\:3093\:3002", <|"File" -> filePath|>]]];
    bytes = Quiet @ Check[ReadByteArray[filePath], $Failed];
    If[!ByteArrayQ[bytes],
      Return[iFailure["ReadFailed", "\:30d5\:30a1\:30a4\:30eb\:306e\:8aad\:307f\:8fbc\:307f\:306b\:5931\:6557\:3057\:307e\:3057\:305f\:3002", <|"File" -> filePath|>]]];
    ByteArrayToString[bytes, "UTF-8"]
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
      ClaudeCode`Private`$currentUseFallback = True];
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
          treeResp, newTreeSHA, author, committer,
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
      ClaudeCode`Private`$currentUseFallback = True];
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
    (* リモートツリーを取得して path→SHA マップを構築 (変更なしファイルのスキップ + DeleteMissing に使用) *)
    remoteTree = iGetTreeRecursive[token, owner, repo, baseTreeSHA];
    Module[{remoteSHAMap = <||>, remoteEntries, skipped = 0, uploaded = 0},
      If[!FailureQ[remoteTree],
        remoteEntries = Lookup[remoteTree["Body"], "tree", {}];
        remoteSHAMap = Association[
          Cases[remoteEntries,
            a_Association /; Lookup[a, "type", None] === "blob" :>
              (Lookup[a, "path", ""] -> Lookup[a, "sha", ""])
          ]
        ]
      ];
      Print["[GitHubCommit] ローカル: " <> ToString[Length[localFiles]] <>
        " ファイル, リモート: " <> ToString[Length[remoteSHAMap]] <> " blob"];
      (* Catch/Throw で blob 作成エラーを確実に伝播 *)
      Module[{blobError, nFiles = Length[localFiles], file, localSHA, remoteSHA},
        blobError = Catch[
          Do[
            file = localFiles[[k]];
            relPath = iRelativeGitPath[localDir, file];
            ba = iReadLocalByteArray[file];
            If[FailureQ[ba], Throw[ba]];
            (* ローカルで git blob SHA を計算し、リモートと比較 *)
            localSHA = iGitBlobSHA[ba];
            remoteSHA = Lookup[remoteSHAMap, relPath, None];
            If[StringQ[remoteSHA] && localSHA === remoteSHA,
              (* 変更なし — blob 作成をスキップしリモート SHA を再利用 *)
              AppendTo[entries, <|"path" -> relPath, "mode" -> "100644",
                "type" -> "blob", "sha" -> remoteSHA|>];
              skipped++;,
              (* 変更あり or 新規 — blob を作成 *)
              Print["[Blob " <> ToString[uploaded + 1] <> "] " <> relPath <>
                If[remoteSHA === None, " (new)", " (changed)"]];
              blobResp = iCreateBlob[token, owner, repo, ba];
              If[FailureQ[blobResp], Throw[blobResp]];
              blobSHA = Lookup[blobResp["Body"], "sha", Missing["NotAvailable"]];
              If[!StringQ[blobSHA] || blobSHA === "",
                Throw[iFailure["MissingBlobSHA",
                  "blob SHA を取得できませんでした。", <|"File" -> file|>]]
              ];
              AppendTo[entries, <|"path" -> relPath, "mode" -> "100644",
                "type" -> "blob", "sha" -> blobSHA|>];
              uploaded++;
            ],
            {k, nFiles}
          ];
          None
        ];
        If[blobError =!= None, Return[blobError]]
      ];
      Print["[GitHubCommit] アップロード: " <> ToString[uploaded] <>
        ", スキップ (変更なし): " <> ToString[skipped]];
      (* DeleteMissing: リモートにあってローカルにないファイルを削除マーク *)
      If[TrueQ[OptionValue[DeleteMissing]],
        localPaths = Lookup[entries, "path"];
        remotePaths = Select[Keys[remoteSHAMap], StringQ];
        deletePaths = Complement[remotePaths, localPaths];
        entries = Join[entries,
          (<|"path" -> #, "mode" -> "100644", "type" -> "blob", "sha" -> Null|> & /@ deletePaths)
        ]
      ]
    ];
    (* entries が空なら blob 作成で問題が起きた可能性がある *)
    If[Length[entries] === 0,
      Return[iFailure["EmptyEntries",
        "コミット対象のエントリが空です。blob 作成が失敗した可能性があります。",
        <|"LocalFiles" -> Length[localFiles]|>]]
    ];
    treeResp = iCreateTree[token, owner, repo, baseTreeSHA, entries];
    If[FailureQ[treeResp], Return[treeResp]];
    newTreeSHA = Lookup[treeResp["Body"], "sha", Missing["NotAvailable"]];
    If[!StringQ[newTreeSHA] || newTreeSHA === "",
      Return[iFailure["MissingNewTreeSHA", "新しい tree SHA を取得できませんでした。",
        <|"TreeResponse" -> treeResp|>]]
    ];
    author = iNormalizePerson[OptionValue[Author]];
    committer = iNormalizePerson[OptionValue[Committer]];
    (* 422 競合リトライ付きコミット + ref 更新 *)
    Module[{cuResult},
      cuResult = iCommitAndUpdateRef[
        token, owner, repo, branch,
        message, newTreeSHA, headSHA,
        author, committer, TrueQ[OptionValue[Force]]
      ];
      If[FailureQ[cuResult], Return[cuResult]];
      <|
        "Package" -> packageName,
        "Owner" -> owner,
        "Repository" -> repo,
        "Branch" -> branch,
        "CommitMessage" -> message,
        "CommitSHA" -> cuResult["CommitSHA"],
        "TreeSHA" -> newTreeSHA,
        "UpdatedRef" -> cuResult["UpdateRef"]["Body"]
      |>
    ]
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
      ClaudeCode`Private`$currentUseFallback = True];
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
  Module[{localDir, refreshResult, commitResult, commitOpts},
    (* Fallback オプションを $currentUseFallback に反映 *)
    If[TrueQ[OptionValue[Fallback]],
      ClaudeCode`Private`$currentUseFallback = True];
    localDir = GitHubEnsureLocalRepo[packageName, LocalRepoPath -> OptionValue[LocalRepoPath]];
    (* ExtraDirectories が指定されていれば manifest に永続追加 *)
    iAddExtraDirectories[packageName, OptionValue[ExtraDirectories]];
    (* OptionValue は定義の RHS でのみ解決されるため、遅延評価される
       クロージャに入れる前にここで値を確定させる。 *)
    commitOpts = {
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
    };
    (* refresh はミラーを先に進めるので、コミット失敗時は巻き戻す *)
    commitResult = iWithMirrorRollback[packageName, localDir,
      Function[
        refreshResult = iRefreshPackageGroup[packageName, localDir];
        If[FailureQ[refreshResult],
          refreshResult,
          GitHubCommit[packageName, message, Sequence @@ commitOpts]
        ]
      ]
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
  Module[{branch, localDir, refreshResult, commitResult, prResult, commitOpts},
    branch = Replace[
      OptionValue[Branch],
      Automatic :> iAutoPRBranchName[packageName, title]
    ];
    localDir = GitHubEnsureLocalRepo[packageName, LocalRepoPath -> OptionValue[LocalRepoPath]];
    (* OptionValue は定義の RHS でのみ解決されるため、遅延評価される
       クロージャに入れる前にここで値を確定させる。 *)
    commitOpts = {
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
    };
    (* refresh はミラーを先に進めるので、コミット失敗時は巻き戻す *)
    commitResult = iWithMirrorRollback[packageName, localDir,
      Function[
        refreshResult = iRefreshPackageGroup[packageName, localDir];
        If[FailureQ[refreshResult],
          refreshResult,
          GitHubCommit[packageName, message, Sequence @@ commitOpts]
        ]
      ]
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
  Fallback -> False, "Overwrite" -> Automatic
};

GitHubInstallPackage[packageName_String, opts:OptionsPattern[]] :=
  Module[{token, owner, repo, baseBranch, branch, localDir,
          pullResult, pkgDir, manifest, files, dirs, src, dst, installed = {},
          isPaclet, isRemote, hasInfoDir},
    pkgDir = iPackageDirectory[];
    (* 上書きガード: ライブソースが既に存在する場合は初回インストールしない。
       未コミットのローカル変更が GitHub HEAD で消えるのを防ぐ。
       更新は GitHubUpdatePackage 経由 ("Overwrite" -> True が渡る)。 *)
    If[OptionValue["Overwrite"] =!= True &&
       FileExistsQ[FileNameJoin[{pkgDir, packageName <> ".wl"}]],
      Return[iFailure["PackageAlreadyInstalled",
        "パッケージ " <> packageName <> " のソースが既に " <> pkgDir <>
        " に存在するため、初回インストールを中止しました。GitHub の最新へ更新するには GitHubUpdatePackage[\"" <>
        packageName <> "\"] を、ローカルを強制上書きするには \"Overwrite\" -> True を使ってください" <>
        " (未コミットのローカル変更は上書きで失われます)。",
        <|"Package" -> packageName, "InstallTarget" -> pkgDir|>]]];
    token = iAccessToken[];
    If[FailureQ[token], Return[token]];
    owner = iResolveOwner[token, OptionValue[Owner], packageName];
    If[FailureQ[owner], Return[owner]];
    (* Fallback オプションを  に反映 *)
    If[TrueQ[OptionValue[Fallback]],
      ClaudeCode`Private`$currentUseFallback = True];
    repo = iResolveRepository[packageName, OptionValue[Repository]];
    If[FailureQ[repo], Return[repo]];
    (* 明示的に Repository が指定された場合も repo_database に登録 *)
    If[OptionValue[Repository] =!= Automatic && !iIsASCIIName[packageName],
      GitHubRepoDBSet[packageName, repo]];
    baseBranch = iResolveBaseBranch[token, owner, repo, OptionValue[BaseBranch]];
    If[FailureQ[baseBranch], Return[baseBranch]];
    branch = iResolveBranch[OptionValue[Branch], baseBranch];
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
  Module[{parsed, remoteOwner, remoteRepo, result},
    parsed = iParseGitHubURL[url];
    If[FailureQ[parsed],
      Return[iFailure["InvalidURL",
        "GitHub URL \:3092\:30d1\:30fc\:30b9\:3067\:304d\:307e\:305b\:3093: " <> url <>
        "\n\:5f62\:5f0f: https://github.com/owner/repo"]]];
    remoteOwner = parsed["owner"];
    remoteRepo = parsed["repo"];
    (* Owner と Repository を明示的に指定して既存の InstallPackage に委譲 *)
    result = GitHubInstallPackage[packageName,
      Owner -> remoteOwner, Repository -> remoteRepo,
      Sequence @@ FilterRules[{opts}, Except[Owner | Repository]]];
    (* RepoDB への owner + repository 登録はインストール成功後に行う。
       存在しないリポジトリ (404) でも先に登録すると、以後の PackageCommit 等が
       誤った owner を参照し続けてしまう (プレースホルダ URL 事故対策) *)
    If[FailureQ[result], Return[result]];
    GitHubRepoDBSet[packageName, remoteRepo, remoteOwner];
    Print["\:30ea\:30e2\:30fc\:30c8\:30ea\:30dd\:30b8\:30c8\:30ea\:3092\:767b\:9332: " <> remoteOwner <> "/" <> remoteRepo <>
      " \[RightArrow] " <> packageName];
    result
  ];

Options[GitHubUpdatePackage] = {
  Owner -> Automatic, Repository -> Automatic,
  Branch -> Automatic, BaseBranch -> Automatic,
  Fallback -> False, "Overwrite" -> True
};

GitHubUpdatePackage[packageName_String, opts:OptionsPattern[]] :=
  GitHubInstallPackage[packageName, opts, "Overwrite" -> True];

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
      ClaudeCode`Private`$currentUseFallback = True];
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
      ClaudeCode`Private`$currentUseFallback = True];
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
      ClaudeCode`Private`$currentUseFallback = True];
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
      ClaudeCode`Private`$currentUseFallback = True];
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
      ClaudeCode`Private`$currentUseFallback = True];
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

(* ── コミット履歴のコンパクト取得 (読み取り専用・承認不要) ──────
   GithubRepositories/<packageName> は REST API 同期のミラーフォルダで
   .git を持たない (ローカル git 履歴は存在しない)。コミット履歴の正本は
   GitHub 上にあるため、GitHubListCommits と同じ API GET を日付範囲
   (since/until) 付きで呼び、LLM が扱いやすいコンパクト形式で返す。
   リポジトリを一切変更しない読み取り操作なので、「いつ何が追加されたか」
   「6/20 以降の変更は?」のような質問に承認なしで答えられるよう、
   ファイル末尾で NBAccess`$NBTrustedPackageHeads に登録する。 *)

(* 日付指定の正規化: GitHub API の since/until は ISO 8601 (UTC) を要求。
   DateObject または日付文字列を "yyyy-MM-ddTHH:mm:ssZ" へ変換する。
   不正な入力は $Failed。 *)
iGHLogISODate[None] := None;
iGHLogISODate[Automatic] := None;
(* UTC 変換は TimeZoneConvert で行う。旧実装の
   DateObject[AbsoluteTime[d], TimeZone -> 0] は AbsoluteTime がローカル
   壁時計秒を返すため +$TimeZone の二重変換ずれを起こし、"...Z" 付き
   ISO 文字列が 9 時間未来へずれて "Since" フィルタが新しいコミットを
   取りこぼしていた (2026-08-04 実測: NotifyGitHub の NoCommitAfterResolution 誤判)。 *)
iGHLogISODate[d_DateObject] :=
  Quiet @ Check[
    DateString[TimeZoneConvert[d, 0], "ISODateTime"] <> "Z", $Failed];
iGHLogISODate[s_String] :=
  Module[{t = StringTrim[s], d},
    If[t === "" || !StringMatchQ[t,
        (DigitCharacter | "-" | "/" | ":" | "T" | "Z" | " " | "." | "+")..],
      Return[$Failed]];
    (* 末尾 Z は UTC 指定: TimeZone -> 0 を明示してパースする *)
    d = Quiet @ Check[
      If[StringEndsQ[t, "Z"],
        DateObject[StringDrop[t, -1], TimeZone -> 0],
        DateObject[t]], $Failed];
    If[DateObjectQ[d], iGHLogISODate[d], $Failed]];
iGHLogISODate[_] := $Failed;

Options[GitHubCommitLog] = {
  Owner -> Automatic, Repository -> Automatic,
  Branch -> Automatic, BaseBranch -> Automatic,
  MaxItems -> 50,
  "Since" -> None, "Until" -> None,
  Fallback -> False
};

GitHubCommitLog[packageName_String, opts:OptionsPattern[]] :=
  Module[{token, owner, repo, baseBranch, branch, maxN, since, until,
          params, resp, commits},
    since = iGHLogISODate[OptionValue["Since"]];
    until = iGHLogISODate[OptionValue["Until"]];
    If[since === $Failed || until === $Failed,
      Return[Failure["GitHubCommitLog",
        <|"MessageTemplate" ->
            "Since/Until は \"2026-06-20\" 形式の文字列か DateObject で指定してください"|>]]];
    token = iAccessToken[];
    If[FailureQ[token], Return[token]];
    owner = iResolveOwner[token, OptionValue[Owner], packageName];
    If[FailureQ[owner], Return[owner]];
    If[TrueQ[OptionValue[Fallback]],
      ClaudeCode`Private`$currentUseFallback = True];
    repo = iResolveRepository[packageName, OptionValue[Repository]];
    If[FailureQ[repo], Return[repo]];
    baseBranch = iResolveBaseBranch[token, owner, repo,
      OptionValue[BaseBranch]];
    If[FailureQ[baseBranch], Return[baseBranch]];
    branch = iResolveBranch[OptionValue[Branch], baseBranch];
    maxN = Min[Replace[OptionValue[MaxItems],
      Except[_Integer?Positive] -> 50], 300];
    params = <|"sha" -> branch, "per_page" -> Min[maxN, 100]|>;
    If[StringQ[since], params["since"] = since];
    If[StringQ[until], params["until"] = until];
    resp = iAPICall["GET",
      "repos/" <> owner <> "/" <> repo <> "/commits",
      token, None, params];
    If[FailureQ[resp], Return[resp]];
    commits = resp["Body"];
    If[!ListQ[commits], Return[{}]];
    Map[Function[c,
      Module[{cm = Lookup[c, "commit", <||>], au},
        au = Lookup[cm, "author", <||>];
        If[!AssociationQ[au], au = <||>];
        <|"SHA" -> Lookup[c, "sha", ""],
          "Date" -> Quiet @ Check[
            DateObject[Lookup[au, "date", ""]], Lookup[au, "date", ""]],
          "Author" -> Lookup[au, "name", ""],
          "Message" -> First[StringSplit[
            Replace[Lookup[cm, "message", ""], Except[_String] -> ""],
            "\n"], ""]|>]],
      Take[commits, UpTo[maxN]]]
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
      ClaudeCode`Private`$currentUseFallback = True];
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
      ClaudeCode`Private`$currentUseFallback = True];
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
      ClaudeCode`Private`$currentUseFallback = True];
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
    Module[{cuResult},
      cuResult = iCommitAndUpdateRef[
        token, owner, repo, branch,
        newCommitMsg, parentTreeSHA, headSHA,
        Automatic, Automatic, False
      ];
      If[FailureQ[cuResult], Return[cuResult]];
      <|"Action" -> "Revert", "Package" -> packageName,
        "RevertedCommit" -> StringTake[commitSHA, UpTo[7]],
        "ParentCommit" -> StringTake[parentSHA, UpTo[7]],
        "NewCommit" -> StringTake[cuResult["CommitSHA"], UpTo[7]],
        "Branch" -> branch,
        "Reason" -> reason|>
    ]
  ];

(* ============================================================
   Package auto-commit (旧 PackageAutoCommit.wl を統合)
   ============================================================ *)

(* パッケージディレクトリ: Global`$packageDirectory を正準、無ければ本ファイル位置 *)
iPACPackageDirectory[] := Module[{dir},
  dir = Quiet @ Check[Global`$packageDirectory, $Failed];
  If[StringQ[dir] && DirectoryQ[dir],
    dir,
    Quiet @ Check[DirectoryName[$InputFileName], $Failed]]
];

(* api ドキュメント 1 件 -> 対応 .wl のペア情報を構築する。
   api.md       -> <pkg>.wl
   api_<sfx>.md -> <pkg>_<sfx>.wl *)
iPACApiWlPair[pkg_String, srcDir_String, docsDir_String, docPath_String] := Module[
  {base, sfx, wl, wlPath, docExists, wlExists},
  base = FileBaseName[docPath];   (* "api" | "api_core" | ... *)
  sfx = If[base === "api", None, StringDrop[base, StringLength["api_"]]];  (* 補助名 or None *)
  wl = If[base === "api",
    pkg <> ".wl",
    pkg <> "_" <> sfx <> ".wl"];
  wlPath = FileNameJoin[{srcDir, wl}];
  docExists = FileExistsQ[docPath];
  wlExists = FileExistsQ[wlPath];
  <|
    "Doc" -> FileNameTake[docPath], "DocPath" -> docPath,
    "Wl" -> wl, "WlPath" -> wlPath, "WlExists" -> wlExists,
    "AuxName" -> sfx, "DocsDir" -> docsDir,
    "DocDate" -> If[docExists, FileDate[docPath, "Modification"], Missing["NoFile"]],
    "WlDate" -> If[wlExists, FileDate[wlPath, "Modification"], Missing["NoFile"]]
  |>
];

(* 補助ソースの内容ハッシュ。claudecode.wl の iAuxSourceHash と同一式でなければ照合できない
   (Import Text -> \r 除去 -> Hash -> 36 進)。ハッシュ機構を変える場合は両方を揃えること。 *)
iPACAuxSourceHash[wlPath_String] := Module[{txt = Quiet @ Check[Import[wlPath, "Text"], $Failed]},
  If[!StringQ[txt], $Failed, IntegerString[Hash[StringDelete[txt, "\r"]], 36]]];

(* claudecode が doc 生成時に記録する docsDir/.aux_source_hashes.json を読む (auxName -> hash) *)
iPACAuxHashRead[docsDir_String] := Module[
  {p = FileNameJoin[{docsDir, ".aux_source_hashes.json"}], j},
  If[!FileExistsQ[p], Return[<||>]];
  j = Quiet @ Check[Developer`ReadRawJSONString[Import[p, "Text"]], <||>];
  If[AssociationQ[j], j, <||>]];

(* 従来の mtime 基準: doc が対応 .wl より古ければ stale。両方が実日付で doc < wl のときのみ。 *)
iPACDocStaleMtimeQ[pair_Association] := Module[{dd, wd},
  dd = pair["DocDate"]; wd = pair["WlDate"];
  MatchQ[dd, _DateObject] && MatchQ[wd, _DateObject] &&
    AbsoluteTime[dd] < AbsoluteTime[wd]
];

(* stale 判定: 補助ソースの内容ハッシュが記録済みなら内容基準で判定し、Dropbox 同期等による
   mtime の揺れ (内容不変でも mtime が進む) を無視する。ClaudeUpdateDocumentation の
   iIsAuxApiFresh と同じ基準に揃え、DocsGate と doc 更新側の齟齬を防ぐ。
   記録ハッシュ == 現 .wl 内容ハッシュ → up-to-date、異なる → stale。
   キー: api.md 本体 → 予約キー "@main" (主ソース <pkg>.wl)、api_<aux>.md → auxName。
   ClaudeUpdateDocumentation が doc 生成成功時と「最新です」判定時に同じサイドカーへ記録する。
   未記録 (まだ doc 生成/判定していない) や内容が読めない場合のみ mtime にフォールバック。 *)
iPACDocStaleQ[pair_Association] := Module[
  {auxName = Lookup[pair, "AuxName", None], docsDir = Lookup[pair, "DocsDir", None],
   key, storedHash, curHash},
  If[!StringQ[docsDir], Return[iPACDocStaleMtimeQ[pair]]];
  key = If[auxName === None, "@main", auxName];   (* api.md 本体は主ソースを "@main" で照合 *)
  storedHash = Lookup[iPACAuxHashRead[docsDir], key, None];
  If[storedHash === None, Return[iPACDocStaleMtimeQ[pair]]];
  curHash = iPACAuxSourceHash[pair["WlPath"]];
  If[!StringQ[curHash], Return[iPACDocStaleMtimeQ[pair]]];
  storedHash =!= curHash
];

PackageDocsFreshnessGate[pkg_String] := Module[
  {srcDir, docsDir, apiDocs, pairs, checked, stale},
  srcDir = iPACPackageDirectory[];
  If[!StringQ[srcDir],
    Return[<|"Status" -> "Failed", "Package" -> pkg,
      "Reason" -> "PackageDirectoryNotResolved"|>]];
  docsDir = FileNameJoin[{srcDir, pkg <> "_info", "docs"}];
  If[!DirectoryQ[docsDir],
    Return[<|"Status" -> "NoDocs", "Package" -> pkg, "Proceed" -> True,
      "StaleDocs" -> {}, "Checked" -> 0, "DocsDir" -> docsDir,
      "Reason" -> "docs フォルダが無い (検査対象なし)"|>]];
  apiDocs = FileNames[{"api.md", "api_*.md"}, docsDir];
  pairs = iPACApiWlPair[pkg, srcDir, docsDir, #] & /@ apiDocs;
  checked = Select[pairs, TrueQ[#["WlExists"]] &];  (* 対応 .wl が在るものだけ検査 *)
  stale = Select[checked, iPACDocStaleQ];
  <|
    "Status" -> "OK", "Package" -> pkg,
    "Proceed" -> (Length[stale] === 0),
    "Checked" -> Length[checked],
    "StaleDocs" -> (KeyTake[#, {"Doc", "Wl", "DocDate", "WlDate"}] & /@ stale),
    "DocsDir" -> docsDir
  |>
];

PackageDocsFreshnessGate[___] :=
  <|"Status" -> "Failed",
    "Reason" -> "PackageDocsFreshnessGate[packageName_String] を期待。"|>;

(* --- 前回コミットスナップショットとの差分 (iRefreshPackageGroup の前方マッピングを ReadOnly に再現) --- *)

(* git 正規化パス (forward slash)。iNormalizeGitPath と同形。 *)
iPACNormGit[s_String] := StringJoin[Riffle[FileNameSplit[s], "/"]];

(* relBase/<dirAbs 相対パス> の git 相対パス。iCopyDirectoryFiltered の relPath と同形。 *)
iPACDirRel[relBase_String, dirAbs_String, file_String] :=
  iPACNormGit[relBase <> "/" <> FileNameJoin[FileNameDrop[file, FileNameDepth[dirAbs]]]];

(* ディレクトリ配下の全ファイル (隠しファイル含む・非ディレクトリ)。iListLocalFiles 相当。 *)
iPACDirFiles[dir_String] :=
  If[DirectoryQ[dir],
    DeleteDuplicates @ Select[
      Join[FileNames["*", dir, Infinity], FileNames[".*", dir, Infinity]],
      FileExistsQ[#] && ! DirectoryQ[#] &],
    {}];

(* exclude 判定 (prefix 一致)。iMatchExcludePattern と同形。 *)
iPACExcluded[relPath_String, patterns_List] :=
  AnyTrue[patterns, StringStartsQ[relPath, #] &];

(* 2 ファイルが同一内容か (byte 一致)。 *)
iPACSameContent[a_String, b_String] := Module[{ba, bb},
  ba = Quiet @ Check[ReadByteArray[a], $Failed];
  bb = Quiet @ Check[ReadByteArray[b], $Failed];
  ba === bb
];

iPACDiffSummary[added_List, changed_List, removed_List] :=
  "added " <> ToString[Length[added]] <>
  ", changed " <> ToString[Length[changed]] <>
  ", removed " <> ToString[Length[removed]];

PackageCommitDiff[pkg_String] := Module[
  {srcDir, snapDir, mfPath, manifest, files, dirs, patterns,
   added = {}, changed = {}, removed = {}, unchanged = 0, copiedRel = {},
   changedDetail = {}},
  srcDir = iPACPackageDirectory[];
  If[! StringQ[srcDir],
    Return[<|"Status" -> "Failed", "Package" -> pkg,
      "Reason" -> "PackageDirectoryNotResolved"|>]];
  (* スナップショット dir = GithubRepositories/<pkg> (GitHubRepoPath と同構成)。 *)
  snapDir = GitHubRepoPath[pkg];
  (* manifest は直接 Import (read-only)。GitHubReadManifest は manifest を自動編集・保存するため呼ばない。 *)
  mfPath = FileNameJoin[{srcDir, pkg <> "_info", "upload_manifest.json"}];
  manifest = If[FileExistsQ[mfPath],
    Quiet @ Check[Import[mfPath, "RawJSON"], $Failed], $Failed];
  If[! AssociationQ[manifest],
    manifest = <|"files" -> {pkg <> ".wl"},
      "directories" -> {pkg <> "_info"}, "excludePatterns" -> {}|>];
  files = Lookup[manifest, "files", {}];
  dirs = Lookup[manifest, "directories", {}];
  (* merged excludePatterns (manifest + default)。iMergedExcludePatterns と同形。 *)
  patterns = DeleteDuplicates @ Join[
    Lookup[manifest, "excludePatterns", {}],
    {pkg <> "_info/history/", pkg <> "_info/references/"}];
  (* --- 個別ファイル: src/<file> -> snap/<basename> --- *)
  Do[
    Module[{srcP, rel, snapP},
      srcP = FileNameJoin[{srcDir, file}];
      rel = FileNameTake[file];
      snapP = FileNameJoin[{snapDir, rel}];
      Which[
        ! FileExistsQ[srcP],
          If[FileExistsQ[snapP], AppendTo[removed, rel]],
        ! FileExistsQ[snapP],
          AppendTo[added, rel]; AppendTo[copiedRel, rel];
          AppendTo[changedDetail, <|"Rel" -> rel, "Src" -> srcP, "Snap" -> snapP|>],
        iPACSameContent[srcP, snapP],
          unchanged++; AppendTo[copiedRel, rel],
        True,
          AppendTo[changed, rel]; AppendTo[copiedRel, rel];
          AppendTo[changedDetail, <|"Rel" -> rel, "Src" -> srcP, "Snap" -> snapP|>]]],
    {file, files}];
  (* --- ディレクトリ: src/<dir>/<rest> -> snap/<dir>/<rest> (exclude 適用) --- *)
  Do[
    Module[{dirAbs, srcFiles},
      dirAbs = FileNameJoin[{srcDir, dir}];
      If[DirectoryQ[dirAbs],
        srcFiles = iPACDirFiles[dirAbs];
        Do[
          Module[{rel, snapP},
            rel = iPACDirRel[dir, dirAbs, f];
            If[! iPACExcluded[rel, patterns],
              snapP = FileNameJoin[Flatten[{snapDir, FileNameSplit[rel]}]];
              AppendTo[copiedRel, rel];
              Which[
                ! FileExistsQ[snapP], AppendTo[added, rel];
                  AppendTo[changedDetail, <|"Rel" -> rel, "Src" -> f, "Snap" -> snapP|>],
                iPACSameContent[f, snapP], unchanged++,
                True, AppendTo[changed, rel];
                  AppendTo[changedDetail, <|"Rel" -> rel, "Src" -> f, "Snap" -> snapP|>]]]],
          {f, srcFiles}]]],
    {dir, dirs}];
  (* --- removed (dir): snapshot にあり現 src map に無く exclude でないファイル --- *)
  Do[
    Module[{snapDirAbs, snapFiles},
      snapDirAbs = FileNameJoin[{snapDir, dir}];
      If[DirectoryQ[snapDirAbs],
        snapFiles = iPACDirFiles[snapDirAbs];
        Do[
          Module[{rel},
            rel = iPACDirRel[dir, snapDirAbs, f];
            If[! MemberQ[copiedRel, rel] && ! iPACExcluded[rel, patterns],
              AppendTo[removed, rel]]],
          {f, snapFiles}]]],
    {dir, dirs}];
  removed = DeleteDuplicates[removed];
  <|
    "Status" -> "OK", "Package" -> pkg,
    "SnapshotDir" -> snapDir, "SnapshotExists" -> DirectoryQ[snapDir],
    "Added" -> Sort[added], "Changed" -> Sort[changed], "Removed" -> Sort[removed],
    "UnchangedCount" -> unchanged,
    "ChangeCount" -> (Length[added] + Length[changed] + Length[removed]),
    "ChangedDetail" -> changedDetail,
    "Summary" -> iPACDiffSummary[added, changed, removed]
  |>
];

PackageCommitDiff[___] :=
  <|"Status" -> "Failed",
    "Reason" -> "PackageCommitDiff[packageName_String] を期待。"|>;

(* --- 決定論コミットメッセージ + 計画 + 駆動関数 --- *)

(* relative path のリストを basename の読みやすい列挙にする (最大 3 件、超過は "ほか N 件")。 *)
iPACNameList[rels_List] := Module[{names},
  names = FileNameTake /@ rels;
  If[Length[names] <= 3,
    StringRiffle[names, ", "],
    StringRiffle[Take[names, 2], ", "] <> " ほか " <> ToString[Length[names] - 2] <> " 件"]
];

(* 差分から決定論的な簡潔単文の日本語コミットメッセージを作る。 *)
iPACDefaultMessage[diff_Association] := Module[{a, c, r, parts},
  a = Lookup[diff, "Added", {}];
  c = Lookup[diff, "Changed", {}];
  r = Lookup[diff, "Removed", {}];
  If[Length[a] + Length[c] + Length[r] === 0, Return["変更なし"]];
  parts = {};
  If[Length[c] > 0, AppendTo[parts, iPACNameList[c] <> " を更新"]];
  If[Length[a] > 0, AppendTo[parts, iPACNameList[a] <> " を追加"]];
  If[Length[r] > 0, AppendTo[parts, iPACNameList[r] <> " を削除"]];
  StringRiffle[parts, "、"]
];

(* 既定コミットメッセージモデル。
   Automatic (既定) = claudecode がロード済みなら周囲の既定モデル ($ClaudeModel) で差分内容を
     要約した LLM メッセージを生成、未ロード/失敗時は決定論メッセージへフォールバック。
   モデル指定子/関数を代入すればそれを使用。None を代入すると LLM を呼ばず決定論に固定。
   再ロード保持。 *)
If[! ValueQ[$PackageCommitModel], $PackageCommitModel = Automatic];

(* claudecode がロード済み (ClaudeQueryBg に定義あり) なら周囲の既定モデルで LLM を呼ぶ
   queryFn を返す。無ければ None (= 決定論フォールバック)。 *)
iPACAutoQueryFn[] := If[
  Length[Names["ClaudeCode`ClaudeQueryBg"]] > 0 &&
    Length[DownValues[ClaudeCode`ClaudeQueryBg]] > 0,
  With[{qbg = ClaudeCode`ClaudeQueryBg}, Function[p, qbg[p]]],
  None];

(* LLM 生成を試み、非文字列/空/失敗なら決定論へフォールバック。 *)
iPACTryLLMMessage[genSpec_, diff_Association] := Module[
  {m = Quiet @ Check[PackageLLMMessageGenerator[genSpec][diff], $Failed]},
  If[StringQ[m] && StringTrim[m] =!= "", m, iPACDefaultMessage[diff]]];

(* MessageGenerator の解決。
   明示 String=固定文 / 明示 Function 等=そのまま diff を渡す。
   Automatic は $PackageCommitModel で分岐:
     None=決定論固定 / モデル指定子=そのモデルで LLM / Automatic=周囲の既定モデル (無ければ決定論)。 *)
iPACResolveMessage[gen_, diff_Association] := Which[
  StringQ[gen], gen,
  gen =!= Automatic,
    Module[{m = Quiet @ Check[gen[diff], $Failed]},
      If[StringQ[m] && StringTrim[m] =!= "", m, iPACDefaultMessage[diff]]],
  $PackageCommitModel === None, iPACDefaultMessage[diff],
  $PackageCommitModel =!= Automatic, iPACTryLLMMessage[$PackageCommitModel, diff],
  True,
    Module[{qf = iPACAutoQueryFn[]},
      If[qf === None, iPACDefaultMessage[diff], iPACTryLLMMessage[qf, diff]]]
];

(* === 謝辞保全ゲート (2026-07-18) ===
   2026-07-16 に claudecode README の「## 謝辞」節がドキュメント再生成で消えたまま
   コミットされた事故の再発防止。前回コミット (スナップショット) に謝辞がある README が
   謝辞なしで上書き/削除されるコミットは公開境界で Blocked にする (fail-closed)。 *)

(* ファイルに「## 謝辞」節見出しが含まれるか (UTF-8 バイト読みで判定) *)
iPACHasAckSection[path_String] :=
  FileExistsQ[path] &&
    StringContainsQ[
      StringReplace[
        Quiet @ Check[ByteArrayToString[ReadByteArray[path], "UTF-8"], ""],
        "\r\n" -> "\n"],
      RegularExpression["(?m)^##[ \t]+謝辞[ \t]*$"]];
iPACHasAckSection[_] := False;

(* 差分中で謝辞が失われる README の Rel リスト (変更で消える + ファイルごと削除) *)
iPACAckLossFiles[diff_Association] := Module[
  {det, snapDir, removed, lossChanged, lossRemoved},
  det = Replace[Lookup[diff, "ChangedDetail", {}], Except[_List] -> {}];
  lossChanged = Cases[det,
    d_Association /; FileNameTake[Lookup[d, "Rel", ""]] === "README.md" &&
      iPACHasAckSection[Lookup[d, "Snap", ""]] &&
      ! iPACHasAckSection[Lookup[d, "Src", ""]] :> Lookup[d, "Rel", ""]];
  snapDir = Lookup[diff, "SnapshotDir", ""];
  removed = Replace[Lookup[diff, "Removed", {}], Except[_List] -> {}];
  lossRemoved = Select[removed,
    FileNameTake[#] === "README.md" && StringQ[snapDir] && snapDir =!= "" &&
      iPACHasAckSection[FileNameJoin[Flatten[{snapDir, FileNameSplit[#]}]]] &];
  DeleteDuplicates[Join[lossChanged, lossRemoved]]
];

Options[PackageCommitPlan] = {"MessageGenerator" -> Automatic, "SkipDocsGate" -> False,
  "AllowAckRemoval" -> False};

PackageCommitPlan[pkg_String, OptionsPattern[]] := Module[
  {gate, diff, msg, skipGate, gateProceed, staleWarn, ackLoss},
  skipGate = TrueQ[OptionValue["SkipDocsGate"]];
  gate = PackageDocsFreshnessGate[pkg];
  If[Lookup[gate, "Status", ""] === "Failed",
    Return[<|"Status" -> "Failed", "Package" -> pkg, "Phase" -> "Gate",
      "Detail" -> gate|>]];
  gateProceed = TrueQ[Lookup[gate, "Proceed", False]];
  If[! skipGate && ! gateProceed,
    Return[<|"Status" -> "Blocked", "Package" -> pkg, "Proceed" -> False,
      "Reason" -> "StaleDocs (対応 .wl 更新後に api ドキュメントが未更新)。SkipDocsGate -> True でゲート無視可。",
      "StaleDocs" -> Lookup[gate, "StaleDocs", {}]|>]];
  (* SkipDocsGate で古い docs のまま進めた場合は警告として StaleDocs を残す *)
  staleWarn = If[skipGate && ! gateProceed, Lookup[gate, "StaleDocs", {}], {}];
  diff = PackageCommitDiff[pkg];
  If[Lookup[diff, "Status", ""] =!= "OK",
    Return[<|"Status" -> "Failed", "Package" -> pkg, "Phase" -> "Diff",
      "Detail" -> diff|>]];
  If[Lookup[diff, "ChangeCount", 0] === 0,
    Return[<|"Status" -> "NoChange", "Package" -> pkg, "Proceed" -> False,
      "Reason" -> "差分なし (コミット対象なし)", "Diff" -> diff|>]];
  (* 謝辞保全ゲート: README の「## 謝辞」節が前回コミットから失われるコミットを拒否。
     解除は明示 "AllowAckRemoval" -> True のみ (SkipDocsGate では解除されない)。 *)
  If[! TrueQ[OptionValue["AllowAckRemoval"]],
    ackLoss = iPACAckLossFiles[diff];
    If[Length[ackLoss] > 0,
      Return[<|"Status" -> "Blocked", "Package" -> pkg, "Proceed" -> False,
        "Reason" -> "AckLoss (前回コミットにある README の「## 謝辞」節が消えています: " <>
          StringRiffle[ackLoss, ", "] <>
          ")。謝辞の削除は禁止。docs/README.md と doc_options.json の Acknowledgments を復元してください。" <>
          "意図的な削除の場合のみ \"AllowAckRemoval\" -> True を明示指定。",
        "AckLossFiles" -> ackLoss, "Diff" -> diff|>]]];
  msg = iPACResolveMessage[OptionValue["MessageGenerator"], diff];
  <|"Status" -> "OK", "Package" -> pkg, "Proceed" -> True,
    "StaleDocs" -> staleWarn, "DocsGateSkipped" -> (skipGate && ! gateProceed),
    "Diff" -> diff, "CommitMessage" -> msg|>
];

PackageCommitPlan[___] :=
  <|"Status" -> "Failed",
    "Reason" -> "PackageCommitPlan[packageName_String, opts] を期待。"|>;

PackageCommit::staledocs =
  "`1` は api ドキュメント (`2`) が対応 .wl より古いため、実コミットを停止しました。" <>
  "ドキュメントを更新してから再実行するか、確認だけなら DryRun + SkipDocsGate -> True を使ってください。";

PackageCommit::ackloss =
  "`1` のコミットで README の「## 謝辞」節が失われるため停止しました (`2`)。" <>
  "docs/README.md と doc_options.json の Acknowledgments を復元してください。" <>
  "意図的な削除の場合のみ \"AllowAckRemoval\" -> True を明示指定してください。";

(* 非コミット結果 (Blocked/NoChange/Failed) の CommitMessage を意味のある Missing にする。
   KeyAbsent ではなく理由付き Missing を返し、誤って実メッセージと混同しないようにする。 *)
iPACNoCommitMessage[status_, pkg_String, plan_Association] := Switch[status,
  "Blocked",
    If[Length[Lookup[plan, "AckLossFiles", {}]] > 0,
      Missing["AckLoss", ToString @ Lookup[plan, "Reason",
        pkg <> ": README の「## 謝辞」節が失われるため停止。"]],
      Missing["StaleDocs", pkg <> ": docs (api*.md) が対応 .wl より古いため停止。" <>
        "更新するか、DryRun + SkipDocsGate -> True でメッセージ案を確認してください。"]],
  "NoChange",
    Missing["NoChange", pkg <> ": 前回コミットからの差分がありません (コミット対象なし)。"],
  "Failed",
    Missing["Failed", ToString @ Lookup[plan, "Reason", Lookup[plan, "Phase", "失敗"]]],
  _,
    Missing["NoCommitMessage", ToString[status]]
];

Options[PackageCommit] = {"DryRun" -> True, "MessageGenerator" -> Automatic,
  "SkipDocsGate" -> False, "AllowAckRemoval" -> False,
  (* 2026-07-08: リモート残骸掃除用に GitHubRefreshAndCommit へ転送。
     削除対象 = リモートにあってミラーに無いもの全部なので、実行前に
     PackageCommitDeletionPreview[pkg] で削除候補を必ず確認すること。
     除外パターン保護されたミラー内ファイル (docs/docs 等) は先にミラーから
     手動削除しないとツリーに残り続けて削除されない点に注意。 *)
  "DeleteMissing" -> False};

PackageCommit[pkg_String, OptionsPattern[]] := Module[
  {dry, skipGate, plan, res},
  dry = TrueQ[OptionValue["DryRun"]];
  skipGate = TrueQ[OptionValue["SkipDocsGate"]];
  (* SkipDocsGate は DryRun プレビュー専用。実コミット (DryRun -> False) では
     SkipDocsGate に関わらず docs 鮮度ゲートを必ず適用する。 *)
  plan = PackageCommitPlan[pkg, "MessageGenerator" -> OptionValue["MessageGenerator"],
    "SkipDocsGate" -> (skipGate && dry),
    "AllowAckRemoval" -> TrueQ[OptionValue["AllowAckRemoval"]]];
  (* OK 以外 (Blocked / NoChange / Failed) はコミットしない *)
  If[Lookup[plan, "Status", ""] =!= "OK",
    Module[{st = Lookup[plan, "Status", ""], stale = Lookup[plan, "StaleDocs", {}]},
      (* 謝辞保全ゲートで Blocked: AckLoss 専用の警告を出して停止 (DryRun でも実コミットでも)。 *)
      If[st === "Blocked" && Length[Lookup[plan, "AckLossFiles", {}]] > 0,
        Message[PackageCommit::ackloss, pkg,
          StringRiffle[Lookup[plan, "AckLossFiles", {}], ", "]];
        Return[<|"Status" -> "Blocked", "Package" -> pkg, "Committed" -> False,
          "CommitMessage" -> iPACNoCommitMessage["Blocked", pkg, plan],
          "Reason" -> Lookup[plan, "Reason", "AckLoss"],
          "AckLossFiles" -> Lookup[plan, "AckLossFiles", {}]|>]];
      (* 実コミット要求が docs 古さで Blocked: 警告メッセージを出して停止 (実コミットでは SkipDocsGate 無効)。 *)
      If[! dry && st === "Blocked",
        Message[PackageCommit::staledocs, pkg,
          StringRiffle[ToString @ Lookup[#, "Doc", "?"] & /@ stale, ", "]];
        Return[<|"Status" -> "Blocked", "Package" -> pkg, "Committed" -> False,
          "CommitMessage" -> iPACNoCommitMessage["Blocked", pkg, plan],
          "Reason" -> "実コミットには docs 更新が必須です。下記 api ドキュメントを対応 .wl 以降に更新してから再実行してください " <>
            "(SkipDocsGate は DryRun プレビュー専用で実コミットには効きません)。",
          "StaleDocs" -> stale,
          "Hint" -> "ドキュメント更新後に PackageCommit[\"" <> pkg <> "\", \"DryRun\" -> False] を再実行。"|>]];
      (* それ以外 (DryRun Blocked / NoChange / Failed): CommitMessage を意味のある Missing で補う。 *)
      Return[Append[plan, <|"Committed" -> False,
        "CommitMessage" -> iPACNoCommitMessage[st, pkg, plan]|>]]]];
  If[dry,
    Return[<|"Status" -> "DryRun", "Package" -> pkg, "Committed" -> False,
      "CommitMessage" -> plan["CommitMessage"], "Diff" -> plan["Diff"],
      "DocsGateSkipped" -> Lookup[plan, "DocsGateSkipped", False],
      "StaleDocs" -> Lookup[plan, "StaleDocs", {}],
      "Note" -> "DryRun -> False で実コミット (GitHubRefreshAndCommit) を実行。"|>]];
  res = GitHubRefreshAndCommit[pkg, plan["CommitMessage"],
    DeleteMissing -> TrueQ[OptionValue["DeleteMissing"]]];
  <|"Status" -> If[FailureQ[res], "Failed", "Committed"], "Package" -> pkg,
    "Committed" -> ! FailureQ[res], "CommitMessage" -> plan["CommitMessage"],
    "DocsGateSkipped" -> Lookup[plan, "DocsGateSkipped", False],
    "StaleDocs" -> Lookup[plan, "StaleDocs", {}],
    "Result" -> res|>
];

PackageCommit[___] :=
  <|"Status" -> "Failed",
    "Reason" -> "PackageCommit[packageName_String, opts] を期待。"|>;

(* DeleteMissing の削除候補を実行せずに列挙する (2026-07-08)。
   GitHubCommit の DeleteMissing 計算 (remote tree − ローカルミラー) と
   同じ式を読み取り専用で再現する。ミラーには手を触れない。 *)
PackageCommitDeletionPreview[packageName_String] := Module[
  {token, owner, repo, baseBranch, ref, headSHA, commitObj, baseTreeSHA,
   remoteTree, remotePaths, localDir, localPaths},
  token = iAccessToken[]; If[FailureQ[token], Return[token]];
  owner = iResolveOwner[token, Automatic, packageName];
  If[FailureQ[owner], Return[owner]];
  repo = iResolveRepository[packageName, Automatic];
  If[FailureQ[repo], Return[repo]];
  baseBranch = iResolveBaseBranch[token, owner, repo, Automatic];
  If[FailureQ[baseBranch], Return[baseBranch]];
  ref = iWaitForRef[token, owner, repo, baseBranch];
  If[FailureQ[ref], Return[ref]];
  headSHA = Lookup[Lookup[ref["Body"], "object", <||>], "sha", Missing[]];
  If[! StringQ[headSHA],
    Return[iFailure["MissingHeadSHA", "head SHA を取得できませんでした。", <||>]]];
  commitObj = iGetCommitObject[token, owner, repo, headSHA];
  If[FailureQ[commitObj], Return[commitObj]];
  baseTreeSHA = Lookup[Lookup[commitObj["Body"], "tree", <||>], "sha", Missing[]];
  If[! StringQ[baseTreeSHA],
    Return[iFailure["MissingBaseTreeSHA", "tree SHA を取得できませんでした。", <||>]]];
  remoteTree = iGetTreeRecursive[token, owner, repo, baseTreeSHA];
  If[FailureQ[remoteTree], Return[remoteTree]];
  remotePaths = Cases[Lookup[remoteTree["Body"], "tree", {}],
    a_Association /; Lookup[a, "type", None] === "blob" :>
      Lookup[a, "path", ""]];
  localDir = GitHubEnsureLocalRepo[packageName];
  If[FailureQ[localDir], Return[localDir]];
  localPaths = iNormalizeGitPath[
    FileNameJoin[FileNameDrop[#, FileNameDepth[localDir]]]] & /@
    iListLocalFiles[localDir];
  <|"WouldDelete" -> Sort[Complement[remotePaths, localPaths]],
    "RemoteCount" -> Length[remotePaths],
    "LocalCount" -> Length[localPaths],
    "Owner" -> owner, "Repository" -> repo, "Branch" -> baseBranch|>];

PackageCommitDeletionPreview[___] :=
  <|"Status" -> "Failed",
    "Reason" -> "PackageCommitDeletionPreview[packageName_String] を期待。"|>;

(* --- LLM コミットメッセージ生成 (MessageGenerator ビルダー、content-aware) --- *)

(* 差分を LLM プロンプト用テキストに整形 (相対パス、変更種別ごと)。 *)
iPACDiffForPrompt[diff_Association] := Module[{a, c, r, lines},
  a = Lookup[diff, "Added", {}]; c = Lookup[diff, "Changed", {}]; r = Lookup[diff, "Removed", {}];
  lines = {};
  If[Length[c] > 0, AppendTo[lines, "変更: " <> StringRiffle[c, ", "]]];
  If[Length[a] > 0, AppendTo[lines, "追加: " <> StringRiffle[a, ", "]]];
  If[Length[r] > 0, AppendTo[lines, "削除: " <> StringRiffle[r, ", "]]];
  If[lines === {}, "変更なし", StringRiffle[lines, "\n"]]
];

(* 文字列に日本語 (CJK 記号・かな・漢字・全角形) が含まれるか。
   生成プロンプトは日本語 1 文を要求するので、日本語を全く含まないメッセージは
   CLI 警告/エラー等の英語定型文とみなし不採用にする (2026-07-18)。 *)
iPACHasJapaneseQ[s_String] := AnyTrue[ToCharacterCode[s],
  (16^^3000 <= # <= 16^^30FF) || (16^^3400 <= # <= 16^^9FFF) ||
    (16^^FF01 <= # <= 16^^FF60) &];
iPACHasJapaneseQ[_] := False;

(* Claude Code CLI の警告/通知行か (英語のみの行が対象。日本語を含む行は本文とみなす)。
   実事故 (2026-07-16, commit 45b7ea19): 未 trust ワークスペースで CLI が stderr へ出した
   "Ignoring 5 permissions.allow entries from .claude/settings.json: this workspace
   has not been trusted. Run Claude Code interactively ..." が bat の 2>&1 で
   プレーンテキスト応答の先頭に混入し、iPACCleanMessage の先頭行選択で
   そのままコミットメッセージに採用された。 *)
iPACCLIWarningLineQ[line_String] := Module[{t = StringTrim[line]},
  ! iPACHasJapaneseQ[t] &&
    TrueQ @ Or[
      StringStartsQ[t, "Ignoring" | "Warning" | "warning:" | "WARN" |
        "Error" | "error:" | "fatal:" | "Note:" | "Notice" | "Usage:"],
      StringContainsQ[t,
        "permissions.allow" | "permissions.deny" | "has not been trusted" |
          "Run Claude Code interactively" | "trust dialog" |
          "hasTrustDialogAccepted"]]];
iPACCLIWarningLineQ[_] := False;

(* LLM 応答を単文メッセージに整形: code fence マーカー行のみ除去 (本文は残す) ->
   CLI 警告/通知行を除去 -> 先頭非空行 -> 前後引用符除去。
   フェンスで全体を囲んだ応答でも本文を失わない。 *)
iPACCleanMessage[resp_String] := Module[{lines},
  lines = StringTrim /@ StringSplit[resp, "\n"];
  lines = DeleteCases[lines, l_ /; StringMatchQ[l, "```" ~~ ___]];  (* ```/```lang 行を除去 *)
  lines = DeleteCases[lines, l_ /; iPACCLIWarningLineQ[l]];  (* CLI 警告行を除去 *)
  lines = Select[lines, # =!= "" &];
  If[lines === {}, Return["", Module]];
  StringTrim[First[lines], ("\"" | "'" | "「" | "」" | "`")]
];
iPACCleanMessage[_] := "";

(* ファイルを UTF-8 で行リストに読む (ReadString は $CharacterEncoding 依存なので避ける)。 *)
iPACReadLines[path_String] := Module[{ba},
  ba = Quiet @ Check[ReadByteArray[path], $Failed];
  If[! ByteArrayQ[ba], Return[{}, Module]];
  StringSplit[ByteArrayToString[ba, "UTF-8"], "\n"]
];

(* snap(旧) と src(新) の行差分を - 削除 / + 追加 で返す。
   ハッシュ集合ベース (O(n))。順序保持・重複除去。巨大ファイルでも高速。 *)
iPACUnifiedDiff[snapPath_String, srcPath_String, maxChars_Integer] := Module[
  {old, new, oldSet, newSet, rem, add, out},
  old = iPACReadLines[snapPath];
  new = iPACReadLines[srcPath];
  oldSet = AssociationThread[old -> True];
  newSet = AssociationThread[new -> True];
  rem = DeleteDuplicates @ Select[old, ! KeyExistsQ[newSet, #] && StringTrim[#] =!= "" &];
  add = DeleteDuplicates @ Select[new, ! KeyExistsQ[oldSet, #] && StringTrim[#] =!= "" &];
  out = StringJoin[
    ("- " <> # <> "\n") & /@ Take[rem, UpTo[60]],
    ("+ " <> # <> "\n") & /@ Take[add, UpTo[60]]];
  If[StringLength[out] > maxChars, StringTake[out, maxChars] <> "\n...(truncated)", out]
];

(* ChangedDetail (変更・追加ファイルの Rel/Src/Snap) から変更内容セクションを組み立てる。
   追加ファイルは Snap 不在で全行が + (新規内容) になる。
   各ファイルに公平な予算 (合計/ファイル数、ただし各 300〜maxPerFile) を配分し、
   先頭の巨大ファイルが予算を食って末尾 (追加ファイル等) が落ちるのを防ぐ。 *)
iPACContentForPrompt[diff_Association, maxTotal_Integer, maxPerFile_Integer] := Module[
  {detail, added, n, effPerFile, parts},
  detail = Lookup[diff, "ChangedDetail", {}];
  added = Lookup[diff, "Added", {}];
  If[! ListQ[detail] || detail === {}, Return["", Module]];
  n = Max[1, Length[detail]];
  effPerFile = Min[maxPerFile, Max[300, Ceiling[maxTotal / n]]];
  parts = Table[
    Module[{rel, d, header},
      rel = ToString @ Lookup[item, "Rel", "?"];
      d = iPACUnifiedDiff[ToString @ Lookup[item, "Snap", ""],
        ToString @ Lookup[item, "Src", ""], effPerFile];
      header = "## " <> rel <> If[MemberQ[added, rel], " (新規ファイル)", ""] <> "\n";
      If[StringTrim[d] === "", Nothing, header <> d]],
    {item, detail}];
  StringRiffle[parts, "\n"]
];

(* queryFn 解決: 関数/シンボルはそのまま。モデル指定子 (tuple {provider,model} or String) は
   ClaudeCode`ClaudeQueryBg[prompt, Model -> spec] でラップ (弱呼び出し)。
   Model オプションの symbol は Options[ClaudeQueryBg] から取り出し context 差を吸収。 *)
iPACWrapModel[spec_] := With[
  {qbg = ClaudeCode`ClaudeQueryBg,
   modelKey = SelectFirst[Keys[Options[ClaudeCode`ClaudeQueryBg]],
     SymbolName[#] === "Model" &, None]},
  If[modelKey === None,
    Function[p, qbg[p]],
    With[{mk = modelKey, sp = spec}, Function[p, qbg[p, mk -> sp]]]]
];
iPACResolveQueryFn[spec_] := Which[
  (ListQ[spec] || StringQ[spec]) &&
    Length[Names["ClaudeCode`ClaudeQueryBg"]] > 0,
    iPACWrapModel[spec],
  True, spec
];

(* LLM 応答がエラー/レート制限メッセージか判定 (コミットメッセージに流用させない)。
   claudecode がロード済みならその堅牢検出器を再利用、無ければローカル検出で fail-closed。
   例: "You've hit your session limit ・ resets 5:30pm (Asia/Tokyo)" / "Error: ..." を弾く。 *)
iPACLooksLikeErrorResponse[s_String] := Module[{t = StringTrim[s]},
  TrueQ @ Or[
    StringStartsQ[t, "Error"],
    StringStartsQ[t, "{\"type\":\"error\""],
    StringContainsQ[s, "\"is_error\":true"],
    StringContainsQ[s, "\"error\":\"rate_limit\"" | "\"error\":\"overloaded\"" |
                       "\"error\":\"api_error\""],
    (StringLength[s] < 1000 &&
      StringContainsQ[s, "\[CenterDot]"] &&
      StringContainsQ[s, "limit" | "resets", IgnoreCase -> True]),
    (StringLength[s] < 1000 &&
      StringContainsQ[s, "hit your limit" | "hit your session limit" |
                         "session limit" | "usage limit" | "rate limit" |
                         "overloaded" | "quota exceeded" | "too many requests",
        IgnoreCase -> True])]];
iPACLooksLikeErrorResponse[_] := True;

iPACErrorResponseQ[s_String] := TrueQ[iPACLooksLikeErrorResponse[s]] ||
  (Length[Names["ClaudeCode`Private`iIsAPIErrorResponse"]] > 0 &&
   Length[DownValues[ClaudeCode`Private`iIsAPIErrorResponse]] > 0 &&
   TrueQ[Quiet @ Check[ClaudeCode`Private`iIsAPIErrorResponse[s], False]]);
iPACErrorResponseQ[_] := True;

Options[PackageLLMMessageGenerator] = {
  "MaxChars" -> 80, "IncludeContent" -> True,
  "MaxContentChars" -> 4000, "MaxPerFileChars" -> 1500};

PackageLLMMessageGenerator[queryFnSpec_, opts:OptionsPattern[]] := Module[
  {maxC, incC, maxTotal, maxPerFile, qfn},
  maxC = With[{m = OptionValue["MaxChars"]}, If[IntegerQ[m] && m > 0, m, 80]];
  incC = TrueQ[OptionValue["IncludeContent"]];
  maxTotal = With[{m = OptionValue["MaxContentChars"]}, If[IntegerQ[m] && m > 0, m, 4000]];
  maxPerFile = With[{m = OptionValue["MaxPerFileChars"]}, If[IntegerQ[m] && m > 0, m, 1500]];
  qfn = iPACResolveQueryFn[queryFnSpec];
  Function[diff,
    Module[{contentSec, prompt, resp, msg},
      If[! AssociationQ[diff], Return[iPACDefaultMessage[<||>], Module]];
      contentSec = If[incC, iPACContentForPrompt[diff, maxTotal, maxPerFile], ""];
      prompt = "次は、あるパッケージの前回コミットからの変更です。これを説明する日本語のコミットメッセージを 1 文で書いてください。\n" <>
        "文末は体言止め (名詞・サ変名詞で終える。例: 追加 / 刷新 / 修正 / 整理 / 対応)。" <>
        "「〜した」「〜する」「〜しました」「〜するとともに」等の冗長な言い回しは避け、" <>
        "複数の変更は読点で簡潔につなぐ。" <> ToString[maxC] <> " 字以内、句点は末尾に 1 つだけ。\n" <>
        "ファイル名の列挙ではなく、何をしたか (機能追加・不具合修正・挙動変更など) を要約する。\n" <>
        "例: パレットUIコードを整理しAPIリファレンスを刷新、高プライバシーデータをクラウドLLMのコンテキストに送信しない制約をCLAUDE.mdに追加。\n" <>
        "コミットメッセージ本文のみを出力し、前置き・引用符・コードフェンスは付けない。\n\n" <>
        "変更ファイル:\n" <> iPACDiffForPrompt[diff] <>
        If[contentSec =!= "", "\n\n変更内容 (- 削除行 / + 追加行):\n" <> contentSec, ""];
      resp = Quiet @ Check[qfn[prompt], $Failed];
      (* エラー/レート制限応答はコミットメッセージに使わず決定論へ落とす *)
      msg = If[StringQ[resp] && ! iPACErrorResponseQ[resp], iPACCleanMessage[resp], ""];
      (* 日本語 1 文の指示に対し日本語を全く含まない応答 (CLI 警告等の英語定型文) も不採用 *)
      If[! iPACHasJapaneseQ[msg], msg = ""];
      If[StringQ[msg] && StringTrim[msg] =!= "", msg, iPACDefaultMessage[diff]]
    ]]
];

(* ============================================================
   GitHub Issues API (読み取り専用)
   Issue の列挙・取得・コメント・作成者プロファイル・管理下全リポジトリ集約。
   すべて GET のみでリポジトリを一切変更しない。SourceVault_issues.wl の
   汎用イシューDB取込 (SourceVaultIssueIngestGitHub) がこの層を供給元とする。
   ============================================================ *)

(* Issue 応答の正規化。body の JSON null は Null で届くため "" に落とす。
   GitHub API は PR も issues エンドポイントで返すので IsPullRequest を保持。 *)
iIssueNormalize[raw_Association, pkg_String, owner_String, repo_String] := <|
  "Package" -> pkg,
  "Owner" -> owner,
  "Repository" -> repo,
  "Number" -> Lookup[raw, "number", 0],
  "Title" -> Replace[Lookup[raw, "title", ""], Except[_String] -> ""],
  "Body" -> Replace[Lookup[raw, "body", ""], Except[_String] -> ""],
  "State" -> Replace[Lookup[raw, "state", ""], Except[_String] -> ""],
  "Labels" -> Cases[Replace[Lookup[raw, "labels", {}], Except[_List] -> {}],
    l_Association :> Lookup[l, "name", ""]],
  "Author" -> Lookup[Replace[Lookup[raw, "user", <||>], Except[_Association] -> <||>],
    "login", ""],
  "AuthorAssociation" -> Replace[Lookup[raw, "author_association", ""],
    Except[_String] -> ""],
  "CreatedAt" -> Replace[Lookup[raw, "created_at", ""], Except[_String] -> ""],
  "UpdatedAt" -> Replace[Lookup[raw, "updated_at", ""], Except[_String] -> ""],
  "CommentCount" -> Replace[Lookup[raw, "comments", 0], Except[_Integer] -> 0],
  "URL" -> Replace[Lookup[raw, "html_url", ""], Except[_String] -> ""],
  "IsPullRequest" -> KeyExistsQ[raw, "pull_request"]|>;

(* 読み取り専用経路のリポジトリ名解決。iResolveRepository[pkg, Automatic] は
   非 ASCII 名のとき LLM 自動命名 + repo_database.json 書込の副作用を持つため
   ここでは使わない。DB lookup のみで、未登録の非 ASCII 名は Failure。 *)
iIssueRepoName[packageName_String, Automatic] := Module[{dbName},
  dbName = GitHubRepoDBLookup[packageName];
  If[iIsASCIIName[dbName], dbName,
    iFailure["RepositoryNameUnresolved",
      "リポジトリ英語名が repo_database.json に未登録です: " <> packageName,
      <|"Package" -> packageName|>]]];
iIssueRepoName[_String, repo_String] := repo;

Options[GitHubListIssues] = {
  Owner -> Automatic, Repository -> Automatic,
  MaxItems -> 50, "State" -> "open", "IncludePullRequests" -> False
};

GitHubListIssues[packageName_String, opts:OptionsPattern[]] :=
  Module[{token, owner, repo, maxItems, resp, items},
    token = iAccessToken[];
    If[FailureQ[token], Return[token]];
    owner = iResolveOwner[token, OptionValue[Owner], packageName];
    If[FailureQ[owner], Return[owner]];
    repo = iIssueRepoName[packageName, OptionValue[Repository]];
    If[FailureQ[repo], Return[repo]];
    maxItems = Replace[OptionValue[MaxItems], Except[_Integer?Positive] -> 50];
    resp = iAPICall["GET",
      "repos/" <> owner <> "/" <> repo <> "/issues", token, None,
      <|"state" -> ToString[OptionValue["State"]],
        "per_page" -> ToString[Min[maxItems, 100]]|>];
    If[FailureQ[resp], Return[resp]];
    items = Select[Replace[resp["Body"], Except[_List] -> {}], AssociationQ];
    If[!TrueQ[OptionValue["IncludePullRequests"]],
      items = Select[items, !KeyExistsQ[#, "pull_request"] &]];
    iIssueNormalize[#, packageName, owner, repo] & /@ Take[items, UpTo[maxItems]]
  ];

Options[GitHubIssueGet] = {Owner -> Automatic, Repository -> Automatic};

GitHubIssueGet[packageName_String, number_Integer, opts:OptionsPattern[]] :=
  Module[{token, owner, repo, resp},
    token = iAccessToken[];
    If[FailureQ[token], Return[token]];
    owner = iResolveOwner[token, OptionValue[Owner], packageName];
    If[FailureQ[owner], Return[owner]];
    repo = iIssueRepoName[packageName, OptionValue[Repository]];
    If[FailureQ[repo], Return[repo]];
    resp = iAPICall["GET",
      "repos/" <> owner <> "/" <> repo <> "/issues/" <> ToString[number], token];
    If[FailureQ[resp], Return[resp]];
    If[!AssociationQ[resp["Body"]],
      Return[iFailure["IssueParseFailed", "Issue 応答を解釈できませんでした。",
        <|"Package" -> packageName, "Number" -> number|>]]];
    iIssueNormalize[resp["Body"], packageName, owner, repo]
  ];

Options[GitHubIssueComments] = {
  Owner -> Automatic, Repository -> Automatic, MaxItems -> 50
};

GitHubIssueComments[packageName_String, number_Integer, opts:OptionsPattern[]] :=
  Module[{token, owner, repo, maxItems, resp, items},
    token = iAccessToken[];
    If[FailureQ[token], Return[token]];
    owner = iResolveOwner[token, OptionValue[Owner], packageName];
    If[FailureQ[owner], Return[owner]];
    repo = iIssueRepoName[packageName, OptionValue[Repository]];
    If[FailureQ[repo], Return[repo]];
    maxItems = Replace[OptionValue[MaxItems], Except[_Integer?Positive] -> 50];
    resp = iAPICall["GET",
      "repos/" <> owner <> "/" <> repo <> "/issues/" <> ToString[number] <> "/comments",
      token, None, <|"per_page" -> ToString[Min[maxItems, 100]]|>];
    If[FailureQ[resp], Return[resp]];
    items = Select[Replace[resp["Body"], Except[_List] -> {}], AssociationQ];
    Map[Function[c, <|
      "Author" -> Lookup[Replace[Lookup[c, "user", <||>],
        Except[_Association] -> <||>], "login", ""],
      "AuthorAssociation" -> Replace[Lookup[c, "author_association", ""],
        Except[_String] -> ""],
      "Body" -> Replace[Lookup[c, "body", ""], Except[_String] -> ""],
      "CreatedAt" -> Replace[Lookup[c, "created_at", ""], Except[_String] -> ""],
      "URL" -> Replace[Lookup[c, "html_url", ""], Except[_String] -> ""]|>],
      Take[items, UpTo[maxItems]]]
  ];

GitHubIssueAuthorProfile[login_String] :=
  Module[{token, resp, b},
    token = iAccessToken[];
    If[FailureQ[token], Return[token]];
    resp = iAPICall["GET", "users/" <> login, token];
    If[FailureQ[resp], Return[resp]];
    b = Replace[resp["Body"], Except[_Association] -> <||>];
    <|"Login" -> Lookup[b, "login", login],
      "Name" -> Replace[Lookup[b, "name", ""], Except[_String] -> ""],
      "CreatedAt" -> Replace[Lookup[b, "created_at", ""], Except[_String] -> ""],
      "Followers" -> Replace[Lookup[b, "followers", 0], Except[_Integer] -> 0],
      "Following" -> Replace[Lookup[b, "following", 0], Except[_Integer] -> 0],
      "PublicRepos" -> Replace[Lookup[b, "public_repos", 0], Except[_Integer] -> 0],
      "Bio" -> Replace[Lookup[b, "bio", ""], Except[_String] -> ""],
      "Company" -> Replace[Lookup[b, "company", ""], Except[_String] -> ""],
      "HTMLURL" -> Replace[Lookup[b, "html_url", ""], Except[_String] -> ""]|>
  ];

Options[GitHubIssueAddComment] = {Owner -> Automatic, Repository -> Automatic};

GitHubIssueAddComment[packageName_String, number_Integer, body_String,
  opts:OptionsPattern[]] :=
  Module[{token, owner, repo, resp, b},
    If[StringTrim[body] === "",
      Return[iFailure["EmptyCommentBody", "コメント本文が空です。"]]];
    token = iAccessToken[];
    If[FailureQ[token], Return[token]];
    owner = iResolveOwner[token, OptionValue[Owner], packageName];
    If[FailureQ[owner], Return[owner]];
    repo = iIssueRepoName[packageName, OptionValue[Repository]];
    If[FailureQ[repo], Return[repo]];
    resp = iAPICall["POST",
      "repos/" <> owner <> "/" <> repo <> "/issues/" <> ToString[number] <> "/comments",
      token, <|"body" -> body|>];
    If[FailureQ[resp], Return[resp]];
    b = Replace[resp["Body"], Except[_Association] -> <||>];
    <|"URL" -> Replace[Lookup[b, "html_url", ""], Except[_String] -> ""],
      "Id" -> Replace[Lookup[b, "id", 0], Except[_Integer] -> 0],
      "CreatedAt" -> Replace[Lookup[b, "created_at", ""], Except[_String] -> ""]|>
  ];

(* 管理下リポジトリの列挙: GithubRepositories/ ミラー (内部フォルダ "_*" を除く)
   と repo_database.json キーの和集合。ローカル情報のみ (ネットワーク不使用)。 *)
GitHubManagedRepositories[] :=
  Module[{db, mirrorRoot, mirrorNames, pkgs},
    db = Replace[Quiet @ iLoadRepoDB[], Except[_Association] -> <||>];
    mirrorRoot = FileNameJoin[{iPackageDirectory[], "GithubRepositories"}];
    mirrorNames = If[DirectoryQ[mirrorRoot],
      Select[FileNameTake[#, -1] & /@ Select[FileNames["*", mirrorRoot], DirectoryQ],
        !StringStartsQ[#, "_"] &],
      {}];
    pkgs = Sort @ DeleteDuplicates @ Join[mirrorNames, Keys[db]];
    Map[Function[pkg, <|
      "Package" -> pkg,
      "Repository" -> GitHubRepoDBLookup[pkg],
      "Owner" -> Lookup[Replace[Lookup[db, pkg, <||>],
        Except[_Association] -> <||>], "owner", Automatic]|>],
      pkgs]
  ];

Options[GitHubAllOpenIssues] = {MaxItems -> 50, "IncludePullRequests" -> False};

GitHubAllOpenIssues[opts:OptionsPattern[]] :=
  Module[{repos, errors = {}, issues},
    repos = GitHubManagedRepositories[];
    If[!ListQ[repos], Return[repos]];
    issues = Flatten @ Map[
      Function[r, Module[{ls},
        (* Repository は Automatic のまま iIssueRepoName に検証させる
           (非 ASCII 未登録名はネットワークに触れず Failure -> Errors 行き) *)
        ls = GitHubListIssues[r["Package"],
          Owner -> Replace[Lookup[r, "Owner", Automatic], Except[_String] -> Automatic],
          MaxItems -> OptionValue[MaxItems],
          "IncludePullRequests" -> OptionValue["IncludePullRequests"]];
        Which[
          FailureQ[ls],
            AppendTo[errors, <|"Package" -> r["Package"], "Failure" -> ls|>]; {},
          ListQ[ls], ls,
          True, {}]]],
      repos];
    <|"Issues" -> issues, "RepoCount" -> Length[repos], "Errors" -> errors|>
  ];

End[];
EndPackage[];

(* SourceVault PromptRouter 連携 (Hybrid A): ClaudeOrchestrator がロード済みなら
   PackageCommitPlan を ReadOnly FunctionRoute handler として登録する (弱呼び出し、未ロードは no-op)。
   これにより SourceVaultCallableAllowlistView のマージビューに現れ、FunctionRoute 解決の対象になる。
   駆動関数 PackageCommit (副作用) は WorkflowRoute 扱いなのでここでは登録しない。 *)
If[Length[Names["ClaudeOrchestrator`ClaudeWorkflowRegisterHandler"]] > 0,
  Quiet @ Check[
    ClaudeOrchestrator`ClaudeWorkflowRegisterHandler["PackageCommitPlan",
      <|"Symbol"             -> GitHubREST`PackageCommitPlan,
        "UseAsFunctionRoute" -> True, "UseAsHandlerRef" -> True,
        "SideEffectClass"    -> "ReadOnly", "OwnerPackage" -> "github"|>],
    Null]];

(* NBAccess trusted-head 登録: GitHubCommitLog / GitHubListCommits は
   コミット履歴の読み取り専用取得で、リポジトリへの書き込み・削除を
   一切伴わない。「履歴を読むだけの関数に承認は不要」という方針のもと、
   ClaudeEval の提案コードから AutoPermit で実行できるよう trusted head に
   登録する (コミット・PR 等の書き込み系 GitHub* は従来どおり承認対象)。 *)
If[Length[Names["NBAccess`$NBTrustedPackageHeads"]] > 0,
  (* 2026-08-06: NBAccess 管理変数への直接書換えをやめ、登録 API を通す *)
  Quiet @ Check[
    NBAccess`NBRegisterTrustedPackageHeads["GitHubREST`",
      (* GitHubServiceStatus は公開ステータスページの GET のみで、
         リポジトリにも api.github.com にも触れない (トークン不使用)。
         GitHubListIssues 以下の Issue 系は GET のみの読み取り専用
         (Issue 本文は未信頼データとして SourceVault_issues 側で
         pre-scan されるため、取得自体は承認不要)。 *)
      {"GitHubCommitLog", "GitHubListCommits", "GitHubServiceStatus",
       "GitHubListIssues", "GitHubIssueGet", "GitHubIssueComments",
       "GitHubIssueAuthorProfile", "GitHubManagedRepositories",
       "GitHubAllOpenIssues"}],
    Null]];
