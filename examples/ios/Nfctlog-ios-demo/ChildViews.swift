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
    
    var body: some View {
        VStack {
            if (canBeReseted()) {
                Button(action: self.onResetPatchClicked) {
                    Text("Reset Patch")
                        .foregroundColor(Color.white)
                        .frame(minWidth: 0, maxWidth: .infinity)
                }.accessibility(identifier: "resetPatchButton")
                    .padding()
                    .background(Color.red)
            }
            if (canBeActivated()) {
                Button(action: self.onActivatePatchClicked) {
                    Text("Activate Patch")
                        .foregroundColor(Color.white)
                        .frame(minWidth: 0, maxWidth: .infinity)
                }.accessibility(identifier: "activatePatchButton")
                    .padding()
                    .background(Color.yellow)
            }
            Button(action: self.onReadPatchClicked) {
                Text("Read Patch")
                    .foregroundColor(Color.white)
                    .frame(minWidth: 0, maxWidth: .infinity)
            }.accessibility(identifier: "readPatchButton")
                .background(Color.green)
                .padding()
            Button(action: self.onReadOrActivatePatchClicked) {
                Text("Read or Activate Patch")
                    .foregroundColor(Color.white)
                    .frame(minWidth: 0, maxWidth: .infinity)
            }.accessibility(identifier: "readOrActivatePatchButton")
                .background(Color.green)
                .padding()
        }
    }
}
