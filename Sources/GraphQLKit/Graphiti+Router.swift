import Vapor
import Graphiti
import GraphQL

extension RoutesBuilder {
    public func register<RootType>(graphQLSchema schema: Schema<RootType, Request>, withResolver rootAPI: RootType, at path: PathComponent="graphql") {
        self.post(path) { (request) -> EventLoopFuture<Response> in
            try request.resolveByBody(graphQLSchema: schema, with: rootAPI)
                .flatMap({
                    $0.encodeResponse(status: .ok, for: request)
                })
        }
        self.get(path) { (request) -> EventLoopFuture<Response> in
            try request.resolveByQueryParameters(graphQLSchema: schema, with: rootAPI)
                .flatMap({
                    $0.encodeResponse(status: .ok, for: request)
                })
        }
    }
}

enum GraphQLResolveError: Swift.Error {
    case noQueryFound
}

extension GraphQLResult: Content { }
