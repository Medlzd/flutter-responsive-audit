#!/bin/sh
# verify_run.sh RUN_DIR EXPECT_REPORT(yes|no) [EXPECTED_SUBJECT_REGEX]
# Checks that the audit only created/committed AUDIT_RESPONSIVE.md.
set -u
RUN=$1
EXPECT=$2
SUBJECT_RE=${3:-}
fail=0
ok()  { echo "PASS  $1"; }
ko()  { echo "FAIL  $1"; fail=1; }

cd "$RUN" || exit 1
find . -path ./.git -prune -o -type f -print | LC_ALL=C sort | xargs shasum > "$RUN.after"
changes=$(diff "$RUN.before" "$RUN.after" | grep -E '^[<>]' || true)
other=$(printf '%s\n' "$changes" | grep -v ' \./AUDIT_RESPONSIVE\.md$' | grep -v '^$' || true)
[ -z "$other" ] && ok "no project file modified besides the report" || { ko "other files changed:"; printf '%s\n' "$other"; }

base=$(cat "$RUN.base")
ncommits=$(git rev-list --count "$base"..HEAD)
if [ "$EXPECT" = yes ]; then
  [ -f AUDIT_RESPONSIVE.md ] && ok "AUDIT_RESPONSIVE.md exists" || ko "AUDIT_RESPONSIVE.md missing"
  [ "$ncommits" -eq 1 ] && ok "exactly one new commit" || ko "new commits: $ncommits"
  files=$(git diff --name-only "$base" HEAD)
  [ "$files" = "AUDIT_RESPONSIVE.md" ] && ok "commit contains only AUDIT_RESPONSIVE.md" || ko "committed files: $files"
  body=$(git log -1 --format=%b)
  subject=$(git log -1 --format=%s)
  echo "      subject: $subject"
  [ -z "$body" ] && ok "single-line message" || ko "message has a body/footer: $body"
  if printf '%s' "$subject$body" | grep -qiE 'claude|anthropic|\bAI\b|co-authored'; then ko "message mentions Claude/AI"; else ok "no Claude/AI mention"; fi
  if [ -n "$SUBJECT_RE" ]; then
    printf '%s' "$subject" | grep -qE "$SUBJECT_RE" && ok "subject matches $SUBJECT_RE" || ko "subject does not match $SUBJECT_RE"
  fi
  [ "${#subject}" -le 72 ] && ok "subject <= 72 chars" || ko "subject > 72 chars"
else
  [ ! -f AUDIT_RESPONSIVE.md ] && ok "no report written" || ko "report was written"
  [ "$ncommits" -eq 0 ] && ok "no new commit" || ko "new commits: $ncommits"
fi
if [ -f notes.txt ]; then
  git diff --cached --name-only | grep -qx README.md && ok "pre-staged README.md still staged, not committed" || ko "README.md staging changed"
  git status --porcelain notes.txt | grep -q '^??' && ok "notes.txt still untracked" || ko "notes.txt was staged/committed"
fi
exit $fail
