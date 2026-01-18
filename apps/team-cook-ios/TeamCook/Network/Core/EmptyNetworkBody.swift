import Foundation

enum EmptyNetworkBody: NetworkRequestBody, NetworkResponseBody {
    case empty
    
    var headers: HTTPHeaders? { nil }
    
    func encodeToData() throws -> Data? {
        return nil
    }
    
    init(data: Data, response: HTTPURLResponse) throws {
        self = .empty
    }
}

extension NetworkRequest where RequestBody == EmptyNetworkBody {
    var body: RequestBody { .empty }
}
