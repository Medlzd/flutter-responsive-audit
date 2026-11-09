#!/bin/sh
# scan_patterns.sh — read-only pre-scan for flutter-responsive-audit.
#
# Usage: sh scan_patterns.sh [PROJECT_ROOT]
#
# Prints candidate matches ("file:line: code") grouped by checklist category
# (see references/checklist.md). Matches are CANDIDATES, not confirmed issues.
# This script never writes, modifies or deletes any file.
#
# Exit codes: 0 = scan done, 2 = not a Flutter project, 1 = usage error.

ROOT=${1:-.}
MAX_PER_PATTERN=${MAX_PER_PATTERN:-60}
MAX_LINE_CHARS=240

# Audited projects may be untrusted:
# - never follow symlinks (they could point outside the project),
# - strip control characters and cap line length in everything printed.
clean() {
  tr -d '\000-\010\013-\037\177' | cut -c "1-$MAX_LINE_CHARS"
}

if [ ! -d "$ROOT" ]; then
  echo "error: '$ROOT' is not a directory" >&2
  exit 1
fi
cd -- "$ROOT" || exit 1

# ---------------------------------------------------------------- validation
if [ -L pubspec.yaml ]; then
  echo "STOP: pubspec.yaml is a symlink; refusing to follow it"
  exit 2
fi
if [ ! -f pubspec.yaml ]; then
  echo "NOT_FLUTTER: no pubspec.yaml found in $(pwd)"
  exit 2
fi
if ! grep -qE '^[[:space:]]+sdk:[[:space:]]*["'"'"']?flutter["'"'"']?([[:space:]]|#|$)' pubspec.yaml; then
  echo "NOT_FLUTTER: pubspec.yaml does not declare the flutter SDK dependency"
  exit 2
fi
if [ -L lib ] || [ ! -d lib ]; then
  echo "NOT_FLUTTER: no lib/ directory"
  exit 2
fi

ANDROID_MANIFEST=android/app/src/main/AndroidManifest.xml
IOS_PLIST=ios/Runner/Info.plist

# Dart files in lib/, excluding generated code. Paths have no newlines.
dart_files() {
  find lib -type f -name '*.dart' \
    ! -name '*.g.dart' ! -name '*.freezed.dart' ! -name '*.gr.dart' \
    ! -name '*.config.dart' ! -name '*.mocks.dart' \
    ! -path 'lib/generated/*' ! -path '*/l10n/generated/*'
}

# scan LABEL ERE_PATTERN
scan() {
  label=$1
  pattern=$2
  out=$(dart_files | while IFS= read -r f; do
          grep -nE -- "$pattern" "$f" /dev/null 2>/dev/null
        done | sed 's/^\([^:]*:[0-9][0-9]*:\)[[:space:]]*/\1 /' | clean)
  if [ -n "$out" ]; then
    count=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
    echo "  -- $label ($count)"
    printf '%s\n' "$out" | head -n "$MAX_PER_PATTERN" | sed 's/^/     /'
    if [ "$count" -gt "$MAX_PER_PATTERN" ]; then
      echo "     ... $((count - MAX_PER_PATTERN)) more (set MAX_PER_PATTERN to see all)"
    fi
  else
    echo "  -- $label: none"
  fi
}

# scan_file LABEL FILE ERE_PATTERN
scan_file() {
  label=$1
  file=$2
  pattern=$3
  if [ -L "$file" ]; then
    echo "  -- $label: SKIPPED, $file is a symlink (not followed)"
  elif [ -f "$file" ]; then
    out=$(grep -nE -- "$pattern" "$file" /dev/null 2>/dev/null \
          | sed 's/^\([^:]*:[0-9][0-9]*:\)[[:space:]]*/\1 /' | clean)
    if [ -n "$out" ]; then
      echo "  -- $label"
      printf '%s\n' "$out" | sed 's/^/     /'
    else
      echo "  -- $label: none"
    fi
  else
    echo "  -- $label: $file not found"
  fi
}

section() {
  echo
  echo "== $1"
}

# ---------------------------------------------------------------- header
nfiles=$(dart_files | wc -l | tr -d ' ')
echo "flutter-responsive-audit pre-scan"
echo "project: $(pwd)"
echo "dart files scanned (lib/, generated excluded): $nfiles"
echo "NOTE: every line below is a candidate. Read the code before reporting it."

