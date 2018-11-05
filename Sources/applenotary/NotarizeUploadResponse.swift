import Foundation

struct NotarizeUploadResponse: Decodable {
    
    private enum CodingKeys: String, CodingKey {
        case osVersion = "os-version"
        case notarizationUpload = "notarization-upload"
        case successMessage = "success-message"
        case toolPath = "tool-path"
        case toolVersion = "tool-version"
        case productErrors = "product-errors"
        case notarizationInfo = "notarization-info"
    }
    
    static func create(from data: Data) -> NotarizeUploadResponse {
        let decoder = PropertyListDecoder()
        do {
            let object = try decoder.decode(NotarizeUploadResponse.self, from: data)
            return object
        } catch {
            print("error: \(error)")
            exit(1)
        }
    }
    
    var notarizationUpload: NotarizationUpload?
    var notarizationInfo: NotarizationInfo?
    var successMessage: String?
    var osVersion: String
    var toolPath: String
    var toolVersion: String
    var productErrors: [NotaryError]?
    
    var uploadSuccess: Bool {
        return successMessage != nil
    }
}
