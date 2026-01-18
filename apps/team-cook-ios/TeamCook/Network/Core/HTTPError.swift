import Foundation

struct HTTPError: Error, LocalizedError {
    let statusCode: Int
    var message: String?
    
    init(data: Data, response: HTTPURLResponse) {
        statusCode = response.statusCode
        message = nil
        
        if let contentType = response.value(forHTTPHeaderField: "Content-Type") {
            if contentType.contains("text/"), let body = String(data: data, encoding: .utf8) {
                message = body
            } else if contentType.contains("application/json"), let probe = try? JSONDecoder().decode(ErrorJSONProbe.self, from: data) {
                message = probe.message
            }
        }
    }
    
    var errorDescription: String? {
        if let message {
            return String(localized: "Request failed with status \(statusCode): \(message)")
        } else {
            return String(localized: "Request failed with status \(statusCode)")
        }
    }
}

private struct ErrorJSONProbe: @nonisolated Decodable {
    var message: String
    
    private enum CodingKeys: String, CodingKey {
        case error
        case message
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let message = try container.decodeIfPresent(String.self, forKey: .message) {
            self.message = message
        } else if let error = try container.decodeIfPresent(String.self, forKey: .error) {
            self.message = error
        } else {
            throw DecodingError.dataCorruptedError(forKey: .message, in: container, debugDescription: "No message or error key found in JSON")
        }
    }
}
