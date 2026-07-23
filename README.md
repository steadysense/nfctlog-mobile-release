# nfctlog

Android and iOS library for integrating SteadySense temperature sensor patches into third-party applications.

The library is written in Kotlin Multiplatform. The Android artifacts (AAR) are published via GitHub Packages, and the iOS XCFramework is distributed via Swift Package Manager.

---

## Installation

### Android

Add the GitHub Packages repository to your `settings.gradle` or `build.gradle`:

```groovy
maven {
    url = uri("https://maven.pkg.github.com/steadysense/nfctlog-mobile-release")
    credentials {
        username = findProperty("GITHUB_PACKAGES_USERNAME") as String?
        password = findProperty("GITHUB_PACKAGES_PASSWORD") as String?
    }
}
```

Then add the dependency:

```groovy
implementation 'at.steadysense.nfctlog:nfctlog-android:VERSION'
```

#### Credentials

GitHub Packages requires authentication even for public packages. Add your credentials to `~/.gradle/gradle.properties`:

```
GITHUB_PACKAGES_USERNAME=your-github-username
GITHUB_PACKAGES_PASSWORD=ghp_yourPersonalAccessToken
```

The personal access token needs at least `read:packages` scope.

Alternatively, load them from `local.properties` in your `build.gradle`:

```groovy
def localProps = new Properties()
def localPropsFile = rootProject.file('local.properties')
if (localPropsFile.exists()) localPropsFile.withReader('UTF-8') { localProps.load(it) }

// in repositories block:
credentials {
    username = localProps['GITHUB_PACKAGES_USERNAME'] ?: findProperty('GITHUB_PACKAGES_USERNAME')
    password = localProps['GITHUB_PACKAGES_PASSWORD'] ?: findProperty('GITHUB_PACKAGES_PASSWORD')
}
```

#### NFC permissions

Add the NFC permission to `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.NFC" />
```

Add an intent filter to receive NFC tag intents in your Activity:

```xml
<intent-filter>
    <action android:name="android.nfc.action.NDEF_DISCOVERED" />
    <category android:name="android.intent.category.DEFAULT" />
    <data android:scheme="https" android:host="t.steadytemp.info" />
</intent-filter>
```

---

### iOS

Add the package via Xcode's package manager using the source repository URL:

```
https://github.com/steadysense/nfctlog-mobile-release
```

Before using NFC, complete the following setup:

1. Add the **Near Field Communication Tag Reader Session Formats** entitlement to your app's entitlements file.
2. Set `NFCReaderUsageDescription` in `Info.plist`.

