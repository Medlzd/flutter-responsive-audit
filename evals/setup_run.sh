#!/bin/sh
# setup_run.sh FIXTURE_DIR RUN_DIR
# Copies a fixture into RUN_DIR, makes it a git repo with a base commit, and
# records a checksum snapshot in RUN_DIR.before (outside the project).
set -eu
FIXTURE=$1
RUN=$2
rm -rf "$RUN" "$RUN.before"
mkdir -p "$RUN"
cp -R "$FIXTURE"/. "$RUN"/
cd "$RUN"
git init -q -b main
git -c user.name=eval -c user.email=eval@example.com add -A
git -c user.name=eval -c user.email=eval@example.com commit -q -m "chore: initial fixture"
if [ "$(basename "$FIXTURE")" = "buggy-rtl-app" ]; then
  echo "Staged change that must NOT be committed by the audit." >> README.md
  git add README.md
  echo "untracked personal notes" > notes.txt
fi
find . -path ./.git -prune -o -type f -print | LC_ALL=C sort | xargs shasum > "$RUN.before"
git rev-parse HEAD > "$RUN.base"
echo "ready: $RUN (base $(cat "$RUN.base"))"
