# Detection checklist (15 categories)

**Scope:** every `.dart` file under `lib/`, plus `pubspec.yaml`,
`android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`, and the root app
widget (`main.dart` / `app.dart`). Skip generated files (`*.g.dart`, `*.freezed.dart`,
`*.gr.dart`, `*.config.dart`, `lib/generated/`, `l10n` output).

Patterns are POSIX ERE (`grep -nE`). `scripts/scan_patterns.sh` runs these patterns
under the same category numbers, plus a few "good sign" patterns (e.g. `LayoutBuilder`,
`withClampedTextScaling`, `GlobalKey`) that feed the Strengths section. A match is a **candidate**: always read the code in
context before confirming. Each category ends with "Manual review": things grep cannot
find that you must check by reading screens.

Rule IDs refer to `references/standards.md`.

---

## C01 — Fixed sizes

**Look for:** hardcoded `width`/`height` on cards, containers, images, buttons, or
`SizedBox` wrappers that hold content and should be flexible.

**Patterns**
```
(width|height):[[:space:]]*[0-9]{3,}(\.[0-9]+)?[,)[:space:]]
height:[[:space:]]*double\.infinity
```
Values < 100 are mostly gaps and icons; check them only when reading a suspicious
widget (e.g. several fixed widths in one `Row`).

**False positives:** spacers (`SizedBox(height: 16)`), dividers, icon/avatar sizes
≤ 64, fixed sizes inside a `FittedBox`/`AspectRatio`, sizes from a design-token
constant used consistently, explicit `minWidth`/`minHeight` touch targets.

**Confirm when:** a box holding text or variable content has a fixed width ≥ ~150 or a
fixed height while its content can grow (text scale, translations, dynamic data), or
the sum of fixed widths in a `Row` exceeds 320 dp.

**Rule:** STD-MEASURE-3, STD-COM-1.

---

## C02 — Grids & lists

**Look for:** variable column counts that change card size per device; aspect ratios
that clip text; unbounded nested scrollables.

**Patterns**
```
SliverGridDelegateWithMaxCrossAxisExtent|GridView\.extent|maxCrossAxisExtent
childAspectRatio
crossAxisCount:[[:space:]]*[0-9]+
shrinkWrap:[[:space:]]*true
NeverScrollableScrollPhysics
```

**Analysis:**
- `MaxCrossAxisExtent`: columns = `ceil(width / (maxCrossAxisExtent + crossAxisSpacing))`.
  Compute it for 360, 393, 411, 440 and 600+ dp. Different column counts → different
  card sizes per phone (classic "looks bigger on Android" symptom). This is a valid
  responsive tool; flag it only when the cards contain fixed-size content or the user
  reports a size difference.
- Fixed `crossAxisCount` (e.g. 2) never adapts to tablets → 🟠 large screens.
- `childAspectRatio` with text-heavy cards: card height = width / ratio; at 1.3×–2×
  text, content clips or overflows (`BOTTOM OVERFLOWED`). Prefer `mainAxisExtent` or
  content-driven heights.
- `ListView`/`GridView` with `shrinkWrap: true` inside another scroll view: performance
  and unbounded-height errors; prefer slivers.

**Rule:** STD-MEASURE-2, STD-WSC-1, STD-HIG-2.

---

## C03 — Measuring

**Look for:** full-MediaQuery subscriptions, screen percentages scattered across
widgets, MediaQuery used where the parent's constraints matter.

**Patterns**
```
MediaQuery\.of\([a-zA-Z_]*\)\.size
MediaQuery\.of\([a-zA-Z_]*\)\.(padding|viewInsets|viewPadding|orientation|textScaleFactor|textScaler)
(size|sizeOf\([a-zA-Z_]*\))\.(width|height)[[:space:]]*[*/][[:space:]]*[0-9]*\.?[0-9]+
```

