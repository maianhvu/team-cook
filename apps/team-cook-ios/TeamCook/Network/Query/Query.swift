import Combine
import Foundation
import SwiftUI

@propertyWrapper
struct Query<Request: NetworkRequest, Value>: DynamicProperty {
    let selector: (Request.ResponseBody) -> Value
    @StateObject private var controller: QueryController<Request>
    @Environment(\.networkClient) private var networkClient

    init(_ requestType: Request.Type, selector: @escaping (_ responseBody: Request.ResponseBody) -> Value) {
        self.selector = selector
        self._controller = .init(wrappedValue: .init())
    }
    
    init(_ requestType: Request.Type) where Value == Request.ResponseBody {
        self.init(requestType, selector: { $0 })
    }
    
    init(_ requestType: Request.Type, keyPath: KeyPath<Request.ResponseBody, Value>) {
        self.init(requestType, selector: { $0[keyPath: keyPath] })
    }
    
    init(_ request: Request, selector: @escaping (_ responseBody: Request.ResponseBody) -> Value) {
        self.selector = selector
        self._controller = .init(wrappedValue: .init(request: request))
    }
    
    init(_ request: Request) where Value == Request.ResponseBody {
        self.init(request, selector: { $0 })
    }
    
    init(_ request: Request, keyPath: KeyPath<Request.ResponseBody, Value>) {
        self.init(request, selector: { $0[keyPath: keyPath] })
    }
    
    var wrappedValue: Value? { controller.data.map(selector) }
    var projectedValue: QueryController<Request> { controller }
    
    mutating func update() {
        let newNetworkClient = networkClient
        let controller = self.controller
        if newNetworkClient !== controller.networkClient {
            DispatchQueue.main.async { controller.networkClient = newNetworkClient }
        }
    }
}

final class QueryController<Request: NetworkRequest>: ObservableObject {
    @Published fileprivate(set) var currentRequest: Request?
    @Published fileprivate(set) var networkClient: NetworkClient?
    @Published var isEnabled: Bool = true

    @Published private(set) var data: Request.ResponseBody?
    @Published var error: (any Error)?
    @Published private var activeFetchID: UUID? = nil
    
    var isFetching: Bool {
        activeFetchID != nil
    }
    
    private var fetchCancellable: AnyCancellable?
    
    private var cancellables: Set<AnyCancellable> = []
    
    fileprivate init(request: Request? = nil) {
        self.currentRequest = request
        
        Publishers.CombineLatest3(
            $currentRequest,
            $networkClient.removeDuplicates(by: { $0 === $1 }),
            $isEnabled.removeDuplicates(),
        )
            .sink { [weak self] request, client, isEnabled in
                guard let request , let client, isEnabled else { return }
                self?.refetch(request, using: client)
            }
            .store(in: &cancellables)
    }
    
    private func refetch(_ request: Request, using networkClient: NetworkClient) {
        fetchCancellable?.cancel()
        let fetchID = UUID()
        let task = Task {
            do {
                activeFetchID = fetchID
                let data = try await networkClient.request(request)
                self.data = data
                self.error = nil
            } catch {
                if !(error is CancellationError) {
                    self.error = error
                }
            }
            if activeFetchID == fetchID { activeFetchID = nil }
        }
        fetchCancellable = AnyCancellable { task.cancel() }
    }
    
    func refetch() {
        guard let networkClient, let request = currentRequest, isEnabled else { return }
        refetch(request, using: networkClient)
    }
}

private struct UpdateQueryRequestViewModifier<Request: NetworkRequest, each Dependency: Equatable>: ViewModifier {
    var queryController: QueryController<Request>
    var updater: (repeat each Dependency) -> Request
    @State private var dependencies: EquatablePack<repeat each Dependency>
    
    fileprivate init(queryController: QueryController<Request>, updater: @escaping (repeat each Dependency) -> Request, dependencies: repeat each Dependency) {
        self.queryController = queryController
        self.updater = updater
        self.dependencies = .init(elements: repeat each dependencies)
    }
    
    func body(content: Content) -> some View {
        content
            .onChange(of: dependencies, initial: true) { _, newDependencies in
                let newRequest = updater(repeat each newDependencies.elements)
                queryController.currentRequest = newRequest
            }
    }
}

private struct EquatablePack<each Element: Equatable>: Equatable {
    let elements: (repeat each Element)
    
    init(elements: repeat each Element) {
        self.elements = (repeat each elements)
    }
    
    static func == (lhs: EquatablePack<repeat each Element>, rhs: EquatablePack<repeat each Element>) -> Bool {
        for (l, r) in repeat (each lhs.elements, each rhs.elements) {
            if l != r { return false }
        }
        return true
    }
}

extension View {
    func updateRequest<Request: NetworkRequest, each Dependency: Equatable>(
        for queryController: QueryController<Request>,
        with updater: @escaping (repeat each Dependency) -> Request,
        using dependencies: repeat each Dependency
    ) -> some View {
        modifier(UpdateQueryRequestViewModifier(queryController: queryController, updater: updater, dependencies: repeat each dependencies))
    }
}
