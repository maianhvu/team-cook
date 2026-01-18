import Foundation

struct URLQuery {
    private var items: [String: String] = [:]

    init() {}

    init(_ items: [String: String]) {
        self.items = items
    }

    subscript(key: String) -> String? {
        get { items[key] }
        set { items[key] = newValue }
    }
    
    subscript(bool key: String) -> Bool? {
        get { items[key].map { $0 == "true" } }
        set { items[key] = newValue.map { String($0) } }
    }
    
    subscript(int key: String) -> Int? {
        get { items[key].flatMap { Int($0) } }
        set { items[key] = newValue.map { String($0) } }
    }
    
    subscript(commaSeparatedStrings key: String) -> [String]? {
        get { items[key].flatMap { $0.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } } }
        set { items[key] = newValue.map { $0.joined(separator: ",") } }
    }

    var queryItems: [URLQueryItem] {
        items.map { URLQueryItem(name: $0.key, value: $0.value) }
    }
    
    var isEmpty: Bool {
        items.isEmpty
    }
}

extension URLComponents {
    mutating func append(query: URLQuery) {
        var queryItems: [URLQueryItem] = self.queryItems ?? []
        for item in query.queryItems {
            queryItems.append(item)
        }
        self.queryItems = queryItems
    }
}
