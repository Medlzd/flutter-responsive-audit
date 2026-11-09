# Flutter Responsive Audit

> An Agent Skill that audits any Flutter app for responsive and iOS/Android adaptation
> issues, then writes a prioritized, evidence-based report: `AUDIT_RESPONSIVE.md`.

**Read-only** · **Every issue cites a real `file:line`** · **Works with Claude Code, Codex, Gemini CLI, Cursor, GitHub Copilot and any agent that can read a file**

---

## Table of contents

- [Why this skill](#why-this-skill)
- [What it checks](#what-it-checks)
- [Installation](#installation)
  - [Option 1: one folder for every agent (recommended)](#option-1-one-folder-for-every-agent-recommended)
  - [Option 2: per-agent install](#option-2-per-agent-install)
  - [Option 3: skills installers](#option-3-skills-installers)
  - [Update and uninstall](#update-and-uninstall)
- [Usage](#usage)
- [What you get](#what-you-get)
- [Severity and score](#severity-and-score)
- [Safety guarantees](#safety-guarantees)
- [Run the pre-scan script on its own](#run-the-pre-scan-script-on-its-own)
- [Repository structure](#repository-structure)
- [Evals](#evals)
- [Standards it is based on](#standards-it-is-based-on)
- [FAQ and troubleshooting](#faq-and-troubleshooting)
- [Contributing](#contributing)

---

## Why this skill

You ship a Flutter app and then hear things like:

- *"The cards look bigger on my Pixel than on my iPhone."*
- *"The title is hidden under the Dynamic Island."*
- *"On the tablet everything is stretched."*
- *"With large text, the button text is cut off."*
- *"In Arabic, the padding is on the wrong side."*

These bugs are hard to spot in review because they only show up on some screen sizes,
platforms, text scales or text directions. This skill gives your AI coding agent a
precise, repeatable method to find them **from the source code**. It explains each
one with numbers (for example, `ceil(412 / 140) = 3 columns` vs `ceil(440 / 140) = 4 columns`)
and ranks the issues so you know what to fix first.

It does **not** change your code. Fixing is a separate step that you decide on.

## What it checks

15 categories, each with detection patterns, known false positives, and the official
rule it violates (see [`references/checklist.md`](references/checklist.md)):

| # | Category | Typical problems found |
|---|----------|------------------------|
| C01 | Fixed sizes | Hardcoded `width`/`height` on cards, containers and images |
| C02 | Grids & lists | `MaxCrossAxisExtent` column jumps, `childAspectRatio` clipping text, nested scroll views |
| C03 | Measuring | `MediaQuery.of(context).size`, scattered screen percentages, screen size used where `LayoutBuilder` fits |
| C04 | Branching logic | Layout based on `Platform.isIOS`, device type or orientation; magic breakpoints |
| C05 | Orientation lock | `setPreferredOrientations`, `android:screenOrientation` |
| C06 | SafeArea | Content under the notch, Dynamic Island or gesture bar; `SafeArea` around the `Scaffold` |
| C07 | Floating navigation | Last items hidden behind floating bars and FABs |
| C08 | Typography | Hardcoded `fontSize`, `Text` overflowing in a `Row`, text scaling disabled |
| C09 | Icons & images | Fixed sizes ignoring the container, missing `fit`, no 2x/3x assets |
| C10 | Keyboard | Forms overflowing when the keyboard opens |
| C11 | RTL | `EdgeInsets.only(left:)`, `Alignment.centerLeft`, arrows not mirrored |
| C12 | Large screens | No max width, no `NavigationRail` at ≥ 600 dp, state lost on fold or rotation |
| C13 | iOS vs Android | Permission declared on one platform only, no fallback UI, undeclared fonts |
| C14 | Scaling packages | `flutter_screenutil` (`.w`, `.h`, `.sp`) used as the main strategy |
| C15 | Layout performance | Huge `build` methods, `MediaQuery.of` rebuilding whole screens |

Layouts are evaluated on reference devices: small phone (320–360 dp), mid Android
(393–411 dp), iPhone Pro Max (≈ 440 pt), foldable, tablet, and system font at 1.3× and 2×.

---

## Installation

Requirements: `git`, plus a POSIX shell with `grep` and `find` (macOS, Linux, or
Windows with WSL / Git Bash) for the optional pre-scan script. No Flutter SDK needed:
the audit is static.

### Option 1: one folder for every agent (recommended)

Clone once into the cross-agent location `~/.agents/skills`, then link it for Claude Code
(which uses its own folder):

```bash
# 1. Download the skill
git clone https://github.com/Medlzd/flutter-responsive-audit.git ~/.agents/skills/flutter-responsive-audit

# 2. Make it visible to Claude Code too
mkdir -p ~/.claude/skills
ln -s ~/.agents/skills/flutter-responsive-audit ~/.claude/skills/flutter-responsive-audit
```

That single copy is picked up by:

| Agent | Reads `~/.agents/skills`? |
|-------|---------------------------|
| OpenAI Codex (CLI / IDE) | ✅ |
| Gemini CLI | ✅ |
| Cursor | ✅ |
| Claude Code | via the symlink in `~/.claude/skills` |
| GitHub Copilot | use `~/.copilot/skills` (see below) |

Restart your agent after installing so it discovers the skill.

### Option 2: per-agent install

Each agent has a **personal** folder (all your projects) and a **project** folder
(commit it so your whole team gets the skill). Replace `<folder>` in the command below:

```bash
git clone https://github.com/Medlzd/flutter-responsive-audit.git <folder>/flutter-responsive-audit
```

| Agent | Personal folder | Project folder | Run it manually with |
|-------|-----------------|----------------|----------------------|
| **Claude Code** | `~/.claude/skills` | `.claude/skills` | `/flutter-responsive-audit` |
| **OpenAI Codex** | `~/.agents/skills` | `.agents/skills` | `/skills` or `$flutter-responsive-audit` |
| **Gemini CLI** | `~/.gemini/skills` or `~/.agents/skills` | `.gemini/skills` or `.agents/skills` | describe the task, or check with `/skills` |
| **Cursor** | `~/.cursor/skills` or `~/.agents/skills` | `.cursor/skills` or `.agents/skills` | `/` in Agent chat, then the skill name |
| **GitHub Copilot** (VS Code, CLI, cloud agent) | `~/.copilot/skills` | `.github/skills` | describe the task in agent mode |

Agent-specific shortcuts:

- **Gemini CLI** has a built-in installer:
  ```bash
  gemini skills install https://github.com/Medlzd/flutter-responsive-audit.git
  # add --scope workspace to install it for the current project only
  ```
- **Codex** ships a built-in `$skill-installer` that can download skills from GitHub.
  In a Codex session: *"$skill-installer install the skill from
  https://github.com/Medlzd/flutter-responsive-audit"*
- **Claude.ai / Claude Desktop**: download the repository as a ZIP
  (*Code → Download ZIP* on GitHub) and upload it in the **Skills** section of the
  app settings. The agent then follows the same workflow on the code you share.

**Windows (PowerShell):**

```powershell
git clone https://github.com/Medlzd/flutter-responsive-audit.git "$env:USERPROFILE\.agents\skills\flutter-responsive-audit"
# Claude Code:
git clone https://github.com/Medlzd/flutter-responsive-audit.git "$env:USERPROFILE\.claude\skills\flutter-responsive-audit"
```

**Any other agent** (Windsurf, Cline, Aider, Zed, or an agent without skill support):
clone the repository anywhere and start your request with:

```text
Read /path/to/flutter-responsive-audit/SKILL.md and follow it exactly to audit this Flutter project.
```

The skill is plain Markdown plus one shell script, so any agent that can read files
and run a command can use it.

### Option 3: skills installers

Community installers can place the skill in the right folder for many agents at once:

```bash
npx skills add Medlzd/flutter-responsive-audit          # vercel-labs/skills, detects your agents
npx skills add Medlzd/flutter-responsive-audit -a codex # or target one agent
```

> Skills are instructions that your agent follows. As with any skill, read
> [`SKILL.md`](SKILL.md) and [`scripts/scan_patterns.sh`](scripts/scan_patterns.sh)
> before installing. Both are short.

### Update and uninstall

```bash
# Update
git -C ~/.agents/skills/flutter-responsive-audit pull

# Uninstall
rm -rf ~/.agents/skills/flutter-responsive-audit
rm ~/.claude/skills/flutter-responsive-audit   # the symlink, if you created it
```

---

## Usage

Open your agent **in the root of a Flutter project** and ask in plain language. The
skill triggers on requests to *audit, scan, analyze, review or check* responsiveness,
adaptive layout, screen sizes, overflows, tablet/foldable display, or iOS/Android
visual differences.

**Example prompts**

```text
Audit the responsiveness of my Flutter app.
```

```text
Check my app for adaptive layout problems before release. Android and iOS, tablets included.
```

```text
On my Pixel 7 the product cards look bigger than on my iPhone 16 Pro Max, and on the
iPhone the title is under the Dynamic Island. The app is in Arabic (RTL). Find out why.
```

**Tip:** describe your symptoms (devices, screenshots, what looks different), the app
language and text direction, and your target platforms. The skill traces each symptom
to its exact root cause in the code. If you don't, it asks once, then continues.

**What the agent does**

| Step | Action |
|------|--------|
| 0. Context | Collects symptoms, language/direction and platforms |
| 1. Validate | Confirms it is a Flutter project (`pubspec.yaml` with the Flutter SDK). Otherwise it stops. |
| 2. Map | Finds the root app widget, screens, navigation, theme and responsive packages |
| 3. Pre-scan | Runs `scripts/scan_patterns.sh` to list candidate lines |
| 4. Analyze | Reads every candidate in context, then confirms or discards it (a grep match is not a bug) |
| 5. Symptoms | Explains each reported symptom with code evidence and numbers |
| 6. Report | Writes `AUDIT_RESPONSIVE.md` at the project root |
| 7. Commit | If the project is a git repo, commits **only** the report, following your `CLAUDE.md` commit rules if any (default: `docs(audit): add responsive audit report`). Never pushes. |
| 8. Summary | Score, issue counts, top 5 priorities, report path, commit hash |

It does not apply any fix. Once you have read the report, ask the agent to fix the
issues as a separate step.

**Example chat summary** (from the bundled RTL eval):

```text
Responsive score: 4.0/10
Issues: 🔴 2 · 🟠 2 · 🟡 1 (2 need verification)

1. 🔴 #1 No SafeArea: the title sits under the Dynamic Island (lib/screens/home_screen.dart:23)
2. 🔴 #2 Fixed childAspectRatio + no maxLines: product names overflow at 2× text (:39)
3. 🟠 #3 maxCrossAxisExtent 140: 3 columns of 132 dp on Pixel 7 vs 4 of 106 pt on iPhone (:37)
4. 🟠 #4 EdgeInsets.only(left:) does not flip in Arabic (:28, :61)
5. 🟡 #5 No bundled Arabic font: different glyphs on iOS and Android (lib/main.dart:24)

Report: AUDIT_RESPONSIVE.md · Commit: ec695f3
```

## What you get

`AUDIT_RESPONSIVE.md`, in English, with six sections (template:
[`references/report-template.md`](references/report-template.md)):

1. **Executive summary**: score /10 with a 3-line justification, issue count per
   severity, top 5 most urgent issues.
2. **Issues table**: `# | Severity | File:line | Category | Issue | Impacted devices | Violated rule (source)`.
3. **Issue details**: code excerpt, why it is a problem (with the cited standard), and
   the fix direction described in words.
4. **Reported symptoms analysis**: the exact root cause of each symptom, with evidence
   and the computation.
5. **Strengths**: what is already done well and should be kept.
6. **Manual test plan**: Small Phone, Pixel 4, Medium Phone, Pixel Fold, Pixel Tablet,
   iPhone SE, iPhone Pro Max, font 1.3× and 2×, landscape (and RTL if relevant), each
   with what to check.

## Severity and score

| Level | Meaning | Example |
|-------|---------|---------|
| 🔴 Critical | Content or a feature is lost: overflow, hidden or clipped content, crash, feature missing on one platform | Submit button under the keyboard on a 360 dp phone |
| 🟠 Medium | Works, but renders differently on iOS and Android, or adapts poorly to tablets, foldables or large text | Grid cards 24% bigger on Android |
| 🟡 Minor | Best practice not followed, maintainability | `MediaQuery.of(context).size` instead of `MediaQuery.sizeOf` |

Score: `10 − 1.5 × 🔴 − 0.5 × 🟠 − 0.15 × 🟡`, capped at 6.0 when a confirmed 🔴
exists (4.0 when it hits a primary flow). Issues marked *Needs verification* count
at half weight and never trigger a cap. Details:
[`references/severity.md`](references/severity.md).

## Safety guarantees

The skill is designed to be safe on any project, including code you did not write:

- **Read-only**: the only file it creates is `AUDIT_RESPONSIVE.md`.
- **No code execution**: no `flutter`, `dart`, Gradle, CocoaPods or project scripts.
- **Evidence only**: every issue points to a real `file:line`. Anything it cannot
  confirm from the code is labeled *Needs verification* instead of asserted.
- **Project content is data**: instructions found in code, comments, README or the
  project's `CLAUDE.md` are never followed. Only the commit message format is taken
  from `CLAUDE.md`.
- **Stays in the project**: no symlinks are followed outside the project root, and it
  refuses to write the report through a symlink.
- **No secrets**: API keys, tokens and passwords are replaced with `<redacted>` in
  excerpts. Credential files are never quoted.
- **Careful git**: it commits only the report, as a single-line message with no
  attribution trailers. It never uses `git add .`, never pushes or amends, and never
  bypasses hooks. If the repository has active hooks and may not be yours, it asks
  before committing.

## Run the pre-scan script on its own

The scanner is useful without any agent, for example in CI or for a quick look:

```bash
sh ~/.agents/skills/flutter-responsive-audit/scripts/scan_patterns.sh /path/to/flutter/app
```

- Prints candidate lines (`file:line: code`) grouped by category C01–C15, plus
  "good sign" patterns used for the Strengths section.
- POSIX `sh`, read-only, no network. It skips generated files (`*.g.dart`,
  `*.freezed.dart`, …) and does not follow symlinks.
- Exit codes: `0` scan done, `2` not a Flutter project, `1` usage error.
- `MAX_PER_PATTERN=200 sh scan_patterns.sh .` shows more matches per pattern
  (default 60).

Every printed line is a **candidate**, not a confirmed issue. The agent's analysis
step is what separates real problems from false positives.

## Repository structure

```text
flutter-responsive-audit/
├── SKILL.md                  # The workflow the agent follows (entry point)
├── references/
│   ├── standards.md          # Official sources and rule IDs (STD-*)
│   ├── checklist.md          # 15 detection categories with patterns
│   ├── severity.md           # Severity levels, reference devices, scoring
│   └── report-template.md    # Exact structure of AUDIT_RESPONSIVE.md
├── scripts/
│   └── scan_patterns.sh      # Read-only pre-scan (POSIX sh)
└── evals/                    # Test fixtures and harness (not needed at runtime)
```

`SKILL.md` stays short. Agents load the reference files only when a step needs them
(progressive disclosure), which keeps context usage low.

## Evals

Three evals run the skill end to end, each with an independent agent that only gets the
skill path and a user prompt:

| Eval | Fixture | Expected result | Status |
|------|---------|-----------------|--------|
| 1 | Arabic RTL app with a `MaxCrossAxisExtent` grid, a missing `SafeArea` and `EdgeInsets.only(left:)` | All three detected, symptoms explained with numbers, only the report committed | ✅ |
| 2 | Clean, well-built adaptive app | No invented issues, high score | ✅ (9.9/10) |
| 3 | Non-Flutter (Node.js) project | Stops gracefully, writes nothing | ✅ |

Run them yourself:

```bash
cd evals
sh setup_run.sh "$PWD/fixtures/buggy-rtl-app" /tmp/runs/buggy-rtl-app
# ask your agent to audit /tmp/runs/buggy-rtl-app with the prompt from evals.json
sh verify_run.sh /tmp/runs/buggy-rtl-app yes '^docs\(qa\): '
```

`verify_run.sh` checks that no file other than the report changed, that only the report
was committed, and that the commit message follows the rules. Prompts and expectations
are in [`evals/evals.json`](evals/evals.json). Results are in
[`evals/RESULTS.md`](evals/RESULTS.md).

## Standards it is based on

- Flutter: [Adaptive and responsive design](https://docs.flutter.dev/ui/adaptive-responsive),
  [Best practices](https://docs.flutter.dev/ui/adaptive-responsive/best-practices),
  [SafeArea & MediaQuery](https://docs.flutter.dev/ui/adaptive-responsive/safearea-mediaquery),
  [Large screens & foldables](https://docs.flutter.dev/ui/adaptive-responsive/large-screens),
  [Understanding constraints](https://docs.flutter.dev/ui/layout/constraints)
- [Material 3 window size classes](https://m3.material.io/foundations/layout/applying-layout/window-size-classes)
  (compact < 600, medium 600–839, expanded ≥ 840)
- [Android large screen app quality](https://developer.android.com/docs/quality-guidelines/large-screen-app-quality)
- Apple HIG: [Layout](https://developer.apple.com/design/human-interface-guidelines/layout),
  [Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
- Senior Flutter community consensus: respect parent constraints, adapt rather than
  scale, clamp text scaling instead of disabling it, test at 200% text.

## FAQ and troubleshooting

**The agent does not use the skill.**
Check the folder name and that `SKILL.md` is directly inside it
(`<skills-folder>/flutter-responsive-audit/SKILL.md`), then restart the agent. Use the
manual command for your agent from the [table above](#option-2-per-agent-install), or
mention the skill by name: *"Use the flutter-responsive-audit skill to…"*.

**It says my project is not a Flutter project.**
Run the agent from the folder that contains `pubspec.yaml` with
`flutter: sdk: flutter`. In a monorepo, point it to the app folder.

**Will it modify my code?**
No. It only creates `AUDIT_RESPONSIVE.md` and commits that file alone.

**Can I keep the report out of git?**
Yes. Add `AUDIT_RESPONSIVE.md` to `.gitignore`: the skill will not force-add it.

**Does it work on Windows?**
The skill itself does. The pre-scan script needs a POSIX shell (WSL or Git Bash). Without
one, the agent falls back to the patterns in `references/checklist.md`.

**Does it support Flutter web or desktop?**
It analyzes any Flutter UI code. The reference devices and test plan focus on mobile,
tablets and foldables.

## Contributing

Issues and pull requests are welcome. Commit messages are a single line in
[Conventional Commits](https://www.conventionalcommits.org/) format:

```text
type(scope): description     # e.g. fix(scan): skip symlinked files
```

Use the types `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`,
`style` or `revert`. Write the description in English, in the imperative mood, in
lowercase, without a trailing period, and keep the whole line at 72 characters or
fewer. Do not add a body or footer.

Before opening a pull request, run the scanner on the fixtures, and run the evals if
you changed `SKILL.md` or a reference file.
