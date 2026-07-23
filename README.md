# StillBox

> First published app from Cerminara Consulting. A single-screen breathwork app.

## What this is

A SwiftUI iOS app that lets you open it, breathe, close it. No accounts. No feeds. No notifications. Dark, calm, immediate.

**Read `SPEC.md` first.** It's the design contract.

## Project layout

```
stillbox/
├── SPEC.md                       ← Design contract (single source of truth)
├── README.md                     ← You are here
├── App/                          ← Xcode project root
│   ├── Sources/App/StillBoxApp.swift
│   ├── Views/
│   │   ├── ContentView.swift            ← "The Room" main screen
│   │   ├── SettingsSheet.swift
│   │   ├── PatternCreatorView.swift
│   │   └── AboutView.swift
│   ├── Engine/
│   │   ├── BreathEngine.swift           ← @MainActor ObservableObject
│   │   ├── BreathPhase.swift            ← enum: inhale, holdIn, exhale, holdOut
│   │   └── BreathingPattern.swift       ← struct + presets
│   ├── Models/
│   │   ├── AppSettings.swift            ← @AppStorage-backed
│   │   └── HapticEngine.swift
│   ├── Store/
│   │   └── StoreManager.swift           ← StoreKit 2 wrapper
│   ├── Resources/
│   │   ├── Info.plist
│   │   └── PrivacyInfo.xcprivacy
│   ├── Assets.xcassets/                 ← See "Brand assets" below
│   └── PreviewContent/
└── project.yml                    ← XcodeGen project spec (see "Generating the Xcode project")
```

## Architecture

Three concerns, cleanly separated:

- **Views** — pure SwiftUI. `@MainActor` `ContentView` and sheets. No business logic.
- **Engine** — owns the breath-loop state machine. `BreathEngine` is an `ObservableObject` driven by a `Timer.publish(...)` or `Task.sleep` chain, publishing phase transitions to views.
- **Store** — thin wrapper over `StoreKit 2`'s `Product` and `Transaction` APIs. Settings view queries unlock state; doesn't make design decisions.

Data flow: `BreathEngine` → `@Published currentPhase` → `ContentView` observes and animates the box.

> **Why SwiftUI (vs UIKit):** the entire interaction surface is one screen + a sheet. SwiftUI handles state, animation, and Dynamic Type with the platform's idiomatic APIs. There is no performance reason to drop to UIKit for an animation that runs at 60fps with a single `scaleEffect`. We get free Reduce Motion and Dynamic Type support, and the code stays roughly half the size of the UIKit equivalent.

## Generating the Xcode project

The project ships as an **XcodeGen** spec (`project.yml`). Generate the `.xcodeproj` on your Mac with:

```bash
brew install xcodegen   # one-time
cd /path/to/stillbox
xcodegen generate
open StillBox.xcodeproj
```

XcodeGen is the convention used throughout the Apple-platform Mac setup for `native-ios-from-non-mac` workflows — it's the cleanest way to keep a Swift-only, multi-folder, asset-catalog project under Git without fighting the binary `.xcodeproj` in source control.

**If you prefer a checked-in `.xcodeproj`:** generate it once with XcodeGen, then `git add` the project file. The XcodeGen `project.yml` stays as documentation for the project structure.

### Notes on the XcodeGen spec

- **`DEVELOPMENT_ASSET_PATHS`** in `project.yml` tells Xcode to expose `App/PreviewContent` as a "Development Assets" folder — used by SwiftUI Previews (⌥⌘↩) for placeholder content.
- **`info:` block owns the truth.** The hand-written `App/Resources/Info.plist` is *not* the source of truth — `project.yml`'s `info.properties` is. When you run `xcodegen generate`, XcodeGen overwrites `Info.plist` with the values from `project.yml`. Edit `project.yml`, not `Info.plist`.
- **`App/Sources/App/StillBoxApp.swift`** lives three folders deep because that's where XcodeGen dropped it when generating Xcode groups from the directory tree. Not a problem, just a navigation quirk.

## First-build runbook (on the Mac)

1. **Install Xcode 15.4+** (SwiftUI 17 features require it). On a fresh Mac: `xcode-select --install` then download Xcode 15.4 from the App Store.
2. **Pull the repo:**
   ```bash
   git clone https://github.com/cerminara-consulting/stillbox.git
   cd stillbox
   git log --oneline    # confirm you got all three commits
   ```
3. **Generate the project:**
   ```bash
   brew install xcodegen   # skip if already installed
   xcodegen generate
   open StillBox.xcodeproj
   ```
4. **Set signing team:** open the project in Xcode → StillBox target → Signing & Capabilities → select Cerminara Consulting developer team. If "Cerminara Consulting" is not in the list, sign in to Xcode with your Apple Developer account first (Xcode → Settings → Accounts).
5. **Pick a destination:** top-left scheme picker → an iPhone 15 Pro (or 16 Pro) simulator on iOS 17.x. ⌘R. First build will take 30–60 seconds (clean build).
6. **Verify it runs.** You should see a dark screen with a single bordered square centered, the word "breathe" above it, and two text links ("Patterns & settings", "About") at the bottom. Tap anywhere to start a 4-4-4-4 breath cycle.
7. **Open Settings.** Long-press anywhere for 0.6s — the Settings sheet slides up. Pattern picker shows "Box" selected.
8. **Run on physical device:** Plug in iPhone, unlock it, ⌘R. Will need to trust the developer certificate on the device (Settings → General → VPN & Device Management → tap your Apple ID → Trust).
9. **TestFlight:** Once the first build runs in the simulator, archive (Product → Archive), then Distribute → TestFlight → Internal Testing.

