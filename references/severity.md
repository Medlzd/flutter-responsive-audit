# Severity, reference devices, scoring

## Severity levels

| Level | Label | Definition | Examples |
|-------|-------|------------|----------|
| 🔴 | **Critical** | The user loses content or a feature: overflow, hidden or clipped content, unreachable action, crash, feature missing on one platform. | `RIGHT OVERFLOWED` on a 360 dp phone; text under the notch; submit button under the keyboard; location permission missing in `Info.plist`. |
| 🟠 | **Medium** | Everything works, but rendering differs between iOS and Android, or adaptation to tablets/foldables/large text is poor. | Grid cards 19% bigger on Android; stretched full-width form on tablet; orientation locked; RTL padding on the wrong side. |
| 🟡 | **Minor** | Best practice not followed; maintainability or future-proofing risk; no visible defect today. | `MediaQuery.of(context).size`; hardcoded `fontSize`; deprecated `textScaleFactor`; missing `const`. |

Decision rules:
- Pick the severity of the **worst realistic case** on the reference devices below,
  not of an extreme edge case.
- Escalate one level if the issue is on a primary flow (login, checkout, main tab) or
  affects many screens; de-escalate one level if it is on a rarely used screen.
- Write `Needs verification` next to the severity when the impact depends on runtime
  data (string length, image size, API content) you cannot see.

## Reference devices

Compute layouts at these logical widths (dp on Android, pt on iOS — equivalent units):

| Profile | Width × height | Notes |
|---------|----------------|-------|
| Small phone | 320–360 × 640–780 | iPhone SE (375 × 667), small Android (360 × 640/800) |
| Mid Android | 393–411 × 851–915 | Pixel 7/8 (412 × 915), Galaxy S (360–393 wide) |
| iPhone Pro Max | ≈ 430–440 × 932–956 | Notch/Dynamic Island + home indicator |
| Foldable | ≈ 673 × 841 unfolded (inner), ≈ 412 folded | Pixel Fold; window changes at runtime |
| Tablet | 800–1280 × 1280–800 | Pixel Tablet (1280 × 800 landscape), iPad (≈ 820–1024 wide) |
| Text scale | 1.3× and 2.0× | Android "Font size", iOS Dynamic Type / Larger Text |
| Landscape | swap width/height | small phone landscape height ≈ 360 |

Window size classes: compact < 600, medium 600–839, expanded ≥ 840 (see
`standards.md` §5).

## Score /10

Group duplicates first (one grouped issue = one issue). Then:

```
score = 10 − 1.5 × (#🔴) − 0.5 × (#🟠) − 0.15 × (#🟡)
```

- Round to one decimal, clamp to [1, 10].
- Cap at **6.0** if any 🔴 exists; cap at **4.0** if a 🔴 affects a primary flow on
  the most common device class.
- `Needs verification` issues count at half weight.
- A clean, well-built app should land at 9–10. Do not invent issues to lower a score,
  and do not hide issues to raise it.

Justify the score in exactly 3 lines: biggest risk, overall adaptive strategy,
best strength.
