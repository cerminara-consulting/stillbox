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
│   └── Preview Content/
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

## First-build runbook (on the Mac)

1. **Install Xcode 15.4+** (SwiftUI 17 features require it). On a fresh Mac: `xcode-select --install` then download Xcode 15.4 from the App Store.
2. **Generate the project:** `xcodegen generate` from the repo root.
3. **Set signing team:** open the project in Xcode → StillBox target → Signing & Capabilities → select Cerminara Consulting developer team.
4. **Run on simulator:** ⌘R with iPhone 15 Pro / iOS 17.x simulator. Should see the dark room and a calm, bordered box.
5. **Run on physical device:** Plug in iPhone, unlock it, ⌘R. Will need to trust the developer certificate on the device (Settings → General → VPN & Device Management).
6. **TestFlight:** Once the first build runs, archive (Product → Archive), then Distribute → TestFlight → Internal Testing.

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

- **Name (30 chars):** `StillBox — Calm Breathing`
- **Subtitle (30 chars):** `Take a minute. Reset your breath.`
- **Promotional text (170 chars):** A dark, quiet space. Tap once. The box breathes with you. 4-4-4-4, 4-7-8, 3-4-5-3 — or make your own. From Cerminara Consulting.
- **Description (4000 chars):** TBD at submission time. Anchor: the opening paragraph is the user-facing rephrasing of `SPEC.md §2 The Problem`.
- **Keywords (100 chars):** `breath,breathing,calm,anxiety,sleep,focus,breathe,box,reset,mindful`
- **Category:** `Health & Fitness`
- **Content rating:** 4+ (no objectionable content)

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
