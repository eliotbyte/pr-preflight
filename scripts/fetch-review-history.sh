#!/usr/bin/env bash
# Download a GitHub repository's review history for building a review profile.
#
#   fetch-review-history.sh <owner/repo> <out-dir>
#       Downloads PRs, code review comments and PR conversation comments, and prints who reviews
#       other people's PRs most.
#   fetch-review-history.sh <owner/repo> <out-dir> <logins> [holdout-prs]
#       Also writes reviewer_comments.txt: the given reviewers' comments on PRs they didn't author,
#       newest first, leaving out the comma-separated holdout PRs kept back for calibration.
#
# Needs an authenticated GitHub CLI (`gh auth status`). Raw files go to <out-dir>; delete it once
# the profile is written: the profile keeps rules and PR links, not the comments.
set -euo pipefail

repo=${1:?usage: fetch-review-history.sh <owner/repo> <out-dir> [logins] [holdout-prs]}
out=${2:?usage: fetch-review-history.sh <owner/repo> <out-dir> [logins] [holdout-prs]}
logins=${3:-}
holdout=${4:-}
mkdir -p "$out"

clean='(.body // "" | gsub("\r"; "") | gsub("\t"; " ") | gsub("\n"; " / "))'

if [ ! -s "$out/pulls.tsv" ]; then
  gh api --paginate "repos/$repo/pulls?state=all&per_page=100" \
    --jq '.[] | [.number, .user.login, (if .merged_at then "merged" else .state end), .created_at[:10], .title] | @tsv' \
    > "$out/pulls.tsv"
  gh api --paginate "repos/$repo/pulls/comments?per_page=100" \
    --jq ".[] | [(.pull_request_url | split(\"/\") | last), .user.login, .created_at[:10], .path, (.line // .original_line // \"\"), $clean] | @tsv" \
    > "$out/review_comments.tsv"
  gh api --paginate "repos/$repo/issues/comments?per_page=100" \
    --jq ".[] | [(.issue_url | split(\"/\") | last), .user.login, .created_at[:10], $clean] | @tsv" \
    > "$out/conversation_comments.tsv"
fi

echo "PRs: $(wc -l < "$out/pulls.tsv"), code comments: $(wc -l < "$out/review_comments.tsv"), conversation comments: $(wc -l < "$out/conversation_comments.tsv")"
echo
echo "Code review comments on other people's PRs, by reviewer (bots left out):"
awk -F'\t' 'NR==FNR { author[$1] = $2; next }
  ($1 in author) && $2 != author[$1] && $2 !~ /\[bot\]$/ { n[$2]++; prs[$2 FS $1] = 1 }
  END { for (k in prs) { split(k, a, FS); p[a[1]]++ }
        for (u in n) printf "  %-24s %5d comments in %4d PRs\n", u, n[u], p[u] }' \
  "$out/pulls.tsv" "$out/review_comments.tsv" | sort -k2 -nr | head -15

[ -n "$logins" ] || exit 0

awk -F'\t' -v logins="$logins" -v holdout="$holdout" '
  BEGIN { n = split(logins, l, ","); for (i = 1; i <= n; i++) who[l[i]] = 1
          n = split(holdout, h, ","); for (i = 1; i <= n; i++) skip[h[i]] = 1 }
  FILENAME ~ /pulls.tsv$/ { author[$1] = $2; state[$1] = $3; next }
  ($2 in who) && ($1 in author) && author[$1] != $2 && !($1 in skip) {
    if (FILENAME ~ /review_comments/) print $3 "\t#" $1 " (" state[$1] ") " $4 ":" $5 " [" $2 "]: " substr($6, 1, 600)
    else                              print $3 "\t#" $1 " (" state[$1] ") conversation [" $2 "]: " substr($4, 1, 600)
  }' "$out/pulls.tsv" "$out/review_comments.tsv" "$out/conversation_comments.tsv" \
  | sort -r | cut -f2- > "$out/reviewer_comments.txt"

echo
echo "Wrote $(wc -l < "$out/reviewer_comments.txt") comments by $logins to $out/reviewer_comments.txt"
[ -z "$holdout" ] || echo "Held out for calibration: $holdout"
