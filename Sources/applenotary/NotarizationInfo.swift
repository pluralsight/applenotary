import Foundation

enum NotarizationStatus: String, Decodable {
    case inProgress = "in progress"
    case success
    case invalid
}

struct NotarizationInfo: Decodable {
    
    private enum CodingKeys: String, CodingKey {
        case date = "Date"
        case logFileUrl = "LogFileURL"
        case requestUUID = "RequestUUID"
        case statusCode = "Status Code"
        case statusMessage = "Status Message"
        case status = "Status"
        
    }
    
    
    var date: Date?
    var logFileUrl: String?
    var requestUUID: String?
    var status: NotarizationStatus
    var statusCode: Int?
    var statusMessage: String?
}
