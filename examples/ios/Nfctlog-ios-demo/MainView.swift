import SwiftUI
import Foundation
import nfctlog

struct MainView: View {

    @State private var appState: AppState = .Idle
    @State private var record: TlogRecord? = nil

    // SW v5.0+ delta-coding activation options.
    @State private var deltaCoding: Bool = false
    @State private var deltaDynamic: Bool = false
    @State private var deltaRefCelsius: String = "25"
    @State private var deltaShift: Int = 2

    private var session: CardReaderSessionIOS = CardReaderSessionIOS.init(
        config: NfcConfig(
            logLevel: LogLevel.error,
            progress: true,
            showUi: true,
            validUrls: ["kiwu.femsense.com", "t.steadytemp.info"]
        )
    )

    /// Builds the activation config from the UI. When delta coding is enabled it passes the
    /// reference as a target temperature; the library converts it to ADC at activation using the
    /// chip's own IFX calibration, so no per-chip offset is introduced.
    private func buildConfig() -> ActivationConfig {
        let interval: Int32 = 60 * 5
        if deltaCoding {
            let celsius = Double(deltaRefCelsius) ?? 25.0
            return ActivationConfig.companion.withDeltaCoding(
                measureIntervalSeconds: interval,
                enableRingBuffer: true,
                enableUVLO: true,
                lock: false,
                userData: nil,
                deltaReferenceTemperatureCelsius: celsius,
                deltaCodingDynamicMode: deltaDynamic,
                deltaCodingShift: Int32(deltaShift)
            )
        }
        return ActivationConfig(
            measureIntervalSeconds: interval,
            enableRingBuffer: true,
            enableUVLO: true,
            lock: false,
            userData: nil,
            deltaCodingReferenceTemperatureCelsius: nil,
            deltaCodingDynamicMode: false,
            deltaCodingShift: 1
        )
    }

    func onClickResetPatch() {
        if(record == nil) {
            return
        }

        do {
            try session.reset(){ result, error in
                if(error != nil) {
                    print("Error: \(String(describing: error?.message))")
                } else {
                    print("Reset successful")
                }
            }
        } catch {
            print("Error: \(error)")
        }
    }

    func onClickReadPatch() {
        do {
            let start = Date()
            self.appState = .ReadSession
            try session.readTag(){ patch, error in
                guard patch != nil else {
                    self.appState = .Error(error: (error?.message)!)
                    return
                }
                print("Record: \(String(describing: patch?.record.format()))")
                self.record = patch?.record
                self.appState = .ReadSuccess(record: patch!.record)
                let timeInterval: Double = Date().timeIntervalSince(start)
                print("Read took \(timeInterval) seconds")
            }
        } catch {
            print("Error: \(error)")
        }
    }

    func onClickReadOrActivatePatch() {
        do {
            self.appState = .ReadSession
            let config = buildConfig()
            try session.readOrActivateTag(config: config){ patch, error in
                guard patch != nil else {
                    self.appState = .Error(error: (error?.message)!)
                    return
                }
                print("Record: \(String(describing: patch?.record.format()))")
                self.record = patch?.record
                self.appState = .ReadSuccess(record: patch!.record)
            }
        } catch {
            print("Error: \(error)")
        }
    }

    func onClickActivatePatch() {
        if(record == nil) {
            return
        }
        do {
            self.appState = .ActivateSession
            let config = buildConfig()
            print("Just before executing activate command")
            try session.activate(config: config){ result, error in
                if(error != nil) {
                    print("Error: \(String(describing: error?.message))")
                } else {
                    print("Activation successful")
                    self.appState = .ActivateSuccess
                }
            }
            print("Just after executing activate command")
        } catch {
            print("Error: \(error)")
        }


    }

    private var deltaCodingControls: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle("Delta coding (SW v5.0+)", isOn: $deltaCoding)
            if deltaCoding {
                Toggle("Dynamic reference", isOn: $deltaDynamic)
                HStack {
                    Text("Ref °C").foregroundColor(.black)
                    TextField("25", text: $deltaRefCelsius)
                        .keyboardType(.numbersAndPunctuation)
                        .textFieldStyle(.roundedBorder)
                        .foregroundColor(.black)
                        .frame(maxWidth: 100)
                    Spacer()
                }
                HStack {
                    Text("Shift \(deltaShift)").foregroundColor(.black)
                    Stepper("Shift", value: $deltaShift, in: 1...4)
                        .labelsHidden()
                    Spacer()
                }
                Text("Reference is an approximate ADC value from a nominal calibration. "
                     + "Shift 1-4 = quantization step (x2/x4/x8/x16). Dynamic encodes each "
                     + "delta against the previous value instead of the fixed reference.")
                    .font(.caption).foregroundColor(.gray)
            }
        }.foregroundColor(.black)
    }

    var body: some View {
        VStack(spacing: 8) {
            TopBox(appState: self.appState)
            deltaCodingControls
            BottomBox(
                appState: self.appState,
                onReadPatchClicked: self.onClickReadPatch,
                onReadOrActivatePatchClicked: self.onClickReadOrActivatePatch,
                onActivatePatchClicked: self.onClickActivatePatch,
                onResetPatchClicked: self.onClickResetPatch
            )
            MiddleBox(appState: self.appState)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .preferredColorScheme(.light)
    }
}
