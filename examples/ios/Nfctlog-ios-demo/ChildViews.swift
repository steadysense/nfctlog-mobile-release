import SwiftUI
import nfctlog


struct TopBox: View {
    var appState: AppState
    var body: some View {
        Text("App state: \(self.appState.enumDescription)").font(.body).foregroundColor(Color.black)
    }
}

extension String {
    mutating func appendLine(_ s: String) {
        self.append(s + "\n")
    }
}

struct MiddleBox: View {
    
    var appState: AppState
    
    func formatTemperature(temperature: Double?) -> String {
        guard let temperature = temperature else {
            return "Discarded"
        }
        return String(format:"%.2f", temperature)
    }
    
    func formatTemperatures(record: TlogRecord) -> String {
        var s = ""
        let iterator = record.temperatures.iterator()
        while iterator.hasNext() {
            let t = iterator.next() as! TlogValue
            let isValid = !t.valid ? "isInvalid" : ""
            s.appendLine( "\(t.index)" + "  " + formatTemperature(temperature: t.temperature) + " " + isValid)
        }
        return s
    }
    
    func printTlogRecordDetails(record: TlogRecord) -> String {
        var s = """
TlogRecord:\n\(record.format())
\nTemperatures:\n\(formatTemperatures(record: record))
\nRaw record:\n\(record.raw_record.toImmutable().toHexDump())
"""
        s.appendLine("")
        return s
    }
    
    func getDetailText() -> String {
        switch appState {
        case .Idle:
            return "Click a button to start either a read session or an activate session.";
        case .ReadSession:
            return "Ready for readout - Hold the back of the device close to a patch.";
        case .ActivateSession:
            return "Ready for activation - Hold the back of the device close to a patch.";
        case .ReadSuccess(let record):
            return printTlogRecordDetails(record: record);
        case .ActivateSuccess:
            return "Patch successfully activated! Please wait a few minutes before measurements are available.";
        case .Error(let error):
            return "The error \(String(describing: error)) occurred during NFC processing.";
        }
    }
    
    var body: some View {
        ScrollView(.vertical) {
            Text(getDetailText())
                .lineLimit(nil).foregroundColor(Color.black)
        }
    }
}

struct BottomBox: View {
    var appState: AppState

    var onReadPatchClicked: () -> Void
    var onReadOrActivatePatchClicked: () -> Void
    var onActivatePatchClicked: () -> Void
    var onResetPatchClicked: () -> Void
    
    private func canBeActivated() -> Bool {
        switch appState {
        case .ReadSuccess(let record):
            return record.isReadyForActivation
        default:
            return false
        }
    }
    
    private func canBeReseted() -> Bool {
        switch appState {
        case .ReadSuccess(let record):
            return record.isActive
        default:
            return false
        }

    }
    
    private func actionButton(_ title: String, color: Color, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(Color.white)
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(color)
        }.accessibility(identifier: id)
    }

    var body: some View {
        VStack(spacing: 8) {
            if (canBeReseted()) {
                actionButton("Reset Patch", color: .red, id: "resetPatchButton", action: self.onResetPatchClicked)
            }
            if (canBeActivated()) {
                actionButton("Activate Patch", color: .yellow, id: "activatePatchButton", action: self.onActivatePatchClicked)
            }
            actionButton("Read Patch", color: .green, id: "readPatchButton", action: self.onReadPatchClicked)
            actionButton("Read or Activate Patch", color: .green, id: "readOrActivatePatchButton", action: self.onReadOrActivatePatchClicked)
        }
    }
}

/// Activation parameters editable in the demo, mirroring the Android demo's options.
struct ActivationSettings {
    /// Same interval steps as the Android demo slider.
    static let intervals: [(seconds: Int32, label: String)] = [
        (1, "1 sec (DO NOT USE IN PRODUCTION)"),
        (30, "30 sec"),
        (60, "1 min"),
        (300, "5 min"),
        (600, "10 min"),
        (900, "15 min"),
        (1800, "30 min"),
        (3600, "1 hour"),
    ]

    var intervalIndex: Int = 3
    var enableRingBuffer: Bool = true
    var enableUVLO: Bool = true
    var lock: Bool = false
    /// ASCII user data; padded with zeros to a multiple of 16 bytes (max 64).
    var userData: String = "DEADBEEF"

