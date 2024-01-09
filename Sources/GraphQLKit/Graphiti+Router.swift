import Vapor
import Graphiti
import GraphQL

extension RoutesBuilder {
    public func register<RootType>(graphQLSchema schema: Schema<RootType, Request>, withResolver rootAPI: RootType, at path: PathComponent="graphql", postBodyStreamStrategy: HTTPBodyStreamStrategy = .collect) {
        self.on(.POST, path, body: postBodyStreamStrategy) { (request) -> EventLoopFuture<Response> in
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

extension GraphQLResult: Content {
    public func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
        return request.eventLoop.submit {
            Response(
                status: .ok,
                headers: [
                    "Content-Type": "application/json"
                ],
                body: .init(data: try GraphQLJSONEncoder().encode(self))
            )
        }
    }
}
