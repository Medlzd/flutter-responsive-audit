# Standards and rules

Cite rules in the report by ID, e.g. `STD-MEASURE-1 (Flutter: Adaptive and responsive
design)`. Cite the source URL in the issue details. Do not cite a rule for something it
does not say.

## Sources

| Key | Source | URL |
|-----|--------|-----|
| FL-ADAPT | Flutter docs — Adaptive and responsive design | https://docs.flutter.dev/ui/adaptive-responsive |
| FL-BP | Flutter docs — Best practices for adaptive design | https://docs.flutter.dev/ui/adaptive-responsive/best-practices |
| FL-SAFE | Flutter docs — SafeArea & MediaQuery | https://docs.flutter.dev/ui/adaptive-responsive/safearea-mediaquery |
| FL-LARGE | Flutter docs — Large screens & foldables | https://docs.flutter.dev/ui/adaptive-responsive/large-screens |
| FL-CONS | Flutter docs — Understanding constraints | https://docs.flutter.dev/ui/layout/constraints |
| M3-WSC | Material 3 — Window size classes | https://m3.material.io/foundations/layout/applying-layout/window-size-classes |
| AND-LS | Android — Large screen app quality guidelines | https://developer.android.com/docs/quality-guidelines/large-screen-app-quality |
| HIG-LAYOUT | Apple HIG — Layout (safe areas, margins) | https://developer.apple.com/design/human-interface-guidelines/layout |
| HIG-TYPE | Apple HIG — Typography (Dynamic Type) | https://developer.apple.com/design/human-interface-guidelines/typography |
| COMMUNITY | Senior Flutter community consensus (see §7) | — |

## 1. Approach: Abstract → Measure → Branch (FL-ADAPT)

- **STD-ADAPT-1** — Abstract: identify the widgets that must change (navigation,
  dialogs, lists/grids) and the data they share, before building variants.
- **STD-ADAPT-2** — Measure: decide using the **available space**, not the device.
- **STD-ADAPT-3** — Branch: choose the layout at explicit breakpoints (see §5).

## 2. Measuring space (FL-ADAPT, FL-CONS)

- **STD-MEASURE-1** — Use `MediaQuery.sizeOf(context)` (or `paddingOf`, `viewInsetsOf`,
  `textScalerOf`…) instead of `MediaQuery.of(context).size`. `MediaQuery.of` subscribes
  the widget to **every** MediaQuery change (keyboard, insets, text scale), causing
  unnecessary rebuilds; `sizeOf` only rebuilds when the size changes.
- **STD-MEASURE-2** — Use `MediaQuery.sizeOf` for **window-level** decisions (which
  navigation, how many panes). Use `LayoutBuilder` for **local** decisions: a widget
  must adapt to the constraints its parent gives it, not to the screen size.
- **STD-MEASURE-3** — "Constraints go down. Sizes go up. Parent sets position." (FL-CONS)
  A child cannot be bigger than its parent's constraints; fixed sizes that ignore the
  incoming constraints overflow or get silently resized.

## 3. Best practices for adaptive design (FL-BP)

- **STD-BP-1** — Don't lock orientation. `SystemChrome.setPreferredOrientations`
  produces letterboxing on foldables/tablets and fails large-screen quality (AND-LS).
  Exception: genuinely orientation-bound experiences (e.g. some games, camera
  viewfinders) — document the reason.
- **STD-BP-2** — Don't branch layout on device type (`Platform.isIOS`, "isTablet",
  `isAndroid`) or on `Orientation`. Window size is what matters: a tablet in
  split-screen is a phone-sized window. Platform checks are fine for **behavior**
  (permissions, platform APIs, haptics), not for **layout size**.
- **STD-BP-3** — Don't take all horizontal space on large screens. Constrain readable
  content (text, forms, lists) with a max width or switch to multi-column layouts.
- **STD-BP-4** — Preserve state across size changes (fold/unfold, rotation,
  multi-window): use `PageStorageKey` for scroll positions, keep state above the
  layout branch, and avoid rebuilding a different widget subtree that loses state.
- **STD-BP-5** — Break down large widgets into small widgets; prefer `const`
  constructors so rebuilds triggered by size changes stay cheap.
- **STD-BP-6** — Support all input types on large screens (keyboard, mouse,
  trackpad, stylus): visual density, hover, focus traversal.

## 4. Safe areas, insets, keyboard (FL-SAFE, HIG-LAYOUT)

- **STD-SAFE-1** — Content must not render under system UI: status bar, notch,
  Dynamic Island, camera cutouts, home indicator, gesture bar. Use `SafeArea` (or
  `MediaQuery.paddingOf`) around the **body content**, not around the `Scaffold`,
  so `AppBar` / bottom bars still paint their background behind system UI.