For authentication with GitHub Packages / Swift Package Manager, follow the [KMMBridge SPM authentication guide](https://kmmbridge.touchlab.co/docs/spm/IOS_SPM#artifact-authentication).

For more details on NFC setup, see [Apple's CoreNFC documentation](https://developer.apple.com/documentation/corenfc/building_an_nfc_tag-reader_app#3240401).

---

## Usage

### Android

Create an `NfcHandler` instance in your `Activity` and wire up the lifecycle callbacks:

```kotlin
class MainActivity : ComponentActivity() {
    private lateinit var nfcHandler: NfcHandler

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        nfcHandler = NfcHandler(this)
    }

    override fun onResume() {
        super.onResume()
        nfcHandler.onResume()
    }

    override fun onPause() {
        super.onPause()
        nfcHandler.onPause()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        nfcHandler.onNewIntent(intent)
    }
}
```

Then call the desired command:

```kotlin
// Read
nfcHandler.read { patchData, error ->
    if (error != null) { /* handle error */ return@read }
    println(patchData?.record?.format())
}

// Activate
val config = ActivationConfig(measureIntervalSeconds = 900, enableRingBuffer = true)
nfcHandler.activate(config) { patchData, error -> }

// Activate with delta-coding (SW v5.0+): stores each sample as an 8-bit delta
// around a reference temperature given in °C.
val deltaConfig = ActivationConfig.withDeltaCoding(
    measureIntervalSeconds = 900,
    enableRingBuffer = true,
    deltaReferenceTemperatureCelsius = 25.0,
    deltaCodingDynamicMode = false,
    deltaCodingShift = 2,
)
nfcHandler.activate(deltaConfig) { patchData, error -> }

// Read, or activate if the patch has not been started yet
nfcHandler.readOrActivate(config) { patchData, error -> }

// Reset
nfcHandler.reset { patchData, error -> }
```

### iOS

Create a `CardReaderSessionIOS` and call the desired command:

```swift
import nfctlog

let session = CardReaderSessionIOS(config: NfcConfig(
    logLevel: .error,
    progress: true,
    showUi: true,
    validUrls: ["t.steadytemp.info"]
))

// Read
try session.readTag { patch, error in
    guard let patch else { print(error?.message ?? ""); return }
    print(patch.record.format())
}

// Activate
let config = ActivationConfig(
    measureIntervalSeconds: 900,
    enableRingBuffer: true,
    enableUVLO: true,
    lock: false,
    userData: nil
)
try session.activate(config: config) { patch, error in }

// Activate with delta-coding (SW v5.0+): reference is given in °C.
let deltaConfig = ActivationConfig.companion.withDeltaCoding(
    measureIntervalSeconds: 900,
    enableRingBuffer: true,
    enableUVLO: true,
    lock: false,
    userData: nil,
    deltaReferenceTemperatureCelsius: 25.0,
    deltaCodingDynamicMode: false,
    deltaCodingShift: 2
)
try session.activate(config: deltaConfig) { patch, error in }

// Read, or activate if the patch has not been started yet
try session.readOrActivateTag(config: config) { patch, error in }

// Reset
try session.reset { patch, error in }
```

---

## API Reference

### `NfcHandler` (Android) / `CardReaderSessionIOS` (iOS)

| Method | Description |
|---|---|
| `read(callback)` | Reads patch data. Returns immediately if an NDEF intent is already available. |
| `activate(config, callback)` | Activates the patch with the given configuration. |
| `readOrActivate(config, callback)` | Reads the patch; activates it first if it is in `WAIT_FOR_MEASUREMENT` state. |
| `reset(callback)` | Resets the patch to its factory state. |

All callbacks follow the pattern `(result: PatchData?, error: Throwable?) -> Unit`.

#### Android-only

| Method | Description |
|---|---|
| `onNewIntent(intent)` | Forward NFC intents from `Activity.onNewIntent`. Returns `PatchData` if the intent contains a readable NDEF message and no command is active. |
| `onTagDiscovered(tag)` | Forward tags from `NfcAdapter.ReaderCallback` when using reader mode. |
| `onResume()` / `onPause()` | Enable/disable foreground dispatch — call from `Activity` lifecycle. |
| `cancelCommand()` | Cancel the currently running command. |
| `isNfcEnabled` | `true` if NFC is available and turned on. |
| `isNfcAvailable` | `true` if the device has an NFC adapter. |

---

### `NfcConfig`

Configuration passed when creating `NfcHandler` / `CardReaderSessionIOS`.

| Property | Type | Default | Description |
|---|---|---|---|
| `logLevel` | `LogLevel` | `ERROR` | Verbosity of library logs. |
| `progress` | `Boolean` | `true` | Show progress percentage in the NFC dialog. |
| `showUi` | `Boolean` | `true` | Show the built-in NFC dialog. |
| `validUrls` | `List<String>` | `[]` | If non-empty, only tags whose URL matches one of these hosts are accepted. |

---

### `ActivationConfig`

Configuration applied to a patch during activation.

| Property | Type | Default | Description |
|---|---|---|---|
| `measureIntervalSeconds` | `Int` | — | Interval between successive measurements in seconds. Values below 30 s mark measurements as invalid (chip heating). |
| `enableRingBuffer` | `Boolean` | — | When `true`, old measurements are overwritten once the buffer is full (920 entries for SW v3.x). When `false`, the patch stops after 920 measurements. |
| `enableUVLO` | `Boolean` | `true` | Enable under-voltage lockout. Disable for sub-10 °C environments. |
| `lock` | `Boolean` | `false` | Lock the activation-timestamp memory area after activation. |
| `userData` | `ImmutableByteArray?` | `null` | Optional binary payload stored on the patch. Size must be a multiple of 16 bytes and at most 64 bytes. |
| `deltaCodingReferenceTemperatureCelsius` | `Double?` | `null` | **SW v5.0+.** Reference temperature (°C) for delta-coding. When set, each measurement is stored as a signed 8-bit delta relative to this reference instead of a full 16-bit value. `null` disables delta-coding. The value is converted to the chip-specific ADC reference at activation using the patch's own IFX calibration (read immediately before), so it means this exact temperature on every chip with no per-chip offset. |
| `deltaCodingDynamicMode` | `Boolean` | `false` | **SW v5.0+.** When `true`, each delta is encoded relative to the *previous* measurement (limits per-sample change) rather than the fixed reference (limits absolute distance from it). Only relevant when delta-coding is enabled. |
| `deltaCodingShift` | `Int` | `1` | **SW v5.0+.** Quantization shift applied to each stored delta; valid values `1..4`. Step = `2^shift` ADC counts, trading resolution for span around the reference (`1` → ~0.02 °C / ±2.5 °C … `4` → ~0.15 °C / ±20 °C). Only relevant when delta-coding is enabled. |

Delta-coding (SW v5.0+) is easiest to construct with the `ActivationConfig.withDeltaCoding(...)`
factory, which takes the reference as a Celsius temperature (see the usage examples above). The
`isDeltaCodingEnabled` property is `true` whenever `deltaCodingReferenceTemperatureCelsius` is set.

> **Note:** Delta-coding requires SW v5.0+ firmware. On patches running SW 4.x (or earlier) the
> delta-coding options have no effect — the patch is activated normally and stores full-value
> measurements regardless.

Serializable: `ActivationConfig.fromJson(json)` / `.toJson()`.

---

### `PatchData`

Returned by all commands.

| Property | Type | Description |
|---|---|---|
| `uid` | `ImmutableByteArray` | 7-byte unique tag identifier. |
| `scannedAt` | `Instant` | Device-local time when the tag was read. |
| `record` | `TlogRecord` | Parsed tag content (temperatures, state, calibration, …). |
| `url` | `String` | URL stored on the tag (e.g. `t.steadytemp.info`). |
| `state` | `PatchState` | Health check result. |
| `firstTimestamp` | `Instant?` | Timestamp of the first measurement (activation time + 1 min). |
| `justActivated` | `Boolean` | `true` when this result comes from an activation or readOrActivate that triggered activation. |
| `isReadyForActivation` | `Boolean` | `true` when SW state is `WAIT_FOR_MEASUREMENT` or `WAIT_FOR_RESTART_MEASUREMENT`. |
| `isActive` | `Boolean` | `true` when the patch is actively recording. |

Serializable: `PatchData.fromJson(json)` / `.toJson()`.

---

### `TlogRecord`

Detailed content of a patch. Key fields:

| Property | Type | Description |
|---|---|---|
| `temperatures` | `Array<TlogValue>` | All stored temperature measurements. |
| `measureIntervalSeconds` | `Int` | Configured measurement interval. |
| `measureCount` | `Int` | Total measurements since activation (may exceed `temperatures.size` on overflow). |
| `activationTime` | `Instant?` | UTC activation timestamp, `null` if not yet activated. |
| `sw_state` | `SWState` | Current firmware state. |
| `swVersion` | `String` | Firmware version string (e.g. `03.04`). |
| `cursor` | `Int` | Index of the most recent measurement in the ring buffer. |
| `isRingBufferEnabled` | `Boolean` | Whether ring buffer mode is active. |
| `isActive` | `Boolean` | `true` when the patch is measuring. |
| `isReadyForActivation` | `Boolean` | `true` when the patch can be activated. |
| `user_data` | `ImmutableByteArray` | Application data stored during activation. |
| `recovery_count` | `Byte` | Number of successful analog-reset recovery events. |
| `isDeltaCodingEnabled` | `Boolean` | **SW v5.0+.** `true` when the patch stores measurements as delta-coded values. |
| `isDeltaCodingDynamicMode` | `Boolean` | **SW v5.0+.** `true` when deltas are encoded against the previous value rather than the fixed reference. |
| `deltaCodingReferenceCelsius` | `Double?` | **SW v5.0+.** The delta-coding reference decoded back to °C (`null` when delta-coding is off). |
| `deltaCodingBitWidth` | `Int?` | **SW v5.0+.** Quantization shift in effect (`null` when delta-coding is off). |

Serializable: `TlogRecord.fromJson(json)` / `.toJson()`.

---

### `TlogValue`

A single temperature measurement — the element type of `TlogRecord.temperatures`.

| Property | Type | Description |
|---|---|---|
| `index` | `Int` | Absolute measurement number since activation, starting at 0. It keeps increasing across ring-buffer overflows — after an overflow only the most recent measurements are retained, so the lowest `index` present is `measureCount - bufferSize` rather than 0. Combine with `firstTimestamp` and `measureIntervalSeconds` to derive the wall-clock time (`firstTimestamp + index * measureIntervalSeconds`); this holds for every retained sample regardless of overflow. |
| `temperature` | `Double` | Measured temperature in °C. |
| `valid` | `Boolean` | `false` if an NFC field was detected during the measurement (the value may be disturbed). |
| `adc` | `UShort?` | Raw value from the patch's analog-to-digital converter, `null` if not available. |

---

### `PatchState`

| Value | Description |
|---|---|
| `OK` | No errors detected. |
| `INVALID_SW_STATE` | Manufacturing defect — return patch to SteadySense. |
| `BATTERY_LOW` | Battery depleted; patch stopped recording. |
| `UNRECOVERABLE_ERROR` | Fatal internal error; patch stopped recording. |
| `TOO_MANY_RECOVERY_EVENTS` | Too many consecutive recovery events detected. |

---

### `SWState`

Common states:

| State | Description |
|---|---|
| `WAIT_FOR_MEASUREMENT` | Patch is ready to be activated. |
| `MEASUREMENT_INITIALIZE` | Patch has just been activated. |
| `MEASUREMENT_FIRST_1_MINUTE` | First minute of measurement in progress. |
| `MEASUREMENT_TIME_CYCLE` | Patch is actively recording. |
| `WAIT_FOR_RESTART_MEASUREMENT` | Patch can be re-activated. |
| `BATTERY_LOW` | Battery critically low. |
| `FATAL_ERROR_STATE` | Unrecoverable firmware error. |