    // SW v5.0+ delta coding.
    var deltaCoding: Bool = false
    var deltaDynamic: Bool = false
    var deltaRefCelsius: String = "25"
    var deltaShift: Int = 1

    var intervalSeconds: Int32 { Self.intervals[intervalIndex].seconds }
    var intervalLabel: String { Self.intervals[intervalIndex].label }

    var summary: String {
        var parts = [intervalLabel]
        if enableRingBuffer { parts.append("RingBuffer") }
        if enableUVLO { parts.append("UVLO") }
        if lock { parts.append("Lock") }
        if !userData.isEmpty { parts.append("UserData") }
        if deltaCoding { parts.append("Delta \(deltaDynamic ? "dyn" : "static") \(deltaRefCelsius)°C s\(deltaShift)") }
        return parts.joined(separator: " · ")
    }

    /// Builds the library config, or nil if the user data exceeds 64 bytes (the Kotlin init would
    /// throw an IllegalArgumentException, which Swift cannot catch). When delta coding is enabled the reference is passed as a temperature; the library converts
    /// it to ADC at activation using the chip's own IFX calibration, so no per-chip offset is introduced.
    func build() -> ActivationConfig? {
        if userData.utf8.count > 64 { return nil }
        let data: ImmutableByteArray? = userData.isEmpty
            ? nil
            : ImmutableByteArray.companion.fromASCIIPadded(s: userData)
        let deltaRef: KotlinDouble? = deltaCoding
            ? KotlinDouble(value: Double(deltaRefCelsius.replacingOccurrences(of: ",", with: ".")) ?? 25.0)
            : nil
        return ActivationConfig(
            measureIntervalSeconds: intervalSeconds,
            enableRingBuffer: enableRingBuffer,
            enableUVLO: enableUVLO,
            lock: lock,
            userData: data,
            deltaCodingReferenceTemperatureCelsius: deltaRef,
            deltaCodingDynamicMode: deltaDynamic,
            deltaCodingShift: Int32(deltaShift)
        )
    }
}

struct ActivationSettingsView: View {
    @Binding var settings: ActivationSettings
    @State private var expanded: Bool = false

    private var userDataTooLong: Bool {
        settings.userData.utf8.count > 64
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: { self.expanded.toggle() }) {
                HStack {
                    Text("Activation settings").bold()
                    Spacer()
                    Text(expanded ? "Hide" : "Edit")
                }
            }
            if !expanded {
                Text(settings.summary).font(.caption).foregroundColor(.gray)
            } else {
                HStack {
                    Text("Interval: \(settings.intervalLabel)")
                    Spacer()
                    Stepper("Interval", value: $settings.intervalIndex, in: 0...(ActivationSettings.intervals.count - 1))
                        .labelsHidden()
                }
                Toggle("Ring buffer", isOn: $settings.enableRingBuffer)
                Toggle("UVLO", isOn: $settings.enableUVLO)
                Toggle("Lock", isOn: $settings.lock)
                HStack {
                    Text("User data")
                    TextField("ASCII, max 64 chars", text: $settings.userData)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textFieldStyle(.roundedBorder)
                }
                if userDataTooLong {
                    Text("User data is limited to 64 bytes.").font(.caption).foregroundColor(.red)
                }

                Toggle("Delta coding (SW v5.0+)", isOn: $settings.deltaCoding)
                if settings.deltaCoding {
                    Toggle("Dynamic reference", isOn: $settings.deltaDynamic)
                    HStack {
                        Text("Ref °C")
                        TextField("25", text: $settings.deltaRefCelsius)
                            .keyboardType(.numbersAndPunctuation)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 100)
                        Spacer()
                    }
                    HStack {
                        Text("Shift \(settings.deltaShift)")
                        Spacer()
                        Stepper("Shift", value: $settings.deltaShift, in: 1...4)
                            .labelsHidden()
                    }
                    Text("Step = 2^shift ADC counts (resolution / span around ref): "
                         + "1 → ~0.02°C / ±2.5°C, 2 → ~0.04°C / ±5°C, "
                         + "3 → ~0.08°C / ±10°C, 4 → ~0.15°C / ±20°C. "
                         + "Dynamic encodes each delta against the previous value instead of the fixed reference.")
                        .font(.caption).foregroundColor(.gray)
                }
            }
        }.foregroundColor(.black)
    }
}