**False positives:** a single `MediaQuery.sizeOf` at the root to pick a layout;
`MediaQuery.of` in a tiny leaf widget (still 🟡 for STD-MEASURE-1, not more).

**Confirm when:** a widget inside a constrained parent (card, dialog, pane, grid cell)
sizes itself from the **screen** width — it breaks in split-screen, panes, dialogs,
and tablets.

**Rule:** STD-MEASURE-1 (🟡), STD-MEASURE-2 / STD-COM-1 (🟠 when it breaks a layout).

---

## C04 — Branching logic

**Look for:** layout decisions based on platform, device type, or orientation; magic
breakpoints.

**Patterns**
```
Platform\.is(IOS|Android)|defaultTargetPlatform[[:space:]]*==|TargetPlatform\.(iOS|android)
OrientationBuilder|Orientation\.(portrait|landscape)
isTablet|isPhone|isMobile|deviceType|DeviceType
(width|maxWidth|shortestSide)[[:space:]]*[<>]=?[[:space:]]*[0-9]{3,}
```

**False positives:** platform checks for **behavior** (permissions, haptics, native
APIs, `CupertinoSwitch` vs `Switch` adaptive widgets) are fine.

**Confirm when:** padding, sizes, column counts, or navigation differ by platform or
orientation; breakpoints are numbers repeated in several files instead of one
definition; no breakpoint exists at all (no `LayoutBuilder`/`sizeOf` decision anywhere).

**Rule:** STD-BP-2, STD-WSC-1, STD-ADAPT-2.

---

## C05 — Orientation lock

**Patterns**
```
setPreferredOrientations
DeviceOrientation\.(portrait|landscape)
```
Also check manifests:
```
android:screenOrientation      (AndroidManifest.xml)
UISupportedInterfaceOrientations  (Info.plist — only portrait listed?)
```

**False positives:** the call restores all orientations; camera/game screens with a
documented reason.

**Rule:** STD-BP-1, STD-AND-1. Severity 🟠 (letterboxing on foldables/tablets).

---

## C06 — SafeArea

**Look for:** content under the notch/Dynamic Island/status bar/gesture bar.

**Patterns**
```
SafeArea\(
Scaffold\(
extendBody(BehindAppBar)?:[[:space:]]*true
SystemUiMode\.(edgeToEdge|immersive)
```

**Manual review (essential):** for each screen, check whether content touches the top
or bottom edge:
- `Scaffold` **without** `appBar` and body not wrapped in `SafeArea` → content under
  the status bar / notch → 🔴 if text/buttons are hidden.
- `SafeArea` wrapping the whole `Scaffold` → `AppBar`/bottom bar background stops at
  the insets (white/black strip) → 🟡/🟠.
- `extendBody: true` or `Stack` with `Positioned(bottom: 0)` without
  `MediaQuery.paddingOf(context).bottom` → content under the gesture bar.
- `SafeArea(bottom: false)` with a bottom-anchored button → 🔴 on iPhones with home
  indicator and Android 15 edge-to-edge.

**Rule:** STD-SAFE-1, STD-SAFE-4, STD-HIG-1.

---

## C07 — Floating navigation / overlays

**Look for:** scrollable content hidden behind a floating bottom bar, FAB, or
persistent bottom sheet.

**Patterns**
```
extendBody:[[:space:]]*true
floatingActionButton:
Positioned\([^)]*bottom:
bottomNavigationBar:
```

**Manual review:** if the bar overlays content (`extendBody`, `Stack`), the scroll
view's last item must have bottom padding ≥ bar height + `MediaQuery.paddingOf.bottom`.

**Rule:** STD-SAFE-2. 🔴 if the last items/actions are unreachable, else 🟡.

---

## C08 — Typography

**Patterns**
```
fontSize:[[:space:]]*[0-9]+
textScaleFactor
TextScaler\.(noScaling|linear\([[:space:]]*1(\.0)?[[:space:]]*\))
withClampedTextScaling
maxLines:
overflow:[[:space:]]*TextOverflow
```

