# Report template — `AUDIT_RESPONSIVE.md`

Copy the structure below exactly. Replace every `<…>` placeholder. Keep all six section
headings even when a section is empty (write "None." / "No symptoms were reported.").
Write in English. Never include code changes (no diffs, no rewritten widgets): fixes
are described in words only.

---

```markdown
# Responsive Audit — <App name from pubspec.yaml>

- **Date:** <YYYY-MM-DD>
- **Project root:** `<path>`
- **Flutter constraint:** `<environment.flutter / sdk from pubspec.yaml>`
- **Platforms audited:** <Android, iOS, …>
- **Text direction:** <LTR | RTL | LTR + RTL (locales)>
- **Responsive packages:** <none | flutter_screenutil x.y, …>
- **Scope:** `lib/` (<N> Dart files, generated files excluded), `pubspec.yaml`,
  `AndroidManifest.xml`, `Info.plist`
- **Method:** static analysis only (no code was modified, the app was not run)

## 1. Executive summary

**Responsive score: <X.X>/10**

<Line 1 — biggest risk.>
<Line 2 — overall adaptive strategy.>
<Line 3 — best strength.>

| Severity | Issues |
|----------|--------|
| 🔴 Critical | <n> |
| 🟠 Medium | <n> |
| 🟡 Minor | <n> |
| Needs verification (included above) | <n> |

**Top 5 most urgent**
1. <#id — short title — `file:line`>
2. …
(Fewer than 5 issues → list them all.)

## 2. Issues

| # | Severity | File:line | Category | Issue | Impacted devices | Violated rule (source) |
|---|----------|-----------|----------|-------|------------------|------------------------|
| 1 | 🔴 | `lib/…:42` (+2 more) | C06 SafeArea | <one line> | iPhone Pro Max, Android 15 | STD-SAFE-1 (Flutter: SafeArea & MediaQuery) |
| … | | | | | | |

Rules: sorted 🔴 → 🟠 → 🟡; one row per grouped issue; "(+N more)" when grouped;
add `⚠ Needs verification` in the Issue column when applicable.

## 3. Issue details

### #1 🔴 <Title>

- **Category:** <Cxx name>
- **Locations:**
  - `lib/…/file.dart:42`
  - `lib/…/other.dart:17`
- **Code:**
  ```dart
  <3–10 lines copied verbatim from the first location, with real line context;
   secrets (keys, tokens, passwords) replaced by <redacted>>
  ```
- **Why it is a problem:** <mechanism with numbers on reference devices; cite the
  rule ID and source name + URL>.
- **Impacted devices:** <list>
- **Recommended fix (direction):** <words only, e.g. "Wrap the body (not the
  Scaffold) in SafeArea and keep the AppBar outside it.">
- **Status:** Confirmed | Needs verification — <what to check on device>

(repeat for each issue, same order as the table)

## 4. Reported symptoms analysis

### Symptom: "<user's words>"

- **Root cause:** <one sentence>
- **Evidence:** `file:line` + short excerpt
- **Computation:** <e.g. columns = ceil(393 / 140) = 3 → 131 dp per card vs
  ceil(440 / 140) = 4 → 110 pt per card>
- **Related issues:** #<id>

(If no symptoms were reported: "No symptoms were reported." If a symptom could not be
traced: say so and list what was checked.)

## 5. Strengths

- <Concrete good practice with `file:line`, e.g. "Uses `MediaQuery.sizeOf` and a
  single breakpoint helper (`lib/core/breakpoints.dart:5`)".>

## 6. Manual test plan

| Device / setting | Configuration | What to check |
|------------------|---------------|---------------|
| Small Phone | Android emulator 360 × 640 | <issues #…: overflows, keyboard on forms> |
| Pixel 4 | 393 × 830 | <…> |
| Medium Phone | Android 412 × 915, API 35 (edge-to-edge) | <gesture bar, insets> |
| Pixel Fold | fold / unfold while on each tab | <state kept, layout switches> |
| Pixel Tablet | 1280 × 800 landscape + portrait | <rail, max width, grid columns> |
| iPhone SE | 375 × 667 | <small height, keyboard> |
| iPhone Pro Max | 440 × 956 | <Dynamic Island, home indicator, grid sizes> |
| Font 1.3× | both platforms | <text in rows, buttons, cards> |
| Font 2× | both platforms | <clipping, maxLines, fixed heights> |
| Landscape | small phone + iPhone | <vertical overflow, notch side insets> |
| RTL (if applicable) | `ar` locale | <padding, icons, alignment> |

Link each row to the issue numbers it verifies.
```
