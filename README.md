# HostMemoryResidency — Demo App

**Change one picker from "App" to "Widget extension" and watch the same domain core resolve to a different set of components, at different fidelities, for reasons the screen states out loud.**

A SwiftUI app that consumes [host-memory-residency-kit](https://github.com/rajatslakhina/host-memory-residency-kit) as a **remote Swift Package resolved from a released version range**. Nothing about the library is vendored here — the project file points at GitHub, and Xcode fetches it.

---

## Why this matters

A shared domain core linked into an app, a widget extension and a notification service extension is the same code compiled three times against three wildly different jetsam ceilings. Nothing in the type system tells you which one you are in, and when you get it wrong the failure is not an exception — it is the process disappearing with no memory warning attached.

This app makes that decision visible. It is a policy engine you can poke at, not a screen with a chart on it.

---

## What the screen actually does

| Control | What changes |
|---|---|
| **Host process** | App / widget / intent / notification service / share extension. Changes both the budget *and* which components are even candidates. |
| **Device class** | Constrained / standard / generous. Same catalog, different ceiling. |
| **Memory pressure** | Normal / warning / critical. Revokes headroom by raising the *margin*, never by rewriting the limit. |
| **Activation** | Sequential vs concurrent — whether one activation peak is carried at a time or all of them at once. |

Three things worth trying:

1. **Widget extension + Constrained.** Headroom drops to 17 MB, the content index falls to `minimal`, and an orange **"Declared meaning changes"** section appears saying so. The library is allowed to make that trade only because the catalog declares the component `degradable`; it records the change rather than making it quietly.
2. **The audit gate.** "Record an under-predicted activation" feeds the model a peak 40% higher than it promised, and the verdict flips to `FAIL`. Over-prediction never fails it — the two directions are graded asymmetrically on purpose.
3. **"Fire 6 concurrent admissions."** Six callers hit one coordinator at once. The reserved figure is what the six of them booked *between* them, alongside what a check-then-act implementation would have booked instead.

The banner at the top is the app's own half of the contract. `DeviceClassifier` reads `ProcessInfo.physicalMemory`, maps it to a `DeviceMemoryTier`, and that same tier is handed to `ResidencyDemoView(hostKind:tier:)` — so the device class the screen plans against is the one this build actually detected, not a hardcoded default. The banner also shows the process's real `phys_footprint` via `MachFootprintProbe`. Device detection belongs in the app; policy belongs in the library, and the library never reads `ProcessInfo` itself.

---

## How to run it

```bash
git clone https://github.com/rajatslakhina/host-memory-residency-kit-demo-app.git
cd host-memory-residency-kit-demo-app
open Demo.xcodeproj
```

Select the **Demo** scheme, pick any iOS Simulator, and Build & Run. Xcode resolves `host-memory-residency-kit` from GitHub on first open — no local checkout of the library is needed, and none is referenced.

Requires Xcode 16 or later (iOS 17 deployment target).

### The dependency, exactly as it is declared

```
XCRemoteSwiftPackageReference "host-memory-residency-kit"
  repositoryURL = https://github.com/rajatslakhina/host-memory-residency-kit.git
  requirement   = { kind = upToNextMajorVersion; minimumVersion = 2.0.0; }
```

Resolved against a **released version range** — `2.0.0 ..< 3.0.0` — rather than tracking `main`. That is the difference that matters for a portfolio artifact: branch-tracking means every clone and every CI run resolves whatever `main` happened to be that day.

It is a range, not a pin, so a minor release would be picked up by a fresh resolve.

`Package.resolved` is deliberately **not** gitignored — but to be exact about what that does and does not mean: **no `Package.resolved` is committed in this repository yet.** The file is written by Xcode (or `xcodebuild -resolvePackageDependencies`) into `Demo.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/`, and this project has never been opened on a machine that could commit one back. What exists instead is CI: every run resolves the range from scratch and prints the resulting `Package.resolved` in the **Show resolved versions** step, so the exact version each build used is on the public record even though the file is not in the tree. The first person to open this project in Xcode will produce one, and it is not gitignored, so it will be committable.

---

## Verification — what actually happened

Stated precisely, because "it builds" and "it ran" are different claims and only one of them is true here.

**What was verified:**

- The library's own test suite: `swift build -Xswiftc -warnings-as-errors`, `swift build --build-tests -Xswiftc -warnings-as-errors` and `swift test` — **85 tests, 0 failures**, clean from a wiped `.build` under Swift 6 language mode. Those ran on the library, not on this app.
- `project.pbxproj` was checked for balanced braces and parentheses and for dangling object references before it was committed. 23 objects defined, 23 referenced, zero dangling.
- **This repo's CI on `macos-15` has run and passed.** `xcodebuild -resolvePackageDependencies` resolved `host-memory-residency-kit` from GitHub at the released version, printed the resulting `Package.resolved`, and `xcodebuild build -scheme Demo -destination 'generic/platform=iOS Simulator'` compiled the app against it. Every step green. That is the cheapest honest substitute for a human opening the project: it proves the project file is valid, the remote package genuinely resolves, and this app compiles. See the [Actions tab](https://github.com/rajatslakhina/host-memory-residency-kit-demo-app/actions).

**What was not:**

- **This app has not been launched on a Simulator.** The automated run that produced this repo requested computer-use access and was refused with: *"Computer-use access to 'Simulator' can't be approved during a scheduled run."* Access was requested three times, including once narrowed to the Simulator alone, and refused identically each time.
- **There are therefore no screenshots in this repository, and no `Demo/Screenshots/` directory.** Nothing here depicts the running app. "Compiles for an iOS Simulator destination" is the strongest claim this repo can currently make, and it is not the same as "ran".

---

## Companion library

[host-memory-residency-kit](https://github.com/rajatslakhina/host-memory-residency-kit) — the planner, the ledger, the audit gate and the tests.

## Licence

MIT. See [LICENSE](LICENSE).
