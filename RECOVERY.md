# StillBox Mac recovery — disk space block

## What happened

Mac reports "No space left on device" when Git tries to update its own
`.git/FETCH_HEAD` file. Every `git pull` since has silently failed.

Consequences:

- The latest `project.yml` with the DEVELOPMENT_ASSET_PATHS fix never
  landed on this Mac. XcodeGen keeps regenerating from the old version.
- The Xcode warnings about `App/Preview` and `Content` are correct for
  the *old* `project.yml` still on disk.
- Apple iOS Simulator runs eat disk fast (~5-15 GB per iPhone per iOS).
  Also: Xcode's `DerivedData/` directory grows unboundedly; previous
  test apps; macOS Time Machine local snapshots.

## Step 1 — free space (run these in order)

```bash
# Quick wins. None of these deletes code or documents.
xcrun simctl shutdown all 2>/dev/null
xcrun simctl delete unavailable               # removes simulators you can't run
rm -rf ~/Library/Developer/Xcode/DerivedData/*    # build cache, can be 30+ GB
rm -rf ~/Library/Developer/CoreSimulator/Caches/* # simulator cache
rm -rf ~/Library/Caches/com.apple.dt.Xcode/*     # Xcode UI cache, can be 5+ GB
tmutil thinlocalsnapshots / 1000000000000 2>/dev/null  # nuke old Time Machine local snapshots

# After each big rm, verify:
df -h /
```

Goal: at least 20 GB free.

## Step 2 — verify the pull now works

```bash
cd /Users/cerminaraconsulting/stillbox/stillbox
git status
# Expect: "Your branch is up to date" or "Your branch is behind ... commits"

git pull
# Expect: a small fetch + merge, no errors
```

## Step 3 — verify the fix is on disk

```bash
grep -A1 DEVELOPMENT_ASSET_PATHS project.yml
```

Expected output:
```
DEVELOPMENT_ASSET_PATHS:
  - "App/PreviewContent"

The directory used to be `App/Preview Content` (with a literal space).
Renamed to remove the space because Xcode's project format kept splitting
the value on the space and reporting `.../App/Preview` and `.../Content`
as separate non-existent paths. With no space, Xcode treats it as one path.
```

If you see the old form (`DEVELOPMENT_ASSET_PATHS: "App/Preview Content"`), that means the file is still stale — wait and tell me, and we'll diagnose further.

## Step 4 — regenerate and rebuild

```bash
rm -rf StillBox.xcodeproj
xcodegen generate
open StillBox.xcodeproj
```

In Xcode: pick iPhone 15 Pro simulator, ⌘R.

If the DEVELOPMENT_ASSET_PATHS warnings are *still* there after this, run:

```bash
grep -A3 DEVELOPMENT_ASSET_PATHS StillBox.xcodeproj/project.pbxproj
```

and paste the result back.