section "CONTEXT: root app, locales, packages"
scan "root app widget" 'MaterialApp(\.router)?\(|CupertinoApp(\.router)?\(|WidgetsApp\('
scan "locales / direction" 'supportedLocales|locale:|Directionality\(|TextDirection\.rtl'
scan_file "responsive packages (pubspec.yaml)" pubspec.yaml \
  'flutter_screenutil|responsive_framework|sizer|responsive_builder|flutter_adaptive_scaffold|responsive_sizer|adaptive_breakpoints'
scan_file "fonts (pubspec.yaml)" pubspec.yaml '^[[:space:]]*(fonts:|- family:|asset:.*\.(ttf|otf))'
scan_file "flutter constraint (pubspec.yaml)" pubspec.yaml '^[[:space:]]+(sdk|flutter):[[:space:]]*["'"'"']?[<>=^0-9]'

section "C01 Fixed sizes"
scan "width/height literal >= 100" '(width|height):[[:space:]]*[0-9]{3,}(\.[0-9]+)?[,)[:space:]]'
scan "double.infinity heights" 'height:[[:space:]]*double\.infinity'

section "C02 Grids & lists"
scan "max cross axis extent" 'SliverGridDelegateWithMaxCrossAxisExtent|GridView\.extent|maxCrossAxisExtent'
scan "fixed crossAxisCount" 'crossAxisCount:[[:space:]]*[0-9]+'
scan "childAspectRatio" 'childAspectRatio'
scan "shrinkWrap / nested scroll" 'shrinkWrap:[[:space:]]*true|NeverScrollableScrollPhysics'

section "C03 Measuring"
scan "MediaQuery.of(...).size" 'MediaQuery\.of\([a-zA-Z_]*\)\.size'
scan "MediaQuery.of(...) other fields" 'MediaQuery\.of\([a-zA-Z_]*\)\.(padding|viewInsets|viewPadding|orientation|textScaleFactor|textScaler)'
scan "screen percentage" '(size|sizeOf\([a-zA-Z_]*\))\.(width|height)[[:space:]]*[*/][[:space:]]*[0-9]*\.?[0-9]+'
scan "LayoutBuilder / sizeOf (good signs)" 'LayoutBuilder|MediaQuery\.sizeOf'

section "C04 Branching logic"
scan "platform checks" 'Platform\.is(IOS|Android|MacOS|Windows|Linux)|defaultTargetPlatform[[:space:]]*==|TargetPlatform\.(iOS|android)'
scan "orientation branching" 'OrientationBuilder|Orientation\.(portrait|landscape)'
scan "device-type helpers" 'isTablet|isPhone|isMobile|isDesktop|deviceType|DeviceType'
scan "numeric breakpoints" '(width|maxWidth|shortestSide|biggest\.width)[[:space:]]*[<>]=?[[:space:]]*[0-9]{3,}'

section "C05 Orientation lock"
scan "setPreferredOrientations" 'setPreferredOrientations|DeviceOrientation\.(portrait|landscape)'
scan_file "Android screenOrientation" "$ANDROID_MANIFEST" 'android:screenOrientation'
scan_file "iOS supported orientations" "$IOS_PLIST" 'UISupportedInterfaceOrientations|UIInterfaceOrientation'

section "C06 SafeArea"
scan "SafeArea usage" 'SafeArea\('
scan "Scaffold usage" 'Scaffold\('
scan "edge-to-edge / extendBody" 'extendBody(BehindAppBar)?:[[:space:]]*true|SystemUiMode\.(edgeToEdge|immersive)'
scan "SafeArea sides disabled" '(top|bottom):[[:space:]]*false'

section "C07 Floating navigation / overlays"
scan "bottom bars / FAB" 'bottomNavigationBar:|floatingActionButton:|bottomSheet:'
scan "bottom-anchored Positioned" 'Positioned\([^)]*bottom:'

