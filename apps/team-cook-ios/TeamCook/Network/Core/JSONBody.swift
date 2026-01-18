import Foundation

protocol JSONRequestBody: Encodable, NetworkRequestBody {
    var extraHeaders: HTTPHeaders? { get }
}

protocol JSONResponseBody: Decodable, NetworkResponseBody {}

extension JSONRequestBody {
    var headers: HTTPHeaders? {
        var headers: HTTPHeaders = ["Content-Type": "application/json"]
        if let extraHeaders {
            headers.merge(extraHeaders, uniquingKeysWith: { $2 })
        }
        return headers
    }
    
    func encodeToData() throws -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }
}

extension JSONResponseBody {
    init(data: Data, response: HTTPURLResponse) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self = try decoder.decode(Self.self, from: data)
    }
}
