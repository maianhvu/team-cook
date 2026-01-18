import Foundation

enum HTTPEndpoint: ExpressibleByStringLiteral {
    case relative(path: String)
    case absolute(url: URL)
    
    init(stringLiteral value: String) {
        if value.hasPrefix("https://") || value.hasPrefix("http://") {
            self = .absolute(url: URL(string: value)!)
        } else {
            self = .relative(path: value)
        }
    }
}
