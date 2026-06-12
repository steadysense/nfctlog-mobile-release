import SwiftUI
import nfctlog

struct MainView: View {

    @State private var appState: AppState = .Idle
    @State private var record: TlogRecord? = nil
    private var session: CardReaderSessionIOS = CardReaderSessionIOS.init(
        config: NfcConfig(
            logLevel: LogLevel.error,
            progress: true,
            showUi: true,
            validUrls: ["kiwu.femsense.com", "t.steadytemp.info"]
        )
    )

    
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
            let config = ActivationConfig(
                measureIntervalSeconds: 60*5,
                enableRingBuffer: true,
                enableUVLO: true,
                lock: false,
                userData: nil
            )
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
            let config = ActivationConfig(
                measureIntervalSeconds: 60*5,
                enableRingBuffer: true,
                enableUVLO: true,
                lock: false,
                userData: nil
            )
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

    var body: some View {
        VStack {
            TopBox(appState: self.appState)
            MiddleBox(appState: self.appState)
            BottomBox(
                appState: self.appState,
                onReadPatchClicked: self.onClickReadPatch,
                onReadOrActivatePatchClicked: self.onClickReadOrActivatePatch,
                onActivatePatchClicked: self.onClickActivatePatch,
                onResetPatchClicked: self.onClickResetPatch
            )
        }.padding().frame(maxHeight: .infinity, alignment: Alignment.bottomLeading).background(Color.white)
    }
}
