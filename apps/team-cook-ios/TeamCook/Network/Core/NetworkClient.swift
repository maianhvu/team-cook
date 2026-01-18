import Combine
import Foundation
import SwiftUI

final class NetworkClient: ObservableObject {
    let defaultHostname: String
    let useInsecureHTTP: Bool
    let urlSession: URLSession
    let injectedHeaders: HTTPHeaders?
    
    init(defaultHostname: String, useInsecureHTTP: Bool = false, urlSession: URLSession = .shared, injectedHeaders: HTTPHeaders? = nil) {
        self.defaultHostname = defaultHostname
        self.useInsecureHTTP = useInsecureHTTP
        self.urlSession = urlSession
        self.injectedHeaders = injectedHeaders
    }
    
    func request<R: NetworkRequest>(_ networkRequest: R) async throws -> R.ResponseBody {
        var urlComponents: URLComponents
        
        switch networkRequest.endpoint {
        case .relative(let path):
            let baseURLString = "http\(useInsecureHTTP ? "" : "s")://\(defaultHostname)"
            guard let baseURLComponents = URLComponents(string: baseURLString, encodingInvalidCharacters: false) else {
                throw URLError(.badURL, userInfo: [NSURLErrorFailingURLErrorKey: baseURLString])
            }
            urlComponents = baseURLComponents
            urlComponents.path = (urlComponents.path as NSString).appendingPathComponent(path)
        case .absolute(let absoluteURL):
            guard let absoluteURLComponents = URLComponents(url: absoluteURL, resolvingAgainstBaseURL: false) else {
                throw URLError(.badURL, userInfo: [NSURLErrorFailingURLErrorKey: absoluteURL])
            }
            urlComponents = absoluteURLComponents
        }
        if let query = networkRequest.query {
            urlComponents.append(query: query)
        }
        
        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }
        
        var urlRequest = URLRequest(url: url, cachePolicy: networkRequest.cachePolicy, timeoutInterval: networkRequest.timeoutInterval)
        urlRequest.httpMethod = networkRequest.method.rawValue
        var headers = injectedHeaders ?? .init()
        if let requestHeaders = networkRequest.headers {
            headers.merge(requestHeaders) { $2 }
        }
        if let bodyHeaders = networkRequest.body.headers {
            headers.merge(bodyHeaders) { $2 }
        }
        urlRequest.addHeaders(headers)
        urlRequest.httpBody = try networkRequest.body.encodeToData()
        
        let (data, anyResponse) = try await urlSession.data(for: urlRequest)
        guard let response = anyResponse as? HTTPURLResponse else {
            throw URLError(.cannotParseResponse)
        }
        
        if !networkRequest.responseStatusFilter(response.statusCode) {
            throw HTTPError(data: data, response: response)
        }
        
        return try R.ResponseBody(data: data, response: response)
    }
}

extension EnvironmentValues {
    @Entry var networkClient = NetworkClient(defaultHostname: "localhost:3000", useInsecureHTTP: true)
}
