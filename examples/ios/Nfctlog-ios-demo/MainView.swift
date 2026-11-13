import SwiftUI
import Foundation
import nfctlog

struct MainView: View {

    @State private var appState: AppState = .Idle
    @State private var record: TlogRecord? = nil

    @State private var settings = ActivationSettings()

    private var session: CardReaderSessionIOS = CardReaderSessionIOS.init(
        config: NfcConfig(
            logLevel: LogLevel.error,
            progress: true,
            showUi: true,
            validUrls: ["kiwu.femsense.com", "t.steadytemp.info"]
        )
    )

    /// Builds the activation config from the UI, or sets an error state if it is invalid.
    private func buildConfig() -> ActivationConfig? {
        guard let config = settings.build() else {
            self.appState = .Error(error: "User data is limited to 64 bytes.")
            return nil
        }
        return config
    }

    func onClickResetPatch() {
        if(record == nil) {
            return
        }

        do {
            try session.reset(){ result, error in
                if(error != nil) {
                    print("Error: \(String(describing: error?.message))")
                } else if(result == nil) {
                    // Session cancelled by the user before the reset finished.
                    print("Reset cancelled")
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
                    // (nil, nil) means the user cancelled the NFC session.
                    if let error = error {
                        self.appState = .Error(error: error.message ?? String(describing: error))
                    } else {
                        self.appState = .Idle
                    }
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
            guard let config = buildConfig() else { return }
            self.appState = .ReadSession
            try session.readOrActivateTag(config: config){ patch, error in
                guard patch != nil else {
                    // (nil, nil) means the user cancelled the NFC session.
                    if let error = error {
                        self.appState = .Error(error: error.message ?? String(describing: error))
                    } else {
                        self.appState = .Idle
                    }
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
            guard let config = buildConfig() else { return }
            self.appState = .ActivateSession
            print("Just before executing activate command")
            try session.activate(config: config){ result, error in
                if let error = error {
                    print("Error: \(String(describing: error.message))")
                    self.appState = .Error(error: error.message ?? String(describing: error))
                } else if(result == nil) {
                    // Session cancelled by the user before the activation finished.
                    print("Activation cancelled")
                    self.appState = .Idle
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

    var body: some View {
        VStack(spacing: 8) {
            TopBox(appState: self.appState)
            ActivationSettingsView(settings: $settings)
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