**Analysis:**
- Hardcoded `fontSize` outside `ThemeData`/`TextTheme` definitions → 🟡 (STD-COM-6).
- `textScaleFactor` usage → deprecated (🟡); forcing it to 1 → 🟠 (STD-COM-3).
- `TextScaler.noScaling` / `TextScaler.linear(1)` applied app-wide in `builder:` →
  🟠 accessibility (STD-COM-3, STD-HIG-2).
- No `withClampedTextScaling` and large text breaks layouts → recommend clamping (🟡).
- **Manual review:** `Text` inside `Row` without `Expanded`/`Flexible` → overflow with
  long strings, translations, or 1.3× text → 🔴 when the string is dynamic or
  translated. `Text` in fixed-height boxes without `maxLines`/`overflow` → 🔴/🟠.

**Rule:** STD-COM-3, STD-COM-5, STD-COM-6, STD-HIG-2.

---

## C09 — Icons & images

**Patterns**
```
Image\.(asset|network|file|memory)\(
(Image|SvgPicture)\.[a-z]+\([^)]*(width|height):[[:space:]]*[0-9]{3,}
size:[[:space:]]*[0-9]{3,}
fit:[[:space:]]*BoxFit
```
Assets: list `assets/` folders declared in `pubspec.yaml`; check for `2.0x/` and
`3.0x/` variants of raster images (`.png`, `.jpg`, `.webp`).

**Analysis:** image with fixed large width inside a flexible parent and no `fit` →
distortion/overflow; raster assets without 2x/3x → blurry on high-density screens
(🟡); icons ≥ 100 dp fixed regardless of container (🟡).

**Rule:** STD-COM-1, STD-COM-8.

---

## C10 — Keyboard

**Patterns**
```
resizeToAvoidBottomInset:[[:space:]]*false
viewInsets
TextField\(|TextFormField\(|CupertinoTextField\(
```

**Manual review:** a screen with input fields whose body is a `Column` (not a scroll
view) → `BOTTOM OVERFLOWED` when the keyboard opens on small phones → 🔴.
`resizeToAvoidBottomInset: false` without manual inset handling → fields hidden under
the keyboard → 🔴.

**Rule:** STD-SAFE-3.

---

## C11 — RTL

Only relevant if the app supports an RTL locale (`ar`, `he`, `fa`, `ur`, `ps`, `ku`,
`yi`, `dv`) or the user says so. In an LTR-only app, report at most one 🟡 grouped entry
("not RTL-ready").

**Patterns**
```
EdgeInsets\.only\([^)]*(left|right):
EdgeInsets\.fromLTRB
Alignment\.(center|top|bottom)(Left|Right)
Positioned\([^)]*(left|right):
BorderRadius\.only\([^)]*(topLeft|topRight|bottomLeft|bottomRight)
TextAlign\.(left|right)
Icons\.(arrow_back|arrow_forward|chevron_left|chevron_right|arrow_back_ios|arrow_forward_ios|keyboard_arrow_left|keyboard_arrow_right)\b
textDirection:[[:space:]]*TextDirection\.(ltr|rtl)
```
(`\b` is not POSIX; the script uses an equivalent.)

**Analysis:** in an RTL app, `left`/`right` do not flip → asymmetric padding, badges on
the wrong side, misaligned text → 🟠 (🔴 if content overlaps or is hidden). Hardcoded
`textDirection: TextDirection.ltr` on a layout → 🟠. Directional arrows not mirrored
(prefer `Icons.adaptive.arrow_back` or `Directionality`-aware icons) → 🟡.

**Rule:** STD-COM-7.

---

## C12 — Large screens

**Patterns**
```
NavigationRail|NavigationDrawer|AdaptiveScaffold
ConstrainedBox\(|maxWidth:
PageStorageKey
BottomNavigationBar\(|NavigationBar\(
```