section "C08 Typography"
scan "hardcoded fontSize" 'fontSize:[[:space:]]*[0-9]+'
scan "deprecated textScaleFactor" 'textScaleFactor'
scan "text scaling disabled" 'TextScaler\.(noScaling|linear\([[:space:]]*1(\.0)?[[:space:]]*\))'
scan "text scaling clamped (good sign)" 'withClampedTextScaling|\.clamp\([[:space:]]*(minScaleFactor|maxScaleFactor)'
scan "maxLines / overflow (good sign)" 'maxLines:|overflow:[[:space:]]*TextOverflow'

section "C09 Icons & images"
scan "images" 'Image\.(asset|network|file|memory)\(|SvgPicture\.|CachedNetworkImage\('
scan "large fixed icon/image size" 'size:[[:space:]]*[0-9]{3,}'
scan "BoxFit (good sign)" 'fit:[[:space:]]*BoxFit'
if [ -d assets ]; then
  echo "  -- raster assets without 2.0x/3.0x variants (first 40)"
  find assets -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webp' \) \
    ! -path '*/2.0x/*' ! -path '*/3.0x/*' | while IFS= read -r a; do
      d=$(dirname "$a"); b=$(basename "$a")
      if [ ! -f "$d/2.0x/$b" ] && [ ! -f "$d/3.0x/$b" ]; then echo "     $a"; fi
    done | head -n 40 | clean
fi

section "C10 Keyboard"
scan "resizeToAvoidBottomInset false" 'resizeToAvoidBottomInset:[[:space:]]*false'
scan "text inputs" 'TextField\(|TextFormField\(|CupertinoTextField\('
scan "viewInsets handling" 'viewInsets'

section "C11 RTL"
scan "EdgeInsets.only left/right" 'EdgeInsets\.only\([^)]*(left|right):'
scan "EdgeInsets.fromLTRB" 'EdgeInsets\.fromLTRB'
scan "non-directional Alignment" 'Alignment\.(center|top|bottom)(Left|Right)'
scan "Positioned left/right" 'Positioned\([^)]*(left|right):'
scan "BorderRadius.only corners" 'BorderRadius\.only\([^)]*(topLeft|topRight|bottomLeft|bottomRight)'
scan "TextAlign left/right" 'TextAlign\.(left|right)'
scan "directional icons" 'Icons\.(arrow_back|arrow_forward|chevron_left|chevron_right|arrow_back_ios|arrow_forward_ios|keyboard_arrow_left|keyboard_arrow_right)([^A-Za-z0-9_]|$)'
scan "forced text direction" 'textDirection:[[:space:]]*TextDirection\.(ltr|rtl)'

section "C12 Large screens"
scan "adaptive navigation (good sign)" 'NavigationRail|NavigationDrawer|AdaptiveScaffold|AdaptiveLayout'
scan "bottom navigation" 'BottomNavigationBar\(|NavigationBar\(|CupertinoTabBar\('
scan "max width constraints (good sign)" 'ConstrainedBox\(|maxWidth:'
scan "PageStorageKey (good sign)" 'PageStorageKey'
scan "GlobalKey (state kept across layout branches)" 'GlobalKey'
scan_file "Android configChanges" "$ANDROID_MANIFEST" 'android:configChanges'

section "C13 iOS vs Android"
scan "permission / device plugins" 'permission_handler|geolocator|image_picker|camera|location|local_auth|Permission\.[a-zA-Z]+'
scan "fontFamily usage" 'fontFamily:'
scan_file "Android permissions" "$ANDROID_MANIFEST" 'uses-permission'
scan_file "iOS usage descriptions" "$IOS_PLIST" 'NS[A-Za-z]+UsageDescription'

section "C14 Scaling packages"
scan "ScreenUtil / sizer" 'flutter_screenutil|ScreenUtil|ScreenUtilInit|package:sizer|responsive_sizer'
scan "scaled units (.w .h .sp .r)" '[0-9)][.](w|h|sp|r|sw|sh)([^A-Za-z0-9_(]|$)'

section "C15 Layout performance"
scan "MediaQuery.of (rebuilds on any change)" 'MediaQuery\.of\('
echo "  -- largest dart files (lines)"
dart_files | while IFS= read -r f; do
  printf '%s %s\n' "$(wc -l < "$f" | tr -d ' ')" "$f"
done | sort -rn | head -n 10 | clean | sed 's/^/     /'

echo
echo "== END OF PRE-SCAN"
exit 0