- **STD-SAFE-2** — Scrollable content must reserve space for overlaying UI
  (floating navigation bars, FABs, bottom sheets) via padding at the end of the scroll
  view, not by clipping.
- **STD-SAFE-3** — The keyboard is an inset (`MediaQuery.viewInsetsOf(context).bottom`).
  Forms must remain usable: keep `resizeToAvoidBottomInset` enabled (default) and
  make the form scrollable, or explicitly handle the inset.
- **STD-SAFE-4** — Since Android 15 (targetSdk 35), apps are edge-to-edge by default:
  insets must be handled on Android exactly as on iOS.

## 5. Breakpoints: window size classes (M3-WSC)

| Class | Width (dp) | Typical layout |
|-------|------------|----------------|
| Compact | < 600 | single pane, `NavigationBar` (bottom) |
| Medium | 600–839 | `NavigationRail`, optional 2 panes |
| Expanded | 840–1199 | `NavigationRail`/drawer, 2 panes |
| Large / Extra-large | 1200–1599 / ≥ 1600 | permanent drawer, multi-pane |

- **STD-WSC-1** — Base layout branches on these width classes (or documented project
  equivalents) rather than ad-hoc numbers scattered in screens.
- **STD-WSC-2** — At ≥ 600 dp, bottom navigation should move to a `NavigationRail`
  (or equivalent) and content should use the extra space (AND-LS, M3-WSC).

## 6. Platform guidelines (AND-LS, HIG-*)

- **STD-AND-1** — Large-screen quality: no letterboxing, no orientation lock, layout
  adapts to every window size, state preserved on configuration change, multi-window
  supported.
- **STD-HIG-1** — Respect safe areas and layout margins on all iPhone shapes and iPad
  multitasking sizes.
- **STD-HIG-2** — Support Dynamic Type: text must grow with the user's setting
  without truncating essential information.
- **STD-PLAT-1** — A feature must work on every target platform, or degrade with an
  explicit fallback UI. Required permissions must be declared on **both** platforms
  (`AndroidManifest.xml` and `Info.plist` usage descriptions); denied permission must
  show a usable fallback.

## 7. Community consensus (COMMUNITY)

Widely shared by senior Flutter engineers and Flutter DevRel talks; cite as
"community consensus", never as official documentation.

- **STD-COM-1** — Respect parent constraints instead of measuring the screen
  everywhere (`LayoutBuilder`, `Flexible`, `Expanded`, `FractionallySizedBox`,
  `AspectRatio`).
- **STD-COM-2** — Adapt the layout, don't scale it. Using `flutter_screenutil`
  (`.w`, `.h`, `.sp`, `.r`) or `sizer` as the **main** strategy scales a phone design
  proportionally: everything becomes huge on tablets, tiny on small phones, and
  `.sp` fights the user's accessibility text size.
- **STD-COM-3** — Clamp text scaling, never disable it:
  `MediaQuery.withClampedTextScaling(maxScaleFactor: …)` in `MaterialApp.builder` is
  acceptable; `TextScaler.noScaling`, `textScaleFactor: 1.0`, or overriding
  `MediaQuery` text scale to 1 is not (accessibility, STD-HIG-2).
- **STD-COM-4** — Test at 200% system font size and with the largest display size.
- **STD-COM-5** — Text in constrained horizontal space (`Row`) must be wrapped in
  `Expanded`/`Flexible` and define `maxLines` + `overflow` where truncation is
  acceptable.
- **STD-COM-6** — Use `TextTheme` styles instead of hardcoded `fontSize` so typography
  is consistent and adjustable in one place.
- **STD-COM-7** — Use `EdgeInsetsDirectional`, `AlignmentDirectional`,
  `PositionedDirectional`, `BorderRadiusDirectional` so layouts mirror correctly in
  RTL; directional icons (arrows, chevrons, "back") must mirror (`Icons.adaptive.*`,
  `matchTextDirection: true`).
- **STD-COM-8** — Provide raster image assets at 1x/2x/3x (`2.0x/`, `3.0x/` folders)
  or use vector assets; set `fit` on images inside constrained boxes.

## Flutter API notes (version-sensitive)

- `MediaQuery.sizeOf` and friends: Flutter ≥ 3.10.
- `TextScaler`, `MediaQuery.withClampedTextScaling`: Flutter ≥ 3.16.
  `textScaleFactor` is **deprecated** since 3.16 (use `textScaler`).
- Check the project's Flutter constraint in `pubspec.yaml` (`environment:`) before
  recommending an API; mention the minimum version when it matters.
