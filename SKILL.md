---
name: flutter-responsive-audit
description: Audits a Flutter app (read-only analysis, no code changes) for responsive and iOS/Android adaptation issues and produces a prioritized AUDIT_RESPONSIVE.md report.
---

# Flutter Responsive Audit

Read-only audit of a Flutter app's responsive and adaptive behavior. Produces one
file, `AUDIT_RESPONSIVE.md`, at the project root, written in English.

## When to use

Use when the user asks to **audit, scan, analyze, review or check** a Flutter app for:
responsiveness, adaptive layout, screen sizes, overflows, iOS vs Android visual
differences, tablet / foldable / large-screen display, text scaling, notch / safe areas,
or RTL layout.

Do NOT use when:
- the user wants code **fixed or refactored** (this skill never edits code; offer
  fixes only as a separate step after the audit),
- the project is **not Flutter** (e.g. CSS/web responsiveness, React Native),
- the user asks a **general Flutter question** that does not require auditing a project.

## Absolute rules

1. **Read-only.** Never create, edit, move, format or delete any project file. Do not
   run `dart fix`, `dart format`, `flutter pub get`, `flutter create`, or anything that
   writes to the project. The ONLY file you may create is `AUDIT_RESPONSIVE.md` at the
   project root.
2. **Evidence only.** Every issue cites a real `path/to/file.dart:line` you have read.
   Never invent files, lines, widgets or symptoms.
3. **Uncertainty is explicit.** If you cannot confirm an issue from the code alone,
   keep it and label it `Needs verification` with what must be checked on a device.
4. **No duplicates.** Group identical occurrences of the same issue into one entry and
   list every location.
5. **English** for the report and the chat summary.

## Reference files (load when needed)

| File | Load at | Contains |
|------|---------|----------|
| `references/standards.md` | Step 4 | Official sources and rule IDs (`STD-*`) to cite |
| `references/checklist.md` | Steps 3–4 | 15 categories: what to look for, grep patterns, false positives, violated rule |
| `references/severity.md` | Step 4 | 🔴 🟠 🟡 definitions, reference devices, scoring |
| `references/report-template.md` | Step 6 | Exact structure of `AUDIT_RESPONSIVE.md` |
| `scripts/scan_patterns.sh` | Step 3 | Read-only pre-scan, plain-text output |

## Workflow

### Step 0 — Context

If the user has not already provided it, ask once, in a single message:
- observed symptoms (screenshots, devices/emulators, what looks different or broken),
- app language(s) and text direction (LTR / RTL),
- target platforms (Android, iOS, tablet, foldable, web/desktop).

If there is no answer, continue without it and state in the report that no symptoms
were reported. Infer RTL from `supportedLocales` / `locale` / `Directionality` when
possible (e.g. `ar`, `he`, `fa`, `ur`).

### Step 1 — Validate the project

Confirm `pubspec.yaml` exists at the root AND declares the Flutter SDK dependency:

```yaml
dependencies:
  flutter:
    sdk: flutter
```

If it is missing, or it is a pure Dart package with no `lib/` UI, **stop**: tell the
user this is not a Flutter app, write nothing, commit nothing.

If the user points to a monorepo, find the Flutter app folder(s) and ask which one to
audit if there are several.

### Step 2 — Map the app

Locate and note (with file:line):
- the root widget: `MaterialApp` / `MaterialApp.router` / `CupertinoApp` / `WidgetsApp`,
  its `builder:`, `theme`, `locale`, `supportedLocales`, `localizationsDelegates`;
- `main()`: `SystemChrome` calls, `ScreenUtilInit`, error/orientation setup;
- navigation: `Navigator`, `go_router`, `auto_route`, `BottomNavigationBar`,
  `NavigationBar`, `NavigationRail`, `Drawer`, custom floating bars;
- theme: `ThemeData`, `TextTheme`, custom text styles, fonts declared in `pubspec.yaml`;
- screens: files under `lib/` that return a `Scaffold` / `CupertinoPageScaffold`;
- responsive helpers or packages in `pubspec.yaml` (`flutter_screenutil`,
  `responsive_framework`, `sizer`, `responsive_builder`, `flutter_adaptive_scaffold`,
  custom `Breakpoints` / `isTablet` helpers).

### Step 3 — Pre-scan

Run the scanner from the skill directory against the project root:

```sh
sh <skill-dir>/scripts/scan_patterns.sh <project-root>
```

It is read-only and prints `file:line: code` grouped by category. If it cannot run,
use the patterns in `references/checklist.md` with your search tool. Treat the output
as **candidates**, not findings.

### Step 4 — Analyze

For each candidate, open the file and read enough context (the whole widget, its
parents and the constraints it receives) to decide:
- **Confirmed** → record it with category, severity (`references/severity.md`),
  impacted devices, and the violated rule ID (`references/standards.md`).
- **Discarded** → a grep match is not a bug. Examples: a 24 dp icon, a `SizedBox`
  used as a gap, `MediaQuery.sizeOf` used once at a breakpoint decision, `left:`
  inside a `Positioned.directional` or an LTR-only app.
- **Needs verification** → plausible but depends on runtime data or device.

Also review what grep cannot see: screens built without `SafeArea`, `Row`s of text
without `Expanded`/`Flexible`, forms without scrolling, content without a max width
on large screens, permissions in `AndroidManifest.xml` vs `Info.plist`. Follow the
"Manual review" items of each category in `references/checklist.md`.

### Step 5 — Explain reported symptoms

For each symptom from Step 0, find the exact root cause in code and explain it with
numbers. Reason from concrete widths of the reference devices. Example:

> The product grid uses `SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent:
> 140)` with no spacing (`lib/home/home_screen.dart:42`). Flutter computes
> columns = ceil(width / (maxCrossAxisExtent + crossAxisSpacing)):
> 393 dp → ceil(2.81) = 3 columns of 131 dp; 440 pt → ceil(3.14) = 4 columns of 110 pt.
> The same card is ≈ 19% wider on the Android phone, which is why cards look bigger
> on Android than on the iPhone Pro Max.

Always show the computation. If a symptom cannot be traced to code, say so and list
what you checked.

### Step 6 — Write the report

Load `references/report-template.md`, fill every section, and write
`AUDIT_RESPONSIVE.md` at the project root. Order issues by severity (🔴 → 🟠 → 🟡),
then by number of impacted screens. Compute the score with the rubric in
`references/severity.md`.

### Step 7 — Commit the report (git projects only)

If the project root is inside a git work tree (`git rev-parse --is-inside-work-tree`):
1. Read the project's `CLAUDE.md` (root) if it exists and follow its commit rules
   (message format, scope, sign-off, attribution rules).
2. Fallback message: `docs(audit): add responsive audit report`.
3. Stage **only** the report: `git add -- AUDIT_RESPONSIVE.md`. Never `git add .` or
   `-A`. If other files were already staged by the user, commit with
   `git commit -m "<message>" -- AUDIT_RESPONSIVE.md` so only the report is included.
4. Never push, amend, or bypass hooks (`--no-verify`). If a hook fails, report the
   failure instead of working around it.
5. Record the commit hash (`git rev-parse --short HEAD`).

If it is not a git repository, skip this step and say so.

### Step 8 — Chat summary

Reply with, and nothing more verbose than:
- score `/10`,
- issue count per severity (🔴 / 🟠 / 🟡) and number marked `Needs verification`,
- top 5 priorities (one line each, with file:line),
- report path,
- commit hash (or "not committed: <reason>").

End by offering to fix the issues as a **separate next step**. Do not apply any fix.
