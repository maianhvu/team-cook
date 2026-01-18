import Foundation

protocol NetworkRequestBody {
    var headers: HTTPHeaders? { get }
    func encodeToData() throws -> Data?
}

protocol NetworkResponseBody {
    init(data: Data, response: HTTPURLResponse) throws
}

protocol NetworkRequest {
    associatedtype RequestBody: NetworkRequestBody
    associatedtype ResponseBody: NetworkResponseBody
    
    var method: HTTPMethod { get }
    var endpoint: HTTPEndpoint { get }
    var query: URLQuery? { get }
    var headers: HTTPHeaders? { get }
    
    var cachePolicy: URLRequest.CachePolicy { get }
    var timeoutInterval: TimeInterval { get }
    
    var body: RequestBody { get }
    var responseStatusFilter: HTTPStatusFilter { get }
}

extension NetworkRequest {
    var method: HTTPMethod { .get }
    var query: URLQuery? { nil }
    var headers: HTTPHeaders? { nil }
    var cachePolicy: URLRequest.CachePolicy { .useProtocolCachePolicy }
    var timeoutInterval: TimeInterval { 60 }
    var responseStatusFilter: HTTPStatusFilter { .success }
}
