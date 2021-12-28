import Vapor
import Graphiti
import GraphQL

extension RoutesBuilder {
    public func register<RootType>(graphQLSchema schema: Schema<RootType, Request>, withResolver rootAPI: RootType, at path: PathComponent="graphql", postBodyStreamStrategy: HTTPBodyStreamStrategy = .collect) {
        self.on(.POST, path, body: postBodyStreamStrategy) { (request) -> EventLoopFuture<Response> in
            try request.resolveByBody(graphQLSchema: schema, with: rootAPI)
                .flatMap({
                    $0.encodeResponse(status: $0.httpResponseStatus(), for: request)
                })
        }
        self.get(path) { (request) -> EventLoopFuture<Response> in
            try request.resolveByQueryParameters(graphQLSchema: schema, with: rootAPI)
                .flatMap({
                    $0.encodeResponse(status: $0.httpResponseStatus(), for: request)
                })
        }
    }
}

extension GraphQLResult {
    fileprivate func httpResponseStatus() -> HTTPStatus {
        if let error = self.errors.first?.originalError as? GraphQLHTTPStatusError {
            return error.status
        } else {
            return .ok
        }
    }
}

enum GraphQLResolveError: Swift.Error {
    case noQueryFound
}

extension GraphQLResult: Content { }

public protocol GraphQLHTTPStatusError: Swift.Error {
    var status: HTTPStatus { get }
}
