import Foundation

import nfctlog

enum AppState {
    case Idle
    case Error(error: String)
    case ReadSession
    case ReadSuccess(record: TlogRecord)
    case ActivateSession
    case ActivateSuccess
    var enumDescription: String {
        switch self {
        case .Idle:
            return "Idle";
        case .Error(let error):
            return "Error: \(error)";
        case .ReadSession:
            return "ReadSession";
        case .ReadSuccess:
            return "ReadSuccess";
        case .ActivateSession:
            return "ActivateSession";
        case .ActivateSuccess:
            return "ActivateSuccess";
        }
    }
}
