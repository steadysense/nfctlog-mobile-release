# nfctlog — Android example

A minimal, runnable Android app that integrates the published SteadySense `nfctlog` library
(`at.steadysense.nfctlog:nfctlog-android:0.4.3`) to read and activate temperature patches over NFC.

This is a standalone Gradle project — it depends on the **published** AAR, not on the library
source. Use it as a reference for wiring `nfctlog` into your own app.

## Prerequisites

1. A physical Android device with NFC (the emulator has no NFC).
2. GitHub Packages credentials. The AAR is hosted on GitHub Packages, which requires
   authentication **even though the package is public**. You need a GitHub personal access token
   with the `read:packages` scope.

   Add to `~/.gradle/gradle.properties` (recommended — keeps the token out of the project):

   ```properties
   GITHUB_PACKAGES_USERNAME=your-github-username
   GITHUB_PACKAGES_PASSWORD=ghp_your_token_with_read_packages
   ```

   (You can also put them in this project's `gradle.properties`, but do not commit a real token.)

## Build & run

```bash
./gradlew assembleDebug
# or install straight onto a connected device:
./gradlew installDebug
```

Then open the app and tap a SteadySense patch. The buttons map to the library commands:
`read`, `readOrActivate`, `activate`, `reset`.

## How it integrates (the two pieces that matter)

- **Repository + dependency** — `settings.gradle.kts` adds the GitHub Packages Maven repo
  (`https://maven.pkg.github.com/steadysense/nfctlog-mobile-release`) with the credentials above,
  and `app/build.gradle.kts` declares `implementation("at.steadysense.nfctlog:nfctlog-android:0.4.3")`.
- **NFC setup** — `app/src/main/AndroidManifest.xml` requests `android.permission.NFC` and filters
  the `NDEF_DISCOVERED` intent; `MainActivity` creates an `NfcHandler` and forwards the
  lifecycle/intent callbacks.

## Version

Pinned to `0.4.3`. (SW v5.0 delta-coding features will appear when 0.5.0 is published.)
