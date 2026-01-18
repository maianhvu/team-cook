import Foundation

struct HTTPStatusFilter {
    let predicate: (_ status: Int) -> Bool
    
    init(predicate: @escaping (_ status: Int) -> Bool) {
        self.predicate = predicate
    }
    
    func callAsFunction(_ status: Int) -> Bool {
        return predicate(status)
    }
    
    static let allowAll = HTTPStatusFilter(predicate: { _ in true })
    static let success: HTTPStatusFilter = .init(predicate: { 200..<300 ~= $0 })
    static func custom(_ predicate: @escaping (_ status: Int) -> Bool) -> HTTPStatusFilter { .init(predicate: predicate) }
}
