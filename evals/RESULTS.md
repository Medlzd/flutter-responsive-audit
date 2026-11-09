# Eval results

Harness: `setup_run.sh` copies a fixture to a scratch dir, makes it a git repo with a
base commit (eval 1 also has a staged `README.md` change and an untracked `notes.txt`),
and snapshots checksums. An independent agent then runs the skill with only the
skill path and the user prompt. `verify_run.sh` checks files and git state.

## Run 1

| Eval | Result | Notes |
|------|--------|-------|
| 1 buggy-rtl-app | ✅ PASS (11/11 checks) | All 3 planted issues detected (MaxCrossAxisExtent `home_screen.dart:37`, missing SafeArea `:23`, `EdgeInsets.only(left:)` `:28` + `:61` grouped). Symptom math correct (396 dp → 3 cols × 132, 424 pt → 4 cols × 106, grid padding included). 11/11 citations valid. Commit `docs(qa): add responsive audit report` per fixture CLAUDE.md; staged README and untracked notes.txt untouched. Score 4.0/10. |
| 2 clean-app | ❌ FAIL | (a) **Skill bug**: no project CLAUDE.md → agent added the default `Co-Authored-By: Claude` trailer (2 checks failed). (b) **Fixture bug**: the "clean" app had real defects, correctly found (28/28 citations valid, nothing invented): body moved between tree positions at the 600 dp branch (state lost on rotation), fixed `mainAxisExtent: 120` clips at 2× text, horizontal safe-area applied twice with the rail, no `android:configChanges`. Score 4.0 driven by a cap triggered by issues marked Needs verification. |
| 3 node-app | ✅ PASS (3/3 checks) | Stopped at Step 1 (no pubspec.yaml), nothing written, no commit. |

## Fixes after run 1

- `SKILL.md` Step 7: the commit message is exactly one line with no trailers
  (`Co-Authored-By`, "Generated with…") unless the project's `CLAUDE.md` requires them.
- `severity.md`: score caps only apply to **confirmed** 🔴 issues.
- `checklist.md` C12 + `scan_patterns.sh`: detect layout branches that move a subtree
  without a `GlobalKey`, and a missing `android:configChanges`.
- `clean-app` fixture made truly clean: stable body position + `GlobalKey`,
  content-driven tile heights, horizontal insets consumed once, template
  `configChanges`.

## Run 2 (eval 2 only; evals 1 and 3 unaffected by the fixes and not re-run)

| Eval | Result | Notes |
|------|--------|-------|
| 2 clean-app | ✅ PASS (9/9 checks) | 0 🔴, 0 🟠, 1 🟡 (`NavigationRail` without `labelType` → icon-only rail at 600–839 dp, `shell.dart:52`: real, defensible). Score 9.9/10. 27/27 citations valid. Commit `docs(audit): add responsive audit report`, one line, no trailer. |

## Final status

| Eval | Status |
|------|--------|
| 1 buggy-rtl-app | ✅ |
| 2 clean-app | ✅ |
| 3 node-app | ✅ |
