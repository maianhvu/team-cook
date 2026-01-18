import Foundation

struct HTTPHeaders: CustomStringConvertible {
    private struct Entry {
        let originalName: String
        var value: String
    }
    
    private var buffer: [String: Entry] = [:]
    
    subscript(name: String) -> String? {
        get { buffer[name.lowercased()]?.value }
        mutating set {
            if let value = newValue {
                buffer[name.lowercased(), default: Entry(originalName: name, value: "")].value = value
            } else {
                buffer[name.lowercased()] = nil
            }
        }
    }
    
    func toDictionary() -> [String: String] {
        Dictionary(buffer.values.map { ($0.originalName, $0.value) }, uniquingKeysWith: { $1 })
    }
    
    var description: String {
        return toDictionary().description
    }
}

extension HTTPHeaders: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral elements: (String, String)...) {
        for (name, value) in elements {
            self[name] = value
        }
    }
}

extension HTTPHeaders {
    mutating func merge(_ other: HTTPHeaders, uniquingKeysWith combine: (_ key: String, _ selfValue: String, _ otherValue: String) throws -> String) rethrows {
        for (key, otherValue) in other.toDictionary() {
            if let selfValue = self[key] {
                self[key] = try combine(key, selfValue, otherValue)
            } else {
                self[key] = otherValue
            }
        }
    }

    func merging(_ other: HTTPHeaders, uniquingKeysWith combine: (_ key: String, _ selfValue: String, _ otherValue: String) throws -> String) rethrows -> HTTPHeaders {
        var result = self
        try result.merge(other, uniquingKeysWith: combine)
        return result
    }
}

extension URLRequest {
    mutating func setHeaders(_ headers: HTTPHeaders) {
        allHTTPHeaderFields = headers.toDictionary()
    }
    
    mutating func addHeaders(_ headers: HTTPHeaders) {
        for (key, value) in headers.toDictionary() {
            addValue(value, forHTTPHeaderField: key)
        }
    }
}
