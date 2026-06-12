# nfctlog — iOS example

A runnable iOS app that integrates the published SteadySense `nfctlog` Swift package to read and
activate temperature patches over NFC.

It depends on the **published** package via Swift Package Manager — use it as a reference for
wiring `nfctlog` into your own app.

## Prerequisites

- Xcode.
- A physical iPhone with NFC (the simulator has no NFC; it compiles there but can't scan).

No credentials are needed: `nfctlog-mobile-release` is public, so SPM resolves the package and
downloads the XCFramework without authentication.

## Run

1. Open `Nfctlog-mobile-demo.xcodeproj`.
2. Let Xcode resolve packages (it pulls `nfctlog` `0.4.3` from
   `https://github.com/steadysense/nfctlog-mobile-release`).
3. Select your development team under **Signing & Capabilities**.
4. Run on a connected iPhone and tap a SteadySense patch.

## How it integrates (the two pieces that matter)

- **SPM dependency** — the project references the package remotely at
  `https://github.com/steadysense/nfctlog-mobile-release`, pinned to `0.4.3`
  (`Add Package Dependency…` in Xcode does the same thing).
- **NFC setup** — `Nfctlog-ios-demo.entitlements` has the *Near Field Communication Tag Reader
  Session Formats* entitlement and `Info.plist` sets `NFCReaderUsageDescription`. `MainView` drives
  the library through `CardReaderSessionIOS` (`readTag`, `readOrActivateTag`, `activate`, `reset`).

## Version

Pinned to `0.4.3`. (SW v5.0 delta-coding features will appear when 0.5.0 is published.)