### What to watch for on first build

- **Compile errors:** if `xcodebuild` complains about anything in `BreathEngine.swift`, `StoreManager.swift`, or `Views/*.swift`, paste the error back here verbatim. Don't try to fix it blind — these are subtle actor-isolation rules.
- **"App icon not found":** expected. The `AppIcon.appiconset/Contents.json` slot exists but the 1024×1024 PNG does not (not built yet — placeholder only). The simulator shows a generic icon; the app still runs.
- **"Privacy manifest invalid":** if Xcode complains about `PrivacyInfo.xcprivacy`, confirm the file format is the XML plist form. Xcode 15.4 accepts it directly.
- **iAP products not found:** expected on first run, before App Store Connect setup. `StoreManager.refresh()` swallows the error silently — the Settings sheet just won't show the "Unlock patterns" button until you create the IAP product ID in App Store Connect.
- **Reduce Motion feedback:** enable Settings → Accessibility → Motion → Reduce Motion on the simulator, then relaunch StillBox. The box should stay static while still updating its phase text ("in" / "hold" / "out" / "hold").

## Configuration before App Store submission

These are one-time setup steps in App Store Connect:

- Register the **bundle ID** `com.cerminara.stillbox`.
- Create the **In-App Purchase** product `com.cerminara.stillbox.patterns` (non-consumable, Family Sharing: no).
- Create the three **tip-jar** products `com.cerminara.stillbox.tip.1`, `tip.3`, `tip.5` (non-consumable).
- Add **screenshots** for 6.7" iPhone (required) and 5.5" (recommended) — see `App Store metadata` section below for copy.
- Set the **privacy nutrition label** to "Data Not Collected" in every category.
- Set **App Tracking Transparency** to "No" — the app does not track.

## App Store metadata (draft copy)

These go in App Store Connect when you're ready to submit:

- **Name (30 chars):** `StillBox: Box Breathing`
- **Subtitle (30 chars):** `Box Breath · Calm · Reset`
- **Promotional text (170 chars):** A dark, quiet space. Tap once. The box breathes with you. 4-4-4-4, 4-7-8, 3-4-5-3 — or make your own. From Cerminara Consulting.
- **Description (4000 chars):** TBD at submission time. Anchor: the opening paragraph is the user-facing rephrasing of `SPEC.md §2 The Problem`.
- **Keywords (100 chars):** `breath,breathing,calm,anxiety,sleep,focus,breathe,box,reset,mindful`
- **Category:** `Health & Fitness`
- **Content rating:** 4+ (no objectionable content)

> The App Store Connect name `StillBox` (plain) was already taken — likely by one of the German breastfeeding-product brands using "Stillbox" as a brand mark. The "Box Breathing" suffix is the App Store's title-disambiguation pattern: it preserves our brand as the lead, anchors the search keyword (`box breathing`), and signals category to Apple's auto-classifier so we don't get mis-filed under lifestyle/kitchen.

## Brand assets

The brand colors, app icon, and a built-in accent color set live in `App/Assets.xcassets/`:

- `AccentColor.colorset` — used by SwiftUI for system controls
- `AppIcon.appiconset` — 1024×1024 PNG (to be designed — see "Next actions")

> **App icon design:** out of scope for the v1 source tree. A 1024×1024 PNG of a centered bordered square on `#0E1116` with `#E6E1D7` stroke is sufficient for v1 submission. We'll come back to this with the same care as the in-app design.

## Verification

After each build, before any commit to `main`:

- [ ] Visual check: app launches into dark room, no nav chrome, no buttons except the two small text links.
- [ ] Tap-to-start works. Tap-to-stop works. No flicker.
- [ ] Phase text updates ("in" / "hold" / "out" / "hold") inside the box.
- [ ] Settings sheet opens from the link, dismisses by swipe.
- [ ] Pattern creator produces a runnable pattern.
- [ ] Reduce Motion setting causes the box to stay static.
- [ ] Dynamic Type at XX-Large does not clip the box or hide controls.
- [ ] VoiceOver reads the current phase on the box and announces all controls.
- [ ] IAP unlocks the advanced patterns after a successful test purchase.

## Next actions for John

These are **not blocking** v1 development, but they need to happen before App Store submission:

1. **USPTO TESS check (3 minutes, free):** open https://tmsearch.uspto.gov, search for `Stillbox` in Nice Classes 9 (downloadable software) and 42 (computer/software services). If no live matches, you're clear.
2. **Register `stillbox.com`:** if TESS is clear, buy the domain. A parked `.com` is better than nothing; an occupied one with no resolution is a marketing problem.
3. **App Icon design:** either a quick stylized version of the in-app box, or a designed one. The source tree ships with an empty `AppIcon.appiconset` for this.
4. **Privacy policy URL:** the privacy label requires a URL. Either host a public markdown file or use a generator.
5. **First TestFlight build:** once you've built and signed on Mac.

## License

© 2026 Cerminara Consulting. Internal portfolio project.
