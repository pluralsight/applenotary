import Foundation

class NotaryError: NSError, Decodable {
    
    private enum CodingKeys: String, CodingKey {
        case code
        case userInfo
    }
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(domain: "Apple Notarization",
                  code: try container.decode(Int.self, forKey: .code),
                  userInfo: try container.decode(Dictionary<String, String>.self, forKey: .userInfo))
    }
}
