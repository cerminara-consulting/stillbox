# StillBox — Mac recovery runbook

If something is broken, run these in order and tell me which step the
failure surfaces at.

## 1. Pull the latest (the source of truth is `main` on `origin`)

```bash
cd /Users/cerminaraconsulting/stillbox/stillbox
git pull
git status
# Expect: "nothing to commit, working tree clean"
```

## 2. Confirm the directory layout is right

```bash
ls App/
# Expect: Assets.xcassets  Engine  Models  PreviewContent  Resources  Sources  Store  Views
#          ^^^^^^^^^^^^^^ no space
```

## 3. Regenerate the .xcodeproj from scratch

```bash
rm -rf StillBox.xcodeproj
xcodegen generate
open StillBox.xcodeproj
```

## 4. Verify XcodeGen wrote the right path into pbxproj

```bash
grep DEVELOPMENT_ASSET_PATHS StillBox.xcodeproj/project.pbxproj
```

Expect a line like:

```
DEVELOPMENT_ASSET_PATHS = "App/PreviewContent";
```

If you see it split across multiple lines, the path got migrated wrong.

## 5. Build + run on iPhone 16 Pro

In Xcode:

- If the "Update to recommended settings" prompt appears → click
  "Perform Changes" once. This is the Xcode 15.4 settings migration;
  it should NOT split path strings now that the path has no space.
- Click the `StillBox` target → Signing & Capabilities → Team set
  to `Cerminara Consulting (LWPR7M772W)`.
- Top scheme picker → your physical **iPhone 16 Pro** (under "My Devices").
- ⌘R.

## 6. On the device (only on first launch)

If the iPhone shows "Untrusted Developer" — that's expected:

iPhone → Settings → General → VPN & Device Management
→ Apple Developer entry → Trust → confirm.

Subsequent launches skip this.

## 7. What to report back

If after step 5 the warnings still appear, paste:

1. The full Xcode warning text, verbatim.
2. The output of: `grep DEVELOPMENT_ASSET_PATHS StillBox.xcodeproj/project.pbxproj`
3. The output of: `cat project.yml | grep -B1 -A2 DEVELOPMENT_ASSET_PATHS`

Without all three, I can't diagnose without guessing. Don't iterate
blind — the diagnostic tells me what's stuck.

## Common error → fix mapping (updated)

| Symptom | Most likely cause | Fix |
|---|---|---|
| `cannot open '.git/FETCH_HEAD': No space left on device` | Mac disk full | `rm -rf ~/Library/Developer/Xcode/DerivedData/*`; free 20 GB |
| `DEVELOPMENT_ASSET_PATHS does not exist: .../App/Preview` | Xcode reading cached/stale project | `rm -rf StillBox.xcodeproj && xcodegen generate` |
| `Signing for StillBox requires a development team` | Apple ID not signed in | Xcode → Settings → Accounts → sign in; pick team in target |
| `Update to recommended settings` prompt | Xcode version sync | "Perform Changes" — one-time only |
| Real Swift compile error | Bug in the source | Paste verbatim error |