**Manual review:**
- Main content (forms, lists, reading text) is full width with no `maxWidth`
  constraint → 🟠 at ≥ 840 dp (STD-BP-3).
- Bottom navigation at all widths, no `NavigationRail` at ≥ 600 dp → 🟠 (STD-WSC-2).
- Scroll views/tabs without `PageStorageKey`, or layout branch that rebuilds a different
  subtree (state lost on fold/rotation) → 🟠 (STD-BP-4). Typical case: the same `body`
  widget is placed at a different tree position in each branch
  (`Scaffold(body: body)` vs `Row([rail, Expanded(child: body)])`) without a
  `GlobalKey`: every `State` below it (text fields, scroll, tabs) is recreated when
  the width crosses the breakpoint — which happens on phone rotation. Escalate to 🔴
  if user input is lost.
- `android/app/src/main/AndroidManifest.xml` activity without `android:configChanges`
  (Flutter template value includes `orientation|screenSize|smallestScreenSize|
  screenLayout|density|fontScale|uiMode…`) → the activity restarts on rotation, fold
  and resize, losing in-memory state → 🟠 (STD-BP-4, STD-AND-1).
- No size-based branching anywhere in the app → 🟠 "phone-only layout".

**Rule:** STD-BP-3, STD-BP-4, STD-WSC-2, STD-AND-1.

---

## C13 — iOS vs Android

**Patterns (Dart)**
```
Platform\.is(IOS|Android)
permission_handler|geolocator|image_picker|camera|location|local_auth
Permission\.[a-zA-Z]+
```
**Patterns (platform files)**
```
uses-permission                       (AndroidManifest.xml)
NS[A-Za-z]+UsageDescription           (Info.plist)
```
**Fonts:** `fonts:` in `pubspec.yaml` — family names used in `fontFamily:` must match
declared families exactly; asset paths must exist.

**Analysis:**
- Plugin needs a permission declared on one platform only → feature broken/crash on
  the other → 🔴 (STD-PLAT-1).
- No UI fallback when permission is denied (only `print`/empty catch) → 🟠.
- Widget rendered only inside `if (Platform.isAndroid)` with no iOS equivalent → 🔴 if
  it is a feature, 🟠 if cosmetic.
- `fontFamily` not declared → falls back to Roboto / San Francisco → visible iOS/Android
  difference → 🟠.
- `Platform` from `dart:io` crashes on web: flag 🔴 only if web is a target.

**Rule:** STD-PLAT-1, STD-BP-2.

---

## C14 — Scaling packages

**Patterns**
```
flutter_screenutil|ScreenUtil|ScreenUtilInit|sizer|responsive_sizer
[0-9)][.](w|h|sp|r|sw|sh)([^A-Za-z0-9_(]|$)
```

**Analysis:** count usages. A few uses → 🟡. Used as the **main** strategy
(dozens of `.w/.h/.sp` across most screens) → 🟠: proportional scaling makes
everything huge on tablets/foldables and `.sp` interferes with accessibility text
scaling. Check `ScreenUtilInit(designSize:, minTextAdapt:, splitScreenMode:)`.

**False positives:** `.w`/`.h` on non-numeric receivers (e.g. `rect.w`), `size.h` in
domain code.

**Rule:** STD-COM-2.

---

## C15 — Layout performance

**Patterns**
```
MediaQuery\.of\(
setState\(
```
Plus file-size heuristics: `.dart` files > 400 lines containing a single `build`
method > 150 lines.

**Analysis:** huge `build` methods that read `MediaQuery.of` at the top rebuild the
whole screen on every keyboard/inset change → 🟡. Missing `const` on static
subtrees (`const` analyzer lint `prefer_const_constructors` disabled) → 🟡. Report once,
grouped, with the worst files.

**Rule:** STD-BP-5, STD-MEASURE-1.
